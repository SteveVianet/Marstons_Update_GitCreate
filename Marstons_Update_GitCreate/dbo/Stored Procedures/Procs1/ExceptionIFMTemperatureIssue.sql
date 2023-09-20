CREATE PROCEDURE [dbo].[ExceptionIFMTemperatureIssue]
(
	@EDISID INT = NULL,
	@Auditor VARCHAR(255) = NULL
)
AS

/* For Testing */
--DECLARE @Auditor VARCHAR(255) = NULL
--DECLARE @EDISID INT = NULL --3282
--DECLARE @SiteID VARCHAR (15) = NULL --'8345'
--IF @SiteID IS NOT NULL
--    SELECT @EDISID = [EDISID] FROM [dbo].[Sites] WHERE [SiteID] = @SiteID

DECLARE @EnableLogging BIT = 1
DECLARE @DebugDayShift INT = 0
DECLARE @DebugFixedDate DATETIME = NULL
DECLARE @DebugDates BIT = 0
DECLARE @DebugParameters BIT = 0
DECLARE @DebugReadings BIT = 0
DECLARE @DebugPump INT
DECLARE @DebugStatus BIT = 0
DECLARE @DebugSequence BIT = 0
DECLARE @DebugAddresses BIT = 0

DECLARE @ColdIdent1 VARCHAR(50) = 'cold'
DECLARE @ColdIdent2 VARCHAR(50) = 'chiled'

DECLARE @MaxPMAddress INT = 399 -- Primarily added to work around a GW3 bug, but probably best practice to include anyway

SET NOCOUNT ON;
SET DATEFIRST 1;

/* Debugging */
--SET @EnableLogging = 0
--SET @DebugDayShift = -2
--SET @DebugFixedDate = '2017-02-07 10:55:00'
--SET @DebugFixedDate = '2017-02-06 03:00:00'
--SET @DebugDates = 1
--SET @DebugParameters = 1
--SET @DebugReadings = 1
--SET @DebugPump = 6
--SET @DebugStatus = 1
--SET @DebugSequence = 1
--SET @DebugAddresses = 1

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

-- Keg (IsCask = 0, IsMetric = 0)
DECLARE @Keg_Amber_Lower_Min INT
DECLARE @Keg_Amber_Lower_Max INT
DECLARE @Keg_Amber_Higher_Min INT
DECLARE @Keg_Amber_Higher_Max INT

-- Cask (IsCask = 1)
DECLARE @Cask_Amber_Lower_Min INT
DECLARE @Cask_Amber_Lower_Max INT
DECLARE @Cask_Amber_Higher_Min INT
DECLARE @Cask_Amber_Higher_Max INT

-- Extra Cold (String Matching *keep your fingers crossed!*)
DECLARE @XtraCold_Amber_Lower_Min INT
DECLARE @XtraCold_Amber_Lower_Max INT
DECLARE @XtraCold_Amber_Higher_Min INT
DECLARE @XtraCold_Amber_Higher_Max INT

-- US Draft
DECLARE @US_Draft_Amber_Lower_Min INT
DECLARE @US_Draft_Amber_Lower_Max INT
DECLARE @US_Draft_Amber_Higher_Min INT
DECLARE @US_Draft_Amber_Higher_Max INT

-- US Cider
DECLARE @US_Cider_Amber_Lower_Min INT
DECLARE @US_Cider_Amber_Lower_Max INT
DECLARE @US_Cider_Amber_Higher_Min INT
DECLARE @US_Cider_Amber_Higher_Max INT

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

SELECT @ConsistentPeriod            = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'IFMTempConsistentData'
SELECT @Occurrances                 = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'IFMTempOccurrances'

SELECT @Keg_Amber_Lower_Min         = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'IFMAmberKegLowerLow'
SELECT @Keg_Amber_Lower_Max         = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'IFMAmberKegLowerHigh'
SELECT @Keg_Amber_Higher_Min        = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'IFMAmberKegUpperLow'
SELECT @Keg_Amber_Higher_Max        = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'IFMAmberKegUpperHigh'

SELECT @Cask_Amber_Lower_Min        = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'IFMAmberCaskLowerLow'
SELECT @Cask_Amber_Lower_Max        = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'IFMAmberCaskLowerHigh'
SELECT @Cask_Amber_Higher_Min       = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'IFMAmberCaskUpperLow'
SELECT @Cask_Amber_Higher_Max       = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'IFMAmberCaskUpperHigh'

SELECT @XtraCold_Amber_Lower_Min    = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'IFMAmberXtraColdLowerLow'
SELECT @XtraCold_Amber_Lower_Max    = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'IFMAmberXtraColdLowerHigh'
SELECT @XtraCold_Amber_Higher_Min   = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'IFMAmberXtraColdUpperLow'
SELECT @XtraCold_Amber_Higher_Max   = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'IFMAmberXtraColdUpperHigh'

