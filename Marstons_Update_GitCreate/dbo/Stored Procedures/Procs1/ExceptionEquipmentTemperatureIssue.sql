CREATE PROCEDURE [dbo].[ExceptionEquipmentTemperatureIssue]
(
	@EDISID INT = NULL,
	@Auditor VARCHAR(255) = NULL		
)
AS

/* For Testing */ --3787
--DECLARE @Auditor VARCHAR(255) = NULL
--DECLARE @EDISID INT = NULL --30
--DECLARE @SiteID VARCHAR (15) = NULL --'896579' -- '40402401'
--IF @SiteID IS NOT NULL
--    SELECT @EDISID = [EDISID] FROM [dbo].[Sites] WHERE [SiteID] = @SiteID

DECLARE @EnableLogging BIT = 1
DECLARE @DebugDayShift INT = 0
DECLARE @DebugFixedDate DATETIME = NULL
DECLARE @DebugDates BIT = 0
DECLARE @DebugParameters BIT = 0
DECLARE @DebugReadings BIT = 0
DECLARE @DebugInputID INT
DECLARE @DebugStatus BIT = 0
DECLARE @DebugSequence BIT = 0

SET NOCOUNT ON;
SET DATEFIRST 1;

/* Debugging */
--SET @EnableLogging = 0
--SET @DebugDayShift = -4
--SET @DebugFixedDate = '2017-02-11 03:16:00'
--SET @DebugDates = 1
--SET @DebugParameters = 1
--SET @DebugReadings = 1
--SET @DebugInputID = 77684
--SET @DebugStatus = 1
--SET @DebugSequence = 1

DECLARE @To DATETIME = GETDATE() -- Only needed to enable The debug ability to shift the 24 hour period
DECLARE @From DATETIME = DATEADD(DAY, -1, @To)

IF @DebugDayShift <> 0 AND @DebugFixedDate IS NULL
BEGIN
    SET @To = DATEADD(DAY, @DebugDayShift, @To)
    SET @From = DATEADD(DAY, @DebugDayShift, @From)
END
ELSE IF @DebugFixedDate IS NOT NULL
BEGIN
    SET @To = @DebugFixedDate
    SET @From = DATEADD(DAY, -1, @To)
END

IF @DebugDates = 1
BEGIN
    SELECT @From, @To
END

IF @EnableLogging = 1
BEGIN
    DECLARE @DatabaseID INT
    SELECT @DatabaseID = [ID] FROM [SQL1\SQL1].[ServiceLogger].[dbo].[EDISDatabases] WHERE [Name] = DB_NAME()
    DECLARE @NotificationTypeID INT
    SELECT @NotificationTypeID = [NotificationTypeID] FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationType] WHERE [StoredProcedure] = OBJECT_NAME(@@PROCID)
    IF @NotificationTypeID IS NOT NULL
    BEGIN
        EXEC [SQL1\SQL1].[Auditing].[dbo].[AddNotificationTypeGenerationLog] @NotificationTypeID, @DatabaseID, @EDISID, @From, @To
    END
END

--Configuration
DECLARE @ConsistentPeriod INT
DECLARE @Occurrances INT

-- Equipment Types (12) (Ambient)
DECLARE @Ambient_Amber_Lower_Min INT
DECLARE @Ambient_Amber_Lower_Max INT
DECLARE @Ambient_Amber_Higher_Min INT
DECLARE @Ambient_Amber_Higher_Max INT
DECLARE @US_Ambient_Amber_Lower_Min INT
DECLARE @US_Ambient_Amber_Lower_Max INT
DECLARE @US_Ambient_Amber_Higher_Min INT
DECLARE @US_Ambient_Amber_Higher_Max INT

-- Equipment Types (15,16) (Remote Cooler)
DECLARE @Remote_Amber_Lower_Min INT
DECLARE @Remote_Amber_Lower_Max INT
DECLARE @Remote_Amber_Higher_Min INT
DECLARE @Remote_Amber_Higher_Max INT

-- Equipment Types (10,11) (Cask Cooler)
DECLARE @Cask_Amber_Lower_Min INT
DECLARE @Cask_Amber_Lower_Max INT
DECLARE @Cask_Amber_Higher_Min INT
DECLARE @Cask_Amber_Higher_Max INT

-- Equipment Types (13,14) (Glycol Cooler)
DECLARE @Glycol_Amber_Lower_Min INT
DECLARE @Glycol_Amber_Lower_Max INT
DECLARE @Glycol_Amber_Higher_Min INT
DECLARE @Glycol_Amber_Higher_Max INT
DECLARE @US_Glycol_Amber_Lower_Min INT
DECLARE @US_Glycol_Amber_Lower_Max INT
DECLARE @US_Glycol_Amber_Higher_Min INT
DECLARE @US_Glycol_Amber_Higher_Max INT

-- Equipment Types (18) (Cool Room)
DECLARE @US_Cool_Room_Amber_Lower_Min INT
DECLARE @US_Cool_Room_Amber_Lower_Max INT
DECLARE @US_Cool_Room_Amber_Higher_Min INT
DECLARE @US_Cool_Room_Amber_Higher_Max INT

-- US Sites
DECLARE @IsUS VARCHAR(255) = 'en-US'
DECLARE @US_Sites TABLE ([EDISID] INT NOT NULL)

DECLARE @Property_International INT
SELECT @Property_International = [ID]
FROM [dbo].[Properties]
WHERE [Name] = 'International'  -- Testing: Independent (property exists), Admiral (property doesn't exist)

INSERT INTO @US_Sites ([EDISID])
SELECT [EDISID]
FROM [dbo].[SiteProperties]
WHERE 
    [PropertyID] = @Property_International
AND [Value] = @IsUS

SELECT @ConsistentPeriod               = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentTempConsistentData'
SELECT @Occurrances                    = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentTempOccurrances'

SELECT @Ambient_Amber_Lower_Min        = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentAmberTempLowerLow'
SELECT @Ambient_Amber_Lower_Max        = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentAmberTempLowerHigh'
SELECT @Ambient_Amber_Higher_Min       = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentAmberTempUpperLow'
SELECT @Ambient_Amber_Higher_Max       = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentAmberTempUpperHigh'
SELECT @US_Ambient_Amber_Lower_Min     = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentAmberTempLowerLow-US'
SELECT @US_Ambient_Amber_Lower_Max     = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentAmberTempLowerHigh-US'
SELECT @US_Ambient_Amber_Higher_Min    = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentAmberTempUpperLow-US'
SELECT @US_Ambient_Amber_Higher_Max    = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentAmberTempUpperHigh-US'

SELECT @Remote_Amber_Lower_Min         = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentAmberRemoteCoolerLowerLow'
SELECT @Remote_Amber_Lower_Max         = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentAmberRemoteCoolerLowerHigh'
SELECT @Remote_Amber_Higher_Min        = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentAmberRemoteCoolerUpperLow'
SELECT @Remote_Amber_Higher_Max        = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentAmberRemoteCoolerUpperHigh'

SELECT @Cask_Amber_Lower_Min           = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentAmberCaskCoolerLowerLow'
SELECT @Cask_Amber_Lower_Max           = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentAmberCaskCoolerLowerHigh'
SELECT @Cask_Amber_Higher_Min          = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentAmberCaskCoolerUpperLow'
SELECT @Cask_Amber_Higher_Max          = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentAmberCaskCoolerUpperHigh'

SELECT @US_Cool_Room_Amber_Lower_Min   = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentAmberCoolRoomLowerLow-US'
SELECT @US_Cool_Room_Amber_Lower_Max   = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentAmberCoolRoomLowerHigh-US'
SELECT @US_Cool_Room_Amber_Higher_Min  = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentAmberCoolRoomUpperLow-US'
SELECT @US_Cool_Room_Amber_Higher_Max  = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentAmberCoolRoomUpperHigh-US'

SELECT @Glycol_Amber_Lower_Min         = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentAmberGlycolCoolerLowerLow'
SELECT @Glycol_Amber_Lower_Max         = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentAmberGlycolCoolerLowerHigh'
SELECT @Glycol_Amber_Higher_Min        = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentAmberGlycolCoolerUpperLow'
SELECT @Glycol_Amber_Higher_Max        = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentAmberGlycolCoolerUpperHigh'
SELECT @US_Glycol_Amber_Lower_Min      = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentAmberGlycolCoolerLowerLow-US'
SELECT @US_Glycol_Amber_Lower_Max      = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentAmberGlycolCoolerLowerHigh-US'
SELECT @US_Glycol_Amber_Higher_Min     = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentAmberGlycolCoolerUpperLow-US'
SELECT @US_Glycol_Amber_Higher_Max     = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'EquipmentAmberGlycolCoolerUpperHigh-US'


IF @DebugParameters = 1
BEGIN
    SELECT 
        @ConsistentPeriod [ConsistentPeriod],
        @Occurrances [Occurrances],
        @Ambient_Amber_Lower_Min [Ambient_Amber_Lower_Min], 
        @Ambient_Amber_Lower_Max [Ambient_Amber_Lower_Max], 
        @Ambient_Amber_Higher_Min [Ambient_Amber_Higher_Min], 
        @Ambient_Amber_Higher_Max [Ambient_Amber_Higher_Max],
        @US_Ambient_Amber_Lower_Min [US_Ambient_Amber_Lower_Min], 
        @US_Ambient_Amber_Lower_Max [US_Ambient_Amber_Lower_Max], 
        @US_Ambient_Amber_Higher_Min [US_Ambient_Amber_Higher_Min], 
        @US_Ambient_Amber_Higher_Max [US_Ambient_Amber_Higher_Max],
        @Remote_Amber_Lower_Min [Remote_Amber_Lower_Min], 
        @Remote_Amber_Lower_Max [Remote_Amber_Lower_Max], 
        @Remote_Amber_Higher_Min [Remote_Amber_Higher_Min], 
        @Remote_Amber_Higher_Max [Remote_Amber_Higher_Max],
        @Cask_Amber_Lower_Min [Cask_Amber_Lower_Min], 
        @Cask_Amber_Lower_Max [Cask_Amber_Lower_Max], 
        @Cask_Amber_Higher_Min [Cask_Amber_Higher_Min], 
        @Cask_Amber_Higher_Max [Cask_Amber_Higher_Max],
        @Glycol_Amber_Lower_Min [Glycol_Amber_Lower_Min], 
        @Glycol_Amber_Lower_Max [Glycol_Amber_Lower_Max],
        @Glycol_Amber_Higher_Min [Glycol_Amber_Higher_Min], 
        @Glycol_Amber_Higher_Max [Glycol_Amber_Higher_Max],
        @US_Glycol_Amber_Lower_Min [US_Glycol_Amber_Lower_Min], 
        @US_Glycol_Amber_Lower_Max [US_Glycol_Amber_Lower_Max], 
        @US_Glycol_Amber_Higher_Min [US_Glycol_Amber_Higher_Min], 
        @US_Glycol_Amber_Higher_Max [US_Glycol_Amber_Higher_Max],
        @US_Cool_Room_Amber_Lower_Min [US_Cool_Room_Amber_Lower_Min],
        @US_Cool_Room_Amber_Lower_Max [US_Cool_Room_Amber_Lower_Max],
        @US_Cool_Room_Amber_Higher_Min [US_Cool_Room_Amber_Higher_Min],
        @US_Cool_Room_Amber_Higher_Max [US_Cool_Room_Amber_Higher_Max]
END

-- Get all non-closed Calls which involve Equipment
-- Stolen from [dbo].[GetCalls]
/*
-- LEGACY LOGGER
CREATE TABLE #EquipmentCalls (CallID INT NOT NULL, EDISID INT NOT NULL, InputID INT NOT NULL)
INSERT INTO #EquipmentCalls (CallID, EDISID, InputID)
SELECT
    Calls.[ID],
	Calls.EDISID,
    SIE.InputID
FROM dbo.CallsSLA AS Calls WITH (NOLOCK)
JOIN dbo.CallStatusHistory WITH (NOLOCK) ON CallStatusHistory.CallID = Calls.[ID]
LEFT JOIN dbo.SupplementaryCallStatusItems ON SupplementaryCallStatusItems.CallID = Calls.[ID]
LEFT JOIN dbo.CallStatusHistory AS InProgressStatus 
	ON InProgressStatus.CallID = Calls.[ID]
	AND InProgressStatus.StatusID <> 1
	AND InProgressStatus.[ID] =	(SELECT MIN(CallStatusHistory.[ID])
					FROM dbo.CallStatusHistory
					WHERE CallID = Calls.[ID]
					AND CallStatusHistory.StatusID <> 1)
LEFT JOIN dbo.CallStatusHistory AS MostRecentOnHoldStatus
	ON MostRecentOnHoldStatus.CallID = Calls.[ID]
	AND MostRecentOnHoldStatus.StatusID = 2
	AND MostRecentOnHoldStatus.[ID] =	(SELECT MAX(CallStatusHistory.[ID])
						FROM dbo.CallStatusHistory
						WHERE CallID = Calls.[ID]
						AND CallStatusHistory.StatusID = 2)
LEFT JOIN dbo.CallStatusHistory AS SubsequentOnHoldStatus
	ON SubsequentOnHoldStatus.CallID = Calls.[ID]
	AND SubsequentOnHoldStatus.StatusID <> 2
	AND SubsequentOnHoldStatus.[ID] =	(SELECT MIN(CallStatusHistory.[ID])
						FROM dbo.CallStatusHistory
						WHERE CallID = Calls.[ID]
						AND CallStatusHistory.[ID] > MostRecentOnHoldStatus.[ID])
LEFT JOIN dbo.CallStatusHistory AS PreviousCallStatus
	ON PreviousCallStatus.CallID = Calls.[ID]
	AND PreviousCallStatus.[ID] =	(SELECT MAX(InnerCallStatusHistory.[ID])
					FROM dbo.CallStatusHistory AS InnerCallStatusHistory
					WHERE CallID = Calls.[ID]
					AND InnerCallStatusHistory.[ID] <> CallStatusHistory.[ID])
LEFT JOIN dbo.ServiceIssuesEquipment AS SIE ON Calls.ID = SIE.CallID AND Calls.EDISID = SIE.EDISID
WHERE 
    CallStatusHistory.[ID] = (
        SELECT MAX(CallStatusHistory.[ID])
		FROM dbo.CallStatusHistory
		WHERE CallID = Calls.[ID]
        )
AND (SupplementaryCallStatusItems.[ID] = (
        SELECT MAX(SupplementaryCallStatusItems.[ID])
		FROM dbo.SupplementaryCallStatusItems
		WHERE CallID = Calls.[ID]
        )
    OR SupplementaryCallStatusItems.[ID] IS NULL)
AND ((CallStatusHistory.StatusID = 1) -- Open
    OR (CallStatusHistory.StatusID = 2) -- On-Hold
    OR (CallStatusHistory.StatusID = 3) -- In-Progress
    OR (CallStatusHistory.StatusID = 6)) -- Pre-Raised
AND SIE.InputID IS NOT NULL
*/

CREATE TABLE #EquipmentCalls (EDISID INT NOT NULL, InputID INT NOT NULL)
INSERT INTO #EquipmentCalls (EDISID, InputID)
SELECT
    [EquipmentItems].[EDISID],
    [EquipmentItems].[InputID]
FROM [dbo].[JobWatchCalls]
JOIN [dbo].[JobWatchCallsData] ON [JobWatchCalls].[JobId] = [JobWatchCallsData].[JobId]
JOIN [dbo].[EquipmentItems] ON [JobWatchCalls].[EdisID] = [EquipmentItems].[EDISID] AND [JobWatchCallsData].[EquipmentAddress] = [EquipmentItems].[InputID]
WHERE [JobWatchCalls].[JobActive] = 1
AND [JobWatchCallsData].[EquipmentAddress] IS NOT NULL


IF @DebugReadings = 1 AND @DebugInputID IS NOT NULL
BEGIN
    SELECT 
        [ER].*,
        [EI].*,
        [ET].*
    FROM [dbo].[EquipmentItems] AS [EI]
    JOIN [dbo].[EquipmentTypes] AS [ET] ON [EI].[EquipmentTypeID] = [ET].[ID]
    JOIN [dbo].[EquipmentReadings] AS [ER] ON [EI].[InputID] = [ER].[InputID] AND [EI].[EDISID] = [ER].[EDISID] AND [ER].[LogDate] >= @From AND [ER].[LogDate] < @To
    WHERE [EI].InputID = @DebugInputID
    AND (@EDISID IS NULL OR [EI].[EDISID] = @EDISID)
END

CREATE TABLE #Readings 
    ([EDISID] INT NOT NULL, [EquipmentInputID] INT NOT NULL, [EquipmentDescription] VARCHAR(1024) NOT NULL, [Type] VARCHAR(255) NOT NULL, 
    [Date] DATETIME NOT NULL, [Day] DATE NOT NULL, [Hour] INT NOT NULL, [Green] INT, [Amber] INT, [Red] INT)
INSERT INTO #Readings ([EDISID], [EquipmentInputID], [EquipmentDescription], [Type], [Date], [Day], [Hour], [Green], [Amber], [Red])
SELECT
    [S].[EDISID],
    [EI].[InputID] AS [EquipmentInputID],
    [EI].[Description] AS [EquipmentDescription],
    [ET].[Description] AS [EquipmentType],
    DATEADD(MINUTE, -DATEPART(MINUTE, [ER].[LogDate]), DATEADD(SECOND, -DATEPART(SECOND, [ER].[LogDate]), DATEADD(MILLISECOND, -DATEPART(MILLISECOND, [ER].[LogDate]), [ER].[LogDate]))) AS [Date],
    CAST([ER].[LogDate] AS DATE) AS [Day],
    DATEPART(HOUR, [ER].[LogDate]) AS [Hour],
    COUNT(
        CASE -- Instances of Green
            WHEN [ET].[ID] IN (12) AND [US].[EDISID] IS NULL
            THEN    -- Ambient Temperature (Non US)
                CASE 
                    WHEN ([ER].[Value] >= @Ambient_Amber_Lower_Max AND [ER].[Value] < @Ambient_Amber_Higher_Min)
                    THEN [ER].[Value]
                    ELSE NULL
                    END
            WHEN [ET].[ID] IN (12) AND [US].[EDISID] IS NOT NULL
            THEN    -- Ambient Temperature (US)
                CASE 
                    WHEN ([ER].[Value] >= @US_Ambient_Amber_Lower_Max AND [ER].[Value] < @US_Ambient_Amber_Higher_Min)
                    THEN [ER].[Value]
                    ELSE NULL
                    END
            WHEN [ET].[ID] IN (15,16) AND [US].[EDISID] IS NULL
            THEN    -- Remote Cooler (Non US)
                CASE
                    WHEN ([ER].[Value] >= @Remote_Amber_Lower_Max AND [ER].[Value] < @Remote_Amber_Higher_Min)
                    THEN [ER].[Value]
                    ELSE NULL
                    END
            WHEN [ET].[ID] IN (10,11)
            THEN    -- Cask Cooler (Non US)
                CASE
                    WHEN ([ER].[Value] >= @Cask_Amber_Lower_Max AND [ER].[Value] < @Cask_Amber_Higher_Min)
                    THEN [ER].[Value]
                    ELSE NULL
                    END
            WHEN [ET].[ID] IN (13,14) AND [US].[EDISID] IS NULL
            THEN    -- Glycol Cooler (Non US)
                CASE
                    WHEN ([ER].[Value] >= @Glycol_Amber_Lower_Max AND [ER].[Value] < @Glycol_Amber_Higher_Min)
                    THEN [ER].[Value]
                    ELSE NULL
                    END
            WHEN [ET].[ID] IN (13,14) AND [US].[EDISID] IS NOT NULL
            THEN    -- Glycol Cooler (US)
                CASE
                    WHEN ([ER].[Value] >= @US_Glycol_Amber_Lower_Max AND [ER].[Value] < @US_Glycol_Amber_Higher_Min)
                    THEN [ER].[Value]
                    ELSE NULL
                    END
            WHEN [ET].[ID] IN (18) AND [US].[EDISID] IS NOT NULL
            THEN    -- Cool Room (US)
                CASE
                    WHEN ([ER].[Value] >= @US_Cool_Room_Amber_Lower_Max AND [ER].[Value] < @US_Cool_Room_Amber_Higher_Min)
                    THEN [ER].[Value]
                    ELSE NULL
                    END
            END
    ) AS [Green],
    COUNT(
        CASE -- Instances of Amber
            WHEN [ET].[ID] IN (12) AND [US].[EDISID] IS NULL
            THEN    -- Ambient Temperature (Non US)
                CASE 
                    WHEN (([ER].[Value] >= @Ambient_Amber_Lower_Min AND [ER].[Value] < @Ambient_Amber_Lower_Max)
                            OR
                          ([ER].[Value] >= @Ambient_Amber_Higher_Min AND [ER].[Value] < @Ambient_Amber_Higher_Max))
                    THEN [ER].[Value]
                    ELSE NULL
                    END
            WHEN [ET].[ID] IN (12) AND [US].[EDISID] IS NOT NULL
            THEN    -- Ambient Temperature (US)
                CASE 
                    WHEN (([ER].[Value] >= @US_Ambient_Amber_Lower_Min AND [ER].[Value] < @US_Ambient_Amber_Lower_Max)
                            OR
                          ([ER].[Value] >= @US_Ambient_Amber_Higher_Min AND [ER].[Value] < @US_Ambient_Amber_Higher_Max))
                    THEN [ER].[Value]
                    ELSE NULL
                    END
            WHEN [ET].[ID] IN (15,16) AND [US].[EDISID] IS NULL
            THEN    -- Remote Cooler (Non US)
                CASE
                    WHEN (([ER].[Value] >= @Remote_Amber_Lower_Min AND [ER].[Value] < @Remote_Amber_Lower_Max)
                            OR
                          ([ER].[Value] >= @Remote_Amber_Higher_Min AND [ER].[Value] < @Remote_Amber_Higher_Max))
                    THEN [ER].[Value]
                    ELSE NULL
                    END
            WHEN [ET].[ID] IN (10,11)
            THEN    -- Cask Cooler (Non US)
                CASE
                    WHEN (([ER].[Value] >= @Cask_Amber_Lower_Min AND [ER].[Value] < @Cask_Amber_Lower_Max)
                            OR
                          ([ER].[Value] >= @Cask_Amber_Higher_Min AND [ER].[Value] < @Cask_Amber_Higher_Max))
                    THEN [ER].[Value]
                    ELSE NULL
                    END
            WHEN [ET].[ID] IN (13,14) AND [US].[EDISID] IS NULL
            THEN    -- Glycol Cooler (Non US)
                CASE
                    WHEN (([ER].[Value] >= @Glycol_Amber_Lower_Min AND [ER].[Value] < @Glycol_Amber_Lower_Max)
                            OR
                          ([ER].[Value] >= @Glycol_Amber_Higher_Min AND [ER].[Value] < @Glycol_Amber_Higher_Max))
                    THEN [ER].[Value]
                    ELSE NULL
                    END
            WHEN [ET].[ID] IN (13,14) AND [US].[EDISID] IS NOT NULL
            THEN    -- Glycol Cooler (US)
                CASE
                    WHEN (([ER].[Value] >= @US_Glycol_Amber_Lower_Min AND [ER].[Value] < @US_Glycol_Amber_Lower_Max)
                            OR
                          ([ER].[Value] >= @US_Glycol_Amber_Higher_Min AND [ER].[Value] < @US_Glycol_Amber_Higher_Max))
                    THEN [ER].[Value]
                    ELSE NULL
                    END
            WHEN [ET].[ID] IN (18) AND [US].[EDISID] IS NOT NULL
            THEN    -- Cool Room (US)
                CASE
                    WHEN (([ER].[Value] >= @US_Cool_Room_Amber_Lower_Min AND [ER].[Value] < @US_Cool_Room_Amber_Lower_Max)
                            OR
                          ([ER].[Value] >= @US_Cool_Room_Amber_Higher_Min AND [ER].[Value] < @US_Cool_Room_Amber_Higher_Max))
                    THEN [ER].[Value]
                    ELSE NULL
                    END
            END
    ) AS [Amber],
    COUNT(
        CASE -- Instances of Red
            WHEN [ET].[ID] IN (12) AND [US].[EDISID] IS NULL
            THEN    -- Ambient Temperature (Non US)
                CASE 
                    WHEN ([ER].[Value] < @Ambient_Amber_Lower_Min OR [ER].[Value] > @Ambient_Amber_Higher_Max)
                    THEN [ER].[Value]
                    ELSE NULL
                    END
            WHEN [ET].[ID] IN (12) AND [US].[EDISID] IS NOT NULL
            THEN    -- Ambient Temperature (US)
                CASE 
                    WHEN ([ER].[Value] < @US_Ambient_Amber_Lower_Min OR [ER].[Value] > @US_Ambient_Amber_Higher_Max)
                    THEN [ER].[Value]
                    ELSE NULL
                    END
            WHEN [ET].[ID] IN (15,16) AND [US].[EDISID] IS NULL
            THEN    -- Remote Cooler (Non US)
                CASE
                    WHEN ([ER].[Value] < @Remote_Amber_Lower_Min OR [ER].[Value] > @Remote_Amber_Higher_Max)
                    THEN [ER].[Value]
                    ELSE NULL
                    END
            WHEN [ET].[ID] IN (10,11)
            THEN    -- Cask Cooler (Non US)
                CASE
                    WHEN ([ER].[Value] < @Cask_Amber_Lower_Min OR [ER].[Value] > @Cask_Amber_Higher_Max)
                    THEN [ER].[Value]
                    ELSE NULL
                    END
            WHEN [ET].[ID] IN (13,14) AND [US].[EDISID] IS NULL
            THEN    -- Glycol Cooler (Non US)
                CASE
                    WHEN ([ER].[Value] < @Glycol_Amber_Lower_Min OR [ER].[Value] > @Glycol_Amber_Higher_Max)
                    THEN [ER].[Value]
                    ELSE NULL
                    END
            WHEN [ET].[ID] IN (13,14) AND [US].[EDISID] IS NOT NULL
            THEN    -- Glycol Cooler (US)
                CASE
                    WHEN ([ER].[Value] < @US_Glycol_Amber_Lower_Min OR [ER].[Value] > @US_Glycol_Amber_Higher_Max)
                    THEN [ER].[Value]
                    ELSE NULL
                    END
            WHEN [ET].[ID] IN (18) AND [US].[EDISID] IS NOT NULL
            THEN    -- Cool Room (US)
                CASE
                    WHEN ([ER].[Value] < @US_Cool_Room_Amber_Lower_Min OR [ER].[Value] > @US_Cool_Room_Amber_Higher_Max)
                    THEN [ER].[Value]
                    ELSE NULL
                    END
            END
    ) AS [Red]
FROM [dbo].[EquipmentItems] AS [EI]
JOIN [dbo].[Sites] AS [S] ON [EI].[EDISID] = [S].[EDISID]
JOIN [dbo].[EquipmentTypes] AS [ET] ON [EI].[EquipmentTypeID] = [ET].[ID]
JOIN [dbo].[EquipmentReadings] AS [ER] ON [EI].[InputID] = [ER].[InputID] AND [EI].[EDISID] = [ER].[EDISID] AND [ER].[LogDate] >= @From
LEFT JOIN #EquipmentCalls AS [EC] ON [EI].[EDISID] = [EC].[EDISID] AND [EI].[InputID] = [EC].[InputID]
LEFT JOIN @US_Sites AS [US] ON [S].[EDISID] = [US].[EDISID]
WHERE
    [S].[LastDownload] >= @From 
AND [ER].[LogDate] BETWEEN @From AND @To
AND (@EDISID IS NULL OR [S].[EDISID] = @EDISID)
AND (@Auditor IS NULL OR SiteUser = @Auditor)
AND [EC].[InputID] IS NULL
GROUP BY
    [S].[EDISID],
    [EI].[InputID],
    [EI].[Description],
    [ET].[Description],
    DATEADD(MINUTE, -DATEPART(MINUTE, [ER].[LogDate]), DATEADD(SECOND, -DATEPART(SECOND, [ER].[LogDate]), DATEADD(MILLISECOND, -DATEPART(MILLISECOND, [ER].[LogDate]), [ER].[LogDate]))),
    CAST([ER].[LogDate] AS DATE),
    DATEPART(HOUR, [ER].[LogDate])
--ORDER BY 
--    [S].[EDISID],
--    COALESCE(CASE WHEN [EI].[Description] = '' THEN NULL ELSE [EI].[Description] END, CAST([EI].[InputID] AS VARCHAR(10))),
--    CAST([ER].[LogDate] AS DATE),
--    DATEPART(HOUR, [ER].[LogDate])



IF @DebugReadings = 1
BEGIN
SELECT 
        [R].[EDISID],
        [R].[EquipmentInputID],
        [R].[EquipmentDescription],
        [R].[Type],
        [R].[Date],
        [R2].[Date] AS [PreviousHour],
        [R3].[Date] AS [NextHour],
        CASE WHEN ([R2].[Date] IS NOT NULL OR [R3].[Date] IS NOT NULL) AND [R].[Green] = 0
             THEN 1
             ELSE 0
             END [AdjacentPureAmberRed],
        [R].[Day],
        [R].[Hour],
        [R].[Green],
        [R].[Amber],
        [R].[Red]
    FROM #Readings AS [R]
    LEFT JOIN #Readings AS [R2]
        ON ([R].[Date] = DATEADD(HOUR, 1, [R2].[Date]))
        AND [R].[EDISID] = [R2].[EDISID]
        AND [R].[EquipmentInputID] = [R2].[EquipmentInputID]
        AND [R].[EquipmentDescription] = [R2].[EquipmentDescription]
        AND [R].[Type] = [R2].[Type]
        AND [R2].[Amber] = 0  -- HACK: Temporarily Remove Amber
        AND [R2].[Green] = 0
    LEFT JOIN #Readings AS [R3]
        ON ([R].[Date] = DATEADD(HOUR, -1, [R3].[Date]))
        AND [R].[EDISID] = [R3].[EDISID]
        AND [R].[EquipmentInputID] = [R3].[EquipmentInputID]
        AND [R].[EquipmentDescription] = [R3].[EquipmentDescription]
        AND [R].[Type] = [R3].[Type]
        AND [R3].[Amber] = 0  -- HACK: Temporarily Remove Amber
        AND [R3].[Green] = 0
    WHERE @DebugInputID IS NULL OR [R].[EquipmentInputID] = @DebugInputID
    --AND [R].[Green] = 0
    ORDER BY 
        [EDISID],
        [EquipmentDescription],
        [Type],
        [Day],
        [Hour]
END

IF @DebugStatus = 1
BEGIN
    SELECT
        [R].[EDISID],
        [R].[EquipmentInputID],
        [R].[EquipmentDescription],
        [R].[Type],
        [R].[Date] AS [Date],
        [R].[Day],
        [R].[Hour],
        CASE
            WHEN (([R].[Green] > 0 AND [R].[Amber] = 0  AND [R].[Red] = 0)
                  OR
                  ([R].[Green] = 0 AND [R].[Amber] > 0  AND [R].[Red] = 0)
                  OR
                  ([R].[Green] = 0 AND [R].[Amber] = 0  AND [R].[Red] > 0))
            THEN 1
            ELSE 0
            END AS [Consistent],
        CASE
            WHEN ([R].[Green] > 0 AND [R].[Amber] = 0  AND [R].[Red] = 0)
            THEN 1 -- Green
            WHEN ([R].[Green] = 0 AND [R].[Amber] > 0  AND [R].[Red] = 0)
            THEN 2 -- Amber
            WHEN ([R].[Green] = 0 AND [R].[Amber] = 0  AND [R].[Red] > 0)
            THEN 3 -- Red
            WHEN ([R].[Green] = 0 AND [R].[Amber] = 0  AND [R].[Red] = 0)
            THEN 0 -- Should not happen! Indicates a configuration issue (or logic bug)
            ELSE -1 -- Data is Inconsistent (Contains multiple 'colours')
            END AS [Status]
    FROM #Readings AS [R]
    WHERE @DebugInputID IS NULL OR [R].[EquipmentInputID] = @DebugInputID
    ORDER BY
        [R].[EDISID],
        [R].[EquipmentDescription],
        [R].[Type],
        [R].[Day],
        [R].[Hour]
END

DECLARE @CursorEDISID INT 
DECLARE @CursorInputID INT
DECLARE @CursorDescription VARCHAR(1024)
DECLARE @CursorType VARCHAR(255)
DECLARE @CursorDate DATETIME
DECLARE @CursorAdjacent BIT
DECLARE @CursorAmber INT
DECLARE @CursorRed INT

DECLARE @PreviousEDISID INT 
DECLARE @PreviousInputID INT
DECLARE @PreviousDescription VARCHAR(1024)
DECLARE @PreviousType VARCHAR(255)
DECLARE @PreviousDate DATETIME

DECLARE @TrackStart DATETIME
DECLARE @TrackEnd DATETIME -- Mostly for convienence, Use of both @CursorDate and @PreviousDate could 100% replace this
DECLARE @TrackHours INT
DECLARE @TrackColour INT 

DECLARE @GREEN  INT = 1
DECLARE @AMBER  INT = 2
DECLARE @RED    INT = 3

CREATE TABLE #AlertPeriods 
    ([EDISID] INT NOT NULL, [InputID] INT NOT NULL, [EquipmentDescription] VARCHAR(1024) NOT NULL, [Type] VARCHAR(255) NOT NULL, 
     [Start] DATETIME NOT NULL, [End] DATETIME NOT NULL, [Hours] INT NOT NULL, [Colour] INT NOT NULL)

DECLARE Cursor_Sequence CURSOR FAST_FORWARD FOR
SELECT 
    [R].[EDISID],
    [R].[EquipmentInputID],
    [R].[EquipmentDescription],
    [R].[Type],
    [R].[Date],
    CAST(CASE WHEN ([R2].[Date] IS NOT NULL OR [R3].[Date] IS NOT NULL) AND [R].[Green] = 0
            THEN 1
            ELSE 0
            END AS BIT) AS [AdjacentPureAmberRed],
    [R].[Amber],
    [R].[Red]
FROM #Readings AS [R]
LEFT JOIN #Readings AS [R2]
    ON ([R].[Date] = DATEADD(HOUR, 1, [R2].[Date]))
    AND [R].[EDISID] = [R2].[EDISID]
    AND [R].[EquipmentInputID] = [R2].[EquipmentInputID]
    AND [R].[EquipmentDescription] = [R2].[EquipmentDescription]
    AND [R].[Type] = [R2].[Type]
    AND [R2].[Amber] = 0  -- HACK: Temporarily Remove Amber
    AND [R2].[Green] = 0
LEFT JOIN #Readings AS [R3]
    ON ([R].[Date] = DATEADD(HOUR, -1, [R3].[Date]))
    AND [R].[EDISID] = [R3].[EDISID]
    AND [R].[EquipmentInputID] = [R3].[EquipmentInputID]
    AND [R].[EquipmentDescription] = [R3].[EquipmentDescription]
    AND [R].[Type] = [R3].[Type]
    AND [R3].[Amber] = 0  -- HACK: Temporarily Remove Amber
    AND [R3].[Green] = 0
WHERE @DebugInputID IS NULL OR [R].[EquipmentInputID] = @DebugInputID
--AND [R].[Green] = 0
ORDER BY 
    [EDISID],
    [EquipmentInputID],
    [Type],
    [Date]

OPEN Cursor_Sequence

FETCH NEXT FROM Cursor_Sequence INTO @CursorEDISID, @CursorInputID, @CursorDescription, @CursorType, @CursorDate, @CursorAdjacent, @CursorAmber, @CursorRed

WHILE @@FETCH_STATUS = 0
BEGIN
    IF ((@PreviousEDISID IS NULL OR @PreviousEDISID <> @CursorEDISID) OR (@PreviousInputID IS NULL OR @PreviousInputID <> @CursorInputID) OR
        (@PreviousDescription IS NULL OR @PreviousDescription <> @CursorDescription) OR (@PreviousType IS NULL OR @PreviousType <> @CursorType))
    BEGIN
        -- We have switched Product/Site context

        IF (@PreviousEDISID IS NOT NULL AND @TrackColour <> 0 AND @TrackHours >= @ConsistentPeriod)
        BEGIN
            -- Save occurrance if it meets requirements (Amber/Red with over @ConsistentPeriod hours involved)
            INSERT INTO #AlertPeriods ([EDISID], [InputID], [EquipmentDescription], [Type], [Start], [End], [Hours], [Colour])
            VALUES (@PreviousEDISID, @PreviousInputID, @PreviousDescription, @PreviousType, @TrackStart, @PreviousDate, @TrackHours, @TrackColour)
        END

        -- Reset all previous/tracking values
        SELECT  @PreviousEDISID = NULL,
                @PreviousDescription = NULL,
                @PreviousInputID = NULL,
                @PreviousType = NULL,
                @TrackColour = 0,
                @TrackHours = 0,
                @TrackStart = NULL,
                @TrackEnd = NULL
    END

    IF @CursorAdjacent = 1
    BEGIN
        -- We have adjacent Amber/Red hours, track the record
        SET @TrackHours = @TrackHours + 1

        IF @TrackStart IS NULL
        BEGIN
            SET @TrackStart = @CursorDate
        END

        IF @CursorAmber > 0 AND @TrackColour < @AMBER
        BEGIN
            SET @TrackColour = @AMBER
        END

        IF @CursorRed > 0 AND @TrackColour <= @GREEN -- HACK: Temporarily Remove Amber   -- < @RED
        BEGIN
            -- Red can only occur if Amber doesn't
            SET @TrackColour = @RED
        END
    END

    IF @CursorAdjacent = 0
    BEGIN
        -- There are no adjacent Amber/Red hours, period has ended
        IF @TrackHours >= @ConsistentPeriod
        BEGIN
            IF @TrackStart IS NOT NULL AND @TrackEnd IS NULL
            BEGIN
                -- An Amber/Red period was started
                SET @TrackEnd = @CursorDate
            END

            -- Save occurrance if it meets requirements
            INSERT INTO #AlertPeriods ([EDISID], [InputID], [EquipmentDescription], [Type], [Start], [End], [Hours], [Colour])
            VALUES (@PreviousEDISID, @PreviousInputID, @PreviousDescription, @PreviousType, @TrackStart, @TrackEnd, @TrackHours, @TrackColour)
        END

        -- Reset tracking
        SET @TrackHours = 0
        SET @TrackStart = NULL
        SET @TrackEnd = NULL
    END

    /* For Testing */
    --SELECT
    --    @CursorEDISID AS [EDISID],
    --    @CursorPump AS [Pump],
    --    @CursorProduct AS [Product],
    --    --@CursorType AS [Type],
    --    @CursorDate AS [Date],
    --    @CursorAdjacent AS [Adjacent],
    --    @TrackColour AS [Tracked Colour],
    --    @TrackHours AS [Tracked Hours],
    --    @TrackStart AS [Tracked Period Start],
    --    @TrackEnd AS [Tracked Period End]

    -- Save current values
    SELECT  @PreviousEDISID = @CursorEDISID,
            @PreviousDescription = @CursorDescription,
            @PreviousInputID = @CursorInputID,
            @PreviousType = @CursorType,
            @PreviousDate = @CursorDate

    FETCH NEXT FROM Cursor_Sequence INTO @CursorEDISID, @CursorInputID, @CursorDescription, @CursorType, @CursorDate, @CursorAdjacent, @CursorAmber, @CursorRed
END

-- Catch any trailing records
IF (@PreviousEDISID IS NOT NULL AND @TrackColour <> 0 AND @TrackHours >= @ConsistentPeriod)
BEGIN
    -- Save occurrance if it meets requirements (@TrackEnd will not have been set)
    INSERT INTO #AlertPeriods ([EDISID], [InputID], [EquipmentDescription], [Type], [Start], [End], [Hours], [Colour])
    VALUES (@PreviousEDISID, @PreviousInputID, @PreviousDescription, @PreviousType, @TrackStart, @CursorDate, @TrackHours, @TrackColour)
END

CLOSE Cursor_Sequence
DEALLOCATE Cursor_Sequence

IF @DebugSequence = 1
BEGIN
    SELECT *
    FROM #AlertPeriods
END

/* If either of the below datasets contain rows it is considered in exception */
CREATE TABLE #Exceptions ([EDISID] INT NOT NULL, [InputID] INT NOT NULL, [Description] VARCHAR(1024) NOT NULL, [Type] VARCHAR(255) NOT NULL, [Status] INT NOT NULL)

INSERT INTO #Exceptions ([EDISID], [InputID], [Description], [Type], [Status])
/* Consistent Data (Amber+ for 6 Hours) */
SELECT DISTINCT
    [EDISID],
    [InputID],
    [EquipmentDescription],
    [Type],
    [Colour]
FROM #AlertPeriods -- Only contains records which have breached the Consistent Data rule
WHERE [Colour] = @RED
UNION
/* Occurrances (8x Red/Amber over 24 hours) */
SELECT DISTINCT
    [R].[EDISID],
    [R].[EquipmentInputID],
    [R].[EquipmentDescription],
    [R].[Type],
    --[Green],
    --[Amber],
    --[Red],
    @RED AS [Status] -- HACK: Temporarily Remove Amber
    --CASE
    --    WHEN SUM([Red]) > 0 -- Any Red at all means the outcome is Red 
    --    THEN 3 -- Red
    --    ELSE 2 -- Amber
    --    END AS [Status]
    --,'Occurrances' AS [Rule]
FROM #Readings AS [R]
GROUP BY 
    [R].[EDISID],
    [R].[EquipmentInputID],
    [R].[EquipmentDescription],
    [R].[Type]
HAVING
    SUM([Red]) >= @Occurrances -- HACK: Temporarily Remove Amber
    --SUM([Amber] + [Red]) >= @Occurrances -- Must have at least the number of values


SELECT 
    [Exceptions].[EDISID],
    --[Sites].[SiteID],               -- *Debug*
    --[Sites].[Name],                 -- *Debug*
    --@DebugFixedDate AS [Generated], -- *Debug*
    (CASE
		WHEN [Exceptions].[Status] = 3 THEN 'Red'
		WHEN [Exceptions].[Status] = 2 THEN 'Amber'
	END) + ' - ' + [EquipmentList] AS [Detail] 
    ,[Ex].[InputID]
FROM (
    SELECT
        [E].[EDISID],
        MAX([Status]) AS [Status],
        MIN([Info].[EquipmentList]) AS [EquipmentList]
    FROM #Exceptions AS [E]
    JOIN (
        SELECT DISTINCT
            [EDISID],
            SUBSTRING(
                (   SELECT 
                        --';' + CAST([InputID] AS VARCHAR(10)) + '|' + [Type]
                        ';' + CAST([InputID] AS VARCHAR(10)) + ':' + [Type] + '|' + (CASE WHEN [Status] = 3 THEN 'Red' WHEN [Status] = 2 THEN 'Amber' END)
                    FROM #Exceptions
                    WHERE [EDISID] = [E].[EDISID] 
                    FOR XML PATH (''), TYPE).value('.','VARCHAR(4000)')
                ,2, 4000) AS [EquipmentList]
        FROM #Exceptions AS [E]
        ) AS [Info] ON [E].[EDISID] = [Info].[EDISID]
    GROUP BY 
        [E].[EDISID]
    ) AS [Exceptions]
--JOIN [dbo].[Sites] ON [Exceptions].[EDISID] = [Sites].[EDISID]   -- *Debug*
JOIN #Exceptions AS [Ex] ON [Exceptions].[EDISID] = [Ex].[EDISID]
--ORDER BY [Exceptions].[EDISID]--, [Ex].[InputID]    -- *Debug*

DROP TABLE #EquipmentCalls
DROP TABLE #AlertPeriods
DROP TABLE #Exceptions
DROP TABLE #Readings

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ExceptionEquipmentTemperatureIssue] TO PUBLIC
    AS [dbo];