SELECT @US_Draft_Amber_Lower_Min    = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'IFMAmberDraftLowerLow-US'
SELECT @US_Draft_Amber_Lower_Max    = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'IFMAmberDraftLowerHigh-US'
SELECT @US_Draft_Amber_Higher_Min   = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'IFMAmberDraftUpperLow-US'
SELECT @US_Draft_Amber_Higher_Max   = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'IFMAmberDraftUpperHigh-US'

SELECT @US_Cider_Amber_Lower_Min    = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'IFMAmberCiderLowerLow-US'
SELECT @US_Cider_Amber_Lower_Max    = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'IFMAmberCiderLowerHigh-US'
SELECT @US_Cider_Amber_Higher_Min   = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'IFMAmberCiderUpperLow-US'
SELECT @US_Cider_Amber_Higher_Max   = CAST([NP].[ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP] WHERE [NP].[ParameterName] = 'IFMAmberCiderUpperHigh-US'

IF @DebugParameters = 1
BEGIN
SELECT 
    @ConsistentPeriod [ConsistentPeriod],
    @Occurrances [Occurrances],
    @Keg_Amber_Lower_Min [Keg_Amber_Lower_Min],
    @Keg_Amber_Lower_Max [@Keg_Amber_Lower_Max],
    @Keg_Amber_Higher_Min [Keg_Amber_Higher_Min],
    @Keg_Amber_Higher_Max [Keg_Amber_Higher_Max],
    @Cask_Amber_Lower_Min [Cask_Amber_Lower_Min],
    @Cask_Amber_Lower_Max [Cask_Amber_Lower_Max],
    @Cask_Amber_Higher_Min [Cask_Amber_Higher_Min],
    @Cask_Amber_Higher_Max [Cask_Amber_Higher_Max],
    @XtraCold_Amber_Lower_Min [XtraCold_Amber_Lower_Min],
    @XtraCold_Amber_Lower_Max [XtraCold_Amber_Lower_Max],
    @XtraCold_Amber_Higher_Min [XtraCold_Amber_Higher_Min],
    @XtraCold_Amber_Higher_Max [XtraCold_Amber_Higher_Max],
    @US_Draft_Amber_Lower_Min [US_Draft_Amber_Lower_Min],
    @US_Draft_Amber_Lower_Max [US_Draft_Amber_Lower_Max],
    @US_Draft_Amber_Higher_Min [US_Draft_Amber_Higher_Min],
    @US_Draft_Amber_Higher_Max [US_Draft_Amber_Higher_Max],
    @US_Cider_Amber_Lower_Min [US_Cider_Amber_Lower_Min],
    @US_Cider_Amber_Lower_Max [US_Cider_Amber_Lower_Max],
    @US_Cider_Amber_Higher_Min [US_Cider_Amber_Higher_Min],
    @US_Cider_Amber_Higher_Max [US_Cider_Amber_Higher_Max]
END

-- Get the IFM addresses for the date in question
-- Stolen from [dbo].[GetPumpAddressesForDay]
DECLARE @IFMs TABLE (EDISID INT NOT NULL, CreateDate DATE NOT NULL, CurrentDate DATE NOT NULL, Pump INT NOT NULL, IFM INT NOT NULL)

INSERT INTO @IFMs (EDISID, CreateDate, CurrentDate, Pump, IFM)
SELECT
    PFS.EDISID,
    CAST(PFS.CreateDate AS DATE) AS CreateDate,
    CAST(@From AS DATE) AS CurrentDate,
    PFSI.FontNumber,
    PFSI.PhysicalAddress
FROM ProposedFontSetups AS PFS
JOIN (
    SELECT 
        PFS.EDISID,
        MAX(PFS.ID) AS [RelevantPFS]
    FROM dbo.ProposedFontSetups AS PFS
	
    WHERE 
        (@EDISID IS NULL OR PFS.EDISID = @EDISID)
    AND CAST(CreateDate As DATE) <= @From
    GROUP BY EDISID
    ) AS [RelevantPFS] ON [PFS].[ID] = [RelevantPFS].[RelevantPFS] AND [PFS].[EDISID] = [RelevantPFS].[EDISID]
LEFT JOIN ProposedFontSetupItems AS PFSI ON PFS.ID = PFSI.ProposedFontSetupID
JOIN Sites on Sites.EDISID = PFS.EDISID
WHERE 
    (@EDISID IS NULL OR PFS.EDISID = @EDISID)
AND (@Auditor IS NULL OR LOWER(SiteUser) = LOWER(@Auditor))
AND PFSI.PhysicalAddress IS NOT NULL
AND PFSI.PhysicalAddress > @MaxPMAddress -- Exclude Pulse Meters

IF @DebugAddresses = 1
BEGIN
    SELECT *
    FROM @IFMs
    ORDER BY 
        [EDISID], 
        [Pump]

    SELECT
        PFS.EDISID,
        CAST(PFS.CreateDate AS DATE) AS CreateDate,
        CAST(@From AS DATE) AS CurrentDate,
        PFSI.FontNumber,
        PFSI.PhysicalAddress
    FROM ProposedFontSetups AS PFS
    JOIN (
        SELECT 
            PFS.EDISID,
            MAX(PFS.ID) AS [RelevantPFS]
        FROM dbo.ProposedFontSetups AS PFS
	
        WHERE 
            (@EDISID IS NULL OR PFS.EDISID = @EDISID)
        AND CAST(CreateDate As DATE) <= @From
        GROUP BY EDISID
        ) AS [RelevantPFS] ON [PFS].[ID] = [RelevantPFS].[RelevantPFS] AND [PFS].[EDISID] = [RelevantPFS].[EDISID]
    LEFT JOIN ProposedFontSetupItems AS PFSI ON PFS.ID = PFSI.ProposedFontSetupID
    JOIN Sites on Sites.EDISID = PFS.EDISID
    WHERE 
        (@EDISID IS NULL OR PFS.EDISID = @EDISID)
    AND (@Auditor IS NULL OR LOWER(SiteUser) = LOWER(@Auditor))
    AND PFSI.PhysicalAddress IS NOT NULL
    AND PFSI.PhysicalAddress <= @MaxPMAddress -- OnlyPulse Meters
END

/*
-- LEGACY LOGGER
-- Get all non-closed Calls which involve Equipment
-- Stolen from [dbo].[GetCalls]
CREATE TABLE #IFMCalls (CallID INT NOT NULL, EDISID INT NOT NULL, IFMAddress INT NOT NULL, Pump INT NOT NULL)
INSERT INTO #IFMCalls (CallID, EDISID, IFMAddress, Pump)
SELECT
    Calls.[ID],
	Calls.EDISID,
    IFMs.IFM,
    SIQ.RealPumpID
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
LEFT JOIN dbo.ServiceIssuesQuality AS SIQ ON Calls.ID = SIQ.CallID AND Calls.EDISID = SIQ.EDISID
LEFT JOIN @IFMs AS IFMs ON SIQ.RealEDISID = IFMs.EDISID AND SIQ.RealPumpID = IFMs.Pump 
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
AND SIQ.RealPumpID IS NOT NULL
AND IFMs.IFM IS NOT NULL
*/

-- JOB WATCH
CREATE TABLE #IFMCalls (EDISID INT NOT NULL, IFMAddress INT NOT NULL, Pump INT NOT NULL)
INSERT INTO #IFMCalls (EDISID, IFMAddress, Pump)
SELECT
    [JobWatchCalls].[EdisID],
    [JobWatchCallsData].[IFMAddress],
    [JobWatchCallsData].[Pump]
FROM [dbo].[JobWatchCalls]
JOIN [dbo].[JobWatchCallsData] ON [JobWatchCalls].[JobId] = [JobWatchCallsData].[JobId]
WHERE [JobWatchCalls].[JobActive] = 1
AND [JobWatchCallsData].[Pump] IS NOT NULL
AND [JobWatchCallsData].[IFMAddress] IS NOT NULL

--SELECT * FROM #IFMCalls

IF @DebugReadings = 1 AND @DebugPump IS NOT NULL
BEGIN
    SELECT * 
    FROM [dbo].[DispenseActions] AS [DA]
    JOIN [dbo].[Sites] AS [S] ON [DA].[EDISID] = [S].[EDISID]
    JOIN [dbo].[Products] AS [P] ON [DA].[Product] = [P].[ID]
    JOIN [dbo].[ProductCategories] AS [PC] ON [P].[CategoryID] = [PC].[ID]
    JOIN @IFMs AS [IFM] ON [DA].[EDISID] = [IFM].[EDISID] AND [DA].[Pump] = [IFM].[Pump] -- Restrict results to only known IFMs (GW3 can incorrectly add IFM data for PMs)
    WHERE
        [S].[LastDownload] >= @From 
    AND [DA].[StartTime] BETWEEN @From AND @To
    AND (@EDISID IS NULL OR [S].[EDISID] = @EDISID)
    AND [DA].[Pump] = @DebugPump
    AND [DA].[LiquidType] = 2 -- Product Only
END

CREATE TABLE #Readings 
    ([EDISID] INT NOT NULL, [Pump] INT NOT NULL, [Product] VARCHAR(50) NOT NULL, [Type] VARCHAR(255) NOT NULL, 
     [Date] DATETIME NOT NULL, [Day] DATE NOT NULL, [Hour] INT NOT NULL, [Green] INT, [Amber] INT, [Red] INT)
INSERT INTO #Readings ([EDISID], [Pump], [Product], [Type], [Date], [Day], [Hour], [Green], [Amber], [Red])

SELECT
    [S].[EDISID],
    [DA].[Pump],
    [P].[Description] AS [Product],
    --[P].[IsCask],
    --CASE WHEN ([P].[IsCask] = 0 AND [P].[IsMetric] = 0 AND [P].[IsWater] = 0)
    --     THEN 1 ELSE 0 END AS [IsKeg],
    --CASE WHEN ([P].[IsMetric] = 0 AND [P].[IsWater] = 0) AND (CHARINDEX(@ColdIdent1, LOWER([P].[Description])) > 0 OR CHARINDEX(@ColdIdent2, LOWER([P].[Description])) > 0)
    --     THEN 1 ELSE 0 END AS [ExtraCold],
    CASE WHEN [US].[EDISID] IS NULL
         THEN CASE WHEN ([P].[IsMetric] = 0 AND [P].[IsWater] = 0) AND (CHARINDEX(@ColdIdent1, LOWER([P].[Description])) > 0 OR CHARINDEX(@ColdIdent2, LOWER([P].[Description])) > 0)
                   THEN 'Extra Cold'
                   WHEN ([P].[IsCask] = 0 AND [P].[IsMetric] = 0 AND [P].[IsWater] = 0)
                   THEN 'Keg'
                   WHEN ([P].[IsCask] = 1 AND [P].[IsMetric] = 0 AND [P].[IsWater] = 0)
                   THEN 'Cask'
                   ELSE 'Unknown'
                   END
         WHEN [US].[EDISID] IS NOT NULL
         THEN CASE WHEN LOWER([PC].[Description]) = 'draft'
                   THEN 'US Draft'
                   WHEN LOWER([PC].[Description]) = 'cider'
                   THEN 'US Cider'
                   ELSE 'Unknown'
                   END
         ELSE 'Unknown'
         END AS [Type],
    DATEADD(MINUTE, -DATEPART(MINUTE, [DA].[StartTime]), DATEADD(SECOND, -DATEPART(SECOND, [DA].[StartTime]), DATEADD(MILLISECOND, -DATEPART(MILLISECOND, [DA].[StartTime]), [DA].[StartTime]))) AS [Date],
    CAST([DA].[StartTime] AS DATE) AS [Day],
    DATEPART(HOUR, [DA].[StartTime]) AS [Hour],
    COUNT(
        CASE -- Instances of Green
            WHEN ([P].[IsCask] = 0 AND [P].[IsMetric] = 0 AND [P].[IsWater] = 0) AND [US].[EDISID] IS NULL AND (CHARINDEX('cold', LOWER([P].[Description])) = 0 AND CHARINDEX('chilled', LOWER([P].[Description])) = 0)
            THEN    -- Keg (Non-US)
                CASE 
                    WHEN ([DA].[AverageTemperature] >= @Keg_Amber_Lower_Max AND [DA].[AverageTemperature] < @Keg_Amber_Higher_Min)
                    THEN [DA].[AverageTemperature]
                    ELSE NULL
                    END
            WHEN ([P].[IsCask] = 1 AND [P].[IsMetric] = 0 AND [P].[IsWater] = 0) AND [US].[EDISID] IS NULL AND (CHARINDEX('cold', LOWER([P].[Description])) = 0 AND CHARINDEX('chilled', LOWER([P].[Description])) = 0)
            THEN    -- Cask (Non-US)
                CASE
                    WHEN ([DA].[AverageTemperature] >= @Cask_Amber_Lower_Max AND [DA].[AverageTemperature] < @Cask_Amber_Higher_Min)
                    THEN [DA].[AverageTemperature]
                    ELSE NULL
                    END
            WHEN ([P].[IsMetric] = 0 AND [P].[IsWater] = 0) AND [US].[EDISID] IS NULL AND (CHARINDEX('cold', LOWER([P].[Description])) > 0 OR CHARINDEX('chilled', LOWER([P].[Description])) > 0)
            THEN    -- "Extra Cold" (Non-US)
                CASE
                    WHEN ([DA].[AverageTemperature] >= @XtraCold_Amber_Lower_Max AND [DA].[AverageTemperature] < @XtraCold_Amber_Higher_Min)
                    THEN [DA].[AverageTemperature]
                    ELSE NULL
                    END
            WHEN LOWER([PC].[Description]) = 'draft' AND [US].[EDISID] IS NOT NULL
            THEN    -- Draft (US)
                CASE
                    WHEN ([DA].[AverageTemperature] >= @US_Draft_Amber_Lower_Max AND [DA].[AverageTemperature] < @US_Draft_Amber_Higher_Min)
                    THEN [DA].[AverageTemperature]
                    ELSE NULL
                    END
            WHEN LOWER([PC].[Description]) = 'cider' AND [US].[EDISID] IS NOT NULL
            THEN    -- Cider (US)
                CASE
                    WHEN ([DA].[AverageTemperature] >= @US_Cider_Amber_Lower_Max AND [DA].[AverageTemperature] < @US_Draft_Amber_Higher_Min)
                    THEN [DA].[AverageTemperature]
                    ELSE NULL
                    END
            END
    ) AS [Green],
    COUNT(
        CASE -- Instances of Amber
            WHEN ([P].[IsCask] = 0 AND [P].[IsMetric] = 0 AND [P].[IsWater] = 0) AND [US].[EDISID] IS NULL AND (CHARINDEX('cold', LOWER([P].[Description])) = 0 AND CHARINDEX('chilled', LOWER([P].[Description])) = 0)
            THEN    -- Keg (Non-US)
                CASE 
                    WHEN (([DA].[AverageTemperature] >= @Keg_Amber_Lower_Min AND [DA].[AverageTemperature] < @Keg_Amber_Lower_Max)
                            OR
                          ([DA].[AverageTemperature] >= @Keg_Amber_Higher_Min AND [DA].[AverageTemperature] < @Keg_Amber_Higher_Max))
                    THEN [DA].[AverageTemperature]
                    ELSE NULL
                    END
            WHEN ([P].[IsCask] = 1 AND [P].[IsMetric] = 0 AND [P].[IsWater] = 0) AND [US].[EDISID] IS NULL AND (CHARINDEX('cold', LOWER([P].[Description])) = 0 AND CHARINDEX('chilled', LOWER([P].[Description])) = 0)
            THEN    -- Cask (Non-US)
                CASE
                    WHEN (([DA].[AverageTemperature] >= @Cask_Amber_Lower_Min AND [DA].[AverageTemperature] < @Cask_Amber_Lower_Max)
                            OR
                          ([DA].[AverageTemperature] >= @Cask_Amber_Higher_Min AND [DA].[AverageTemperature] < @Cask_Amber_Higher_Max))
                    THEN [DA].[AverageTemperature]
                    ELSE NULL
                    END
            WHEN ([P].[IsMetric] = 0 AND [P].[IsWater] = 0) AND [US].[EDISID] IS NULL AND (CHARINDEX('cold', LOWER([P].[Description])) > 0 OR CHARINDEX('chilled', LOWER([P].[Description])) > 0)
            THEN    -- "Extra Cold" (Non-US)
                CASE
                    WHEN (([DA].[AverageTemperature] >= @XtraCold_Amber_Lower_Min AND [DA].[AverageTemperature] < @XtraCold_Amber_Lower_Max)
                            OR
                          ([DA].[AverageTemperature] >= @XtraCold_Amber_Higher_Min AND [DA].[AverageTemperature] < @XtraCold_Amber_Higher_Max))
                    THEN [DA].[AverageTemperature]
                    ELSE NULL
                    END
            WHEN LOWER([PC].[Description]) = 'draft' AND [US].[EDISID] IS NOT NULL
            THEN    -- Draft (US)
                CASE
                    WHEN (([DA].[AverageTemperature] >= @US_Draft_Amber_Lower_Min AND [DA].[AverageTemperature] < @US_Draft_Amber_Lower_Max)
                            OR
                          ([DA].[AverageTemperature] >= @US_Draft_Amber_Higher_Min AND [DA].[AverageTemperature] < @US_Draft_Amber_Higher_Max))
                    THEN [DA].[AverageTemperature]
                    ELSE NULL
                    END
            WHEN LOWER([PC].[Description]) = 'cider' AND [US].[EDISID] IS NOT NULL
            THEN    -- Cider (US)
                CASE
                    WHEN (([DA].[AverageTemperature] >= @US_Cider_Amber_Lower_Min AND [DA].[AverageTemperature] < @US_Cider_Amber_Lower_Max)
                            OR
                          ([DA].[AverageTemperature] >= @US_Cider_Amber_Higher_Min AND [DA].[AverageTemperature] < @US_Cider_Amber_Higher_Max))
                    THEN [DA].[AverageTemperature]
                    ELSE NULL
                    END
            END
    ) AS [Amber],
    COUNT(
        CASE -- Instances of Red
            WHEN ([P].[IsCask] = 0 AND [P].[IsMetric] = 0 AND [P].[IsWater] = 0) AND [US].[EDISID] IS NULL AND (CHARINDEX('cold', LOWER([P].[Description])) = 0 AND CHARINDEX('chilled', LOWER([P].[Description])) = 0)
            THEN    -- Keg (Non-US)
                CASE 
                    WHEN ([DA].[AverageTemperature] < @Keg_Amber_Lower_Min OR [DA].[AverageTemperature] >= @Keg_Amber_Higher_Max)
                    THEN [DA].[AverageTemperature]
                    ELSE NULL
                    END
            WHEN ([P].[IsCask] = 1 AND [P].[IsMetric] = 0 AND [P].[IsWater] = 0) AND [US].[EDISID] IS NULL AND (CHARINDEX('cold', LOWER([P].[Description])) = 0 AND CHARINDEX('chilled', LOWER([P].[Description])) = 0)
            THEN    -- Cask (Non-US)
                CASE
                    WHEN ([DA].[AverageTemperature] < @Cask_Amber_Lower_Min OR [DA].[AverageTemperature] >= @Cask_Amber_Higher_Max)
                    THEN [DA].[AverageTemperature]
                    ELSE NULL
                    END
            WHEN ([P].[IsMetric] = 0 AND [P].[IsWater] = 0) AND [US].[EDISID] IS NULL AND (CHARINDEX('cold', LOWER([P].[Description])) > 0 OR CHARINDEX('chilled', LOWER([P].[Description])) > 0)
            THEN    -- "Extra Cold" (Non-US)
                CASE
                    WHEN ([DA].[AverageTemperature] < @XtraCold_Amber_Lower_Min OR [DA].[AverageTemperature] >= @XtraCold_Amber_Higher_Max)
                    THEN [DA].[AverageTemperature]
                    ELSE NULL
                    END
            WHEN LOWER([PC].[Description]) = 'draft' AND [US].[EDISID] IS NOT NULL
            THEN    -- Draft (US)
                CASE
                    WHEN ([DA].[AverageTemperature] < @US_Draft_Amber_Lower_Min OR [DA].[AverageTemperature] >= @US_Draft_Amber_Higher_Max)
                    THEN [DA].[AverageTemperature]
                    ELSE NULL
                    END
            WHEN LOWER([PC].[Description]) = 'cider' AND [US].[EDISID] IS NOT NULL
            THEN    -- Cider (US)
                CASE
                    WHEN ([DA].[AverageTemperature] < @US_Cider_Amber_Lower_Min OR [DA].[AverageTemperature] >= @US_Draft_Amber_Higher_Max)
                    THEN [DA].[AverageTemperature]
                    ELSE NULL
                    END
            END
    ) AS [Red]
FROM [dbo].[DispenseActions] AS [DA]
JOIN [dbo].[Sites] AS [S] ON [DA].[EDISID] = [S].[EDISID]
JOIN [dbo].[Products] AS [P] ON [DA].[Product] = [P].[ID]
JOIN [dbo].[ProductCategories] AS [PC] ON [P].[CategoryID] = [PC].[ID]
JOIN @IFMs AS [IFM] ON [DA].[EDISID] = [IFM].[EDISID] AND [DA].[Pump] = [IFM].[Pump] -- Restrict results to only known IFMs (GW3 can incorrectly add IFM data for PMs)
LEFT JOIN #IFMCalls AS [IC] ON [DA].[EDISID] = [IC].[EDISID] AND [DA].[Pump] = [IC].[Pump]
LEFT JOIN @US_Sites AS [US] ON [S].[EDISID] = [US].[EDISID]
WHERE
    [S].[LastDownload] >= @From 
AND [DA].[StartTime] BETWEEN @From AND @To
AND [DA].[LiquidType] = 2 -- Product Only
AND (@EDISID IS NULL OR [S].[EDISID] = @EDISID)
AND (@Auditor IS NULL OR SiteUser = @Auditor)
AND [IC].[IFMAddress] IS NULL
AND (@DebugPump IS NULL OR [DA].[Pump] = @DebugPump)
GROUP BY
    [S].[EDISID],
    [DA].[Pump],
    [P].[Description],
    [PC].[Description],
    [P].[IsCask],
    [P].[IsMetric],
    [P].[IsWater],
    [US].[EDISID],
    DATEADD(MINUTE, -DATEPART(MINUTE, [DA].[StartTime]), DATEADD(SECOND, -DATEPART(SECOND, [DA].[StartTime]), DATEADD(MILLISECOND, -DATEPART(MILLISECOND, [DA].[StartTime]), [DA].[StartTime]))),
    CAST([DA].[StartTime] AS DATE),
    DATEPART(HOUR, [DA].[StartTime])
ORDER BY
    [S].[EDISID],
    [DA].[Pump],
    [P].[Description],
    CAST([DA].[StartTime] AS DATE),
    DATEPART(HOUR, [DA].[StartTime])


IF @DebugReadings = 1
BEGIN
    SELECT 
        [R].[EDISID],
        [R].[Pump],
        [R].[Product],
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
        AND [R].[Pump] = [R2].[Pump]
        AND [R].[Product] = [R2].[Product]
        AND [R].[Type] = [R2].[Type]
        AND [R2].[Amber] = 0  -- HACK: Temporarily Remove Amber
        AND [R2].[Green] = 0
    LEFT JOIN #Readings AS [R3]
        ON ([R].[Date] = DATEADD(HOUR, -1, [R3].[Date]))
        AND [R].[EDISID] = [R3].[EDISID]
        AND [R].[Pump] = [R3].[Pump]
        AND [R].[Product] = [R3].[Product]
        AND [R].[Type] = [R3].[Type]
        AND [R3].[Amber] = 0  -- HACK: Temporarily Remove Amber
        AND [R3].[Green] = 0
    WHERE (@DebugPump IS NULL OR [R].[Pump] = @DebugPump)
    --AND [R].[Green] = 0
    ORDER BY 
        [EDISID],
        [Pump],
        [Type],
        [Day],
        [Hour]
END

IF @DebugStatus = 1
BEGIN
    SELECT
        [R].[EDISID],
        [R].[Pump],
        [R].[Product],
        [R].[Type],
        [R].[Date] AS [Date],
        [R].[Day],
        [R].[Hour],
        CASE
            WHEN (([R].[Green] > 0 AND [R].[Amber] = 0 AND [R].[Red] = 0)
                  OR
                  ([R].[Green] = 0 AND [R].[Amber] > 0 AND [R].[Red] = 0)
                  OR
                  ([R].[Green] = 0 AND [R].[Amber] = 0 AND [R].[Red] > 0))
            THEN 1
            ELSE 0
            END AS [Consistent],
        CASE
            WHEN ([R].[Green] > 0 AND [R].[Amber] = 0 AND [R].[Red] = 0)
            THEN 1 -- Green
            WHEN ([R].[Green] = 0 AND [R].[Amber] > 0 AND [R].[Red] = 0)
            THEN 2 -- Amber
            WHEN ([R].[Green] = 0 AND [R].[Amber] = 0 AND [R].[Red] > 0)
            THEN 3 -- Red
            WHEN ([R].[Green] = 0 AND [R].[Amber] = 0 AND [R].[Red] = 0)
            THEN 0 -- Should not happen! Indicates a configuration issue (or logic bug)
            ELSE -1 -- Data is Inconsistent (Contains multiple 'colours')
            END AS [Status]
    FROM #Readings AS [R]
    WHERE @DebugPump IS NULL OR [R].[Pump] = @DebugPump
    ORDER BY
        [R].[EDISID],
        [R].[Pump],
        [R].[Type],
        [R].[Day],
        [R].[Hour]
END

DECLARE @CursorEDISID INT 
DECLARE @CursorPump INT
DECLARE @CursorProduct VARCHAR(50)
DECLARE @CursorType VARCHAR(255)
DECLARE @CursorDate DATETIME
DECLARE @CursorAdjacent BIT
DECLARE @CursorAmber INT
DECLARE @CursorRed INT

DECLARE @PreviousEDISID INT 
DECLARE @PreviousPump INT
DECLARE @PreviousProduct VARCHAR(50)
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
    ([EDISID] INT NOT NULL, [Pump] INT NOT NULL, [Product] VARCHAR(50) NOT NULL, [Type] VARCHAR(255) NOT NULL, 
     [Start] DATETIME NOT NULL, [End] DATETIME NOT NULL, [Hours] INT NOT NULL, [Colour] INT NOT NULL)

DECLARE Cursor_Sequence CURSOR FAST_FORWARD FOR
SELECT 
    [R].[EDISID],
    [R].[Pump],
    [R].[Product],
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
    AND [R].[Pump] = [R2].[Pump]
    AND [R].[Product] = [R2].[Product]
    AND [R].[Type] = [R2].[Type]
    AND [R2].[Amber] = 0  -- HACK: Temporarily Remove Amber
    AND [R2].[Green] = 0
LEFT JOIN #Readings AS [R3]
    ON ([R].[Date] = DATEADD(HOUR, -1, [R3].[Date]))
    AND [R].[EDISID] = [R3].[EDISID]
    AND [R].[Pump] = [R3].[Pump]
    AND [R].[Product] = [R3].[Product]
    AND [R].[Type] = [R3].[Type]
    AND [R3].[Amber] = 0  -- HACK: Temporarily Remove Amber
    AND [R3].[Green] = 0
WHERE (@DebugPump IS NULL OR [R].[Pump] = @DebugPump)
--AND [R].[Green] = 0
ORDER BY 
    [EDISID],
    [Pump],
    [Type],
    [Date]

OPEN Cursor_Sequence

FETCH NEXT FROM Cursor_Sequence INTO @CursorEDISID, @CursorPump, @CursorProduct, @CursorType, @CursorDate, @CursorAdjacent, @CursorAmber, @CursorRed

WHILE @@FETCH_STATUS = 0
BEGIN
    IF ((@PreviousEDISID IS NULL OR @PreviousEDISID <> @CursorEDISID) OR (@PreviousProduct IS NULL OR @PreviousProduct <> @CursorProduct) OR
        (@PreviousPump IS NULL OR @PreviousPump <> @CursorPump) OR (@PreviousType IS NULL OR @PreviousType <> @CursorType))
    BEGIN
        -- We have switched Product/Site context

        IF (@PreviousEDISID IS NOT NULL AND @TrackColour <> 0 AND @TrackHours >= @ConsistentPeriod)
        BEGIN
            -- Save occurrance if it meets requirements (Amber/Red with over @ConsistentPeriod hours involved)
            INSERT INTO #AlertPeriods ([EDISID], [Pump], [Product], [Type], [Start], [End], [Hours], [Colour])
            VALUES (@PreviousEDISID, @PreviousPump, @PreviousProduct, @PreviousType, @TrackStart, @PreviousDate, @TrackHours, @TrackColour)
        END

        -- Reset all previous/tracking values
        SELECT  @PreviousEDISID = NULL,
                @PreviousProduct = NULL,
                @PreviousPump = NULL,
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
            INSERT INTO #AlertPeriods ([EDISID], [Pump], [Product], [Type], [Start], [End], [Hours], [Colour])
            VALUES (@PreviousEDISID, @PreviousPump, @PreviousProduct, @PreviousType, @TrackStart, @TrackEnd, @TrackHours, @TrackColour)
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
            @PreviousProduct = @CursorProduct,
            @PreviousPump = @CursorPump,
            @PreviousType = @CursorType,
            @PreviousDate = @CursorDate

    FETCH NEXT FROM Cursor_Sequence INTO @CursorEDISID, @CursorPump, @CursorProduct, @CursorType, @CursorDate, @CursorAdjacent, @CursorAmber, @CursorRed
END

-- Catch any trailing records
IF (@PreviousEDISID IS NOT NULL AND @TrackColour <> 0 AND @TrackHours >= @ConsistentPeriod)
BEGIN
    -- Save occurrance if it meets requirements (@TrackEnd will not have been set)
    INSERT INTO #AlertPeriods ([EDISID], [Pump], [Product], [Type], [Start], [End], [Hours], [Colour])
    VALUES (@PreviousEDISID, @PreviousPump, @PreviousProduct, @PreviousType, @TrackStart, @CursorDate, @TrackHours, @TrackColour)
END

CLOSE Cursor_Sequence
DEALLOCATE Cursor_Sequence

IF @DebugSequence = 1
BEGIN
    SELECT *
    FROM #AlertPeriods
END

CREATE TABLE #Exceptions ([EDISID] INT NOT NULL, [Pump] INT NOT NULL, [Product] VARCHAR(50) NOT NULL, [Type] VARCHAR(255) NOT NULL, [Status] INT NOT NULL)

INSERT INTO #Exceptions ([EDISID], [Pump], [Product], [Type], [Status])
/* Consistent Data (Amber+ for 6 Hours) */
SELECT DISTINCT
    [EDISID],
    [Pump],
    [Product],
    [Type],
    [Colour]
FROM #AlertPeriods -- Only contains records which have breached the Consistent Data rule
WHERE [Colour] = @RED
UNION
/* Occurrances (8x Red/Amber over 24 hours) */
SELECT DISTINCT
    [R].[EDISID],
    [R].[Pump],
    [R].Product,
    [R].[Type],
    @RED AS [Status] -- HACK: Temporarily Remove Amber
    --CASE
    --    WHEN SUM([Red]) > 0 -- Any Red at all means the outcome is Red 
    --    THEN 3 -- Red
    --    ELSE 2 -- Amber
    --    END AS [Status]
FROM #Readings AS [R]
GROUP BY 
    [R].[EDISID],
    [R].[Pump],
    [R].Product,
    [R].[Type]
HAVING
    SUM([Red]) >= @Occurrances -- HACK: Temporarily Remove Amber
    --SUM([Amber] + [Red]) >= @Occurrances -- Meets minimum requirement of Red+Amber

SELECT
    [Exceptions].[EDISID],
    --[Sites].[SiteID],               -- *Debug*
    --[Sites].[Name],                 -- *Debug*
    --@DebugFixedDate AS [Generated], -- *Debug*
    (CASE
		WHEN [Exceptions].[Status] = 3 THEN 'Red'
		WHEN [Exceptions].[Status] = 2 THEN 'Amber'
	END) + ' - ' + [EquipmentList] AS [Detail]
    ,[P].[ID] AS [ProductID],
    [Ex].[Pump]
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
                (   SELECT ';' + CAST([Pump] AS VARCHAR(10)) + ':' + [Product] + ':' + [Type] + '|' + (CASE WHEN [Status] = 3 THEN 'Red' WHEN [Status] = 2 THEN 'Amber' END) 
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
JOIN [dbo].[Products] AS [P] ON [Ex].[Product] = [P].[Description] -- Not the correct way to do this, a hopefully temporary hack to get the required results quickly
--ORDER BY [Exceptions].[EDISID]--, [P].[ID], [Ex].[Pump]    -- *Debug*

DROP TABLE #AlertPeriods
DROP TABLE #Exceptions
DROP TABLE #IFMCalls
DROP TABLE #Readings

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ExceptionIFMTemperatureIssue] TO PUBLIC
    AS [dbo];

