CREATE PROCEDURE [dbo].[ExceptionEquipmentFailed]
(
	@EDISID INT = NULL,
	@Auditor VARCHAR(255) = NULL
)
AS

/* For Testing */ 
--DECLARE @EDISID INT = NULL
--DECLARE @Auditor VARCHAR(255)

DECLARE @EnableLogging BIT = 1
DECLARE @DebugDayShift INT = 0
DECLARE @DebugService BIT = 0

/* For testing */
--SET @EnableLogging = 0
--SET @DebugDayShift = -6
--SET @DebugService = 1

SET NOCOUNT ON;
SET DATEFIRST 1;

DECLARE @To DATETIME = GETDATE() -- Only needed to enable The debug ability to shift the 24 hour period
DECLARE @From DATETIME = DATEADD(DAY, -1, @To)

IF @DebugDayShift <> 0
BEGIN
    SET @To = DATEADD(DAY, @DebugDayShift, @To)
    SET @From = DATEADD(DAY, @DebugDayShift, @From)
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

-- Get Latest Dispense date for each Site

-- Get Service Calls involving Equipment
DECLARE @FaultAmbient INT = 38
DECLARE @FaultRecirc INT = 40

DECLARE @EquipmentStart CHAR = ':'
DECLARE @EquipmentEnd CHAR = '('

/*
-- LEGACY LOGGER
DECLARE @ServiceRequestForEquipment TABLE ([EDISID] INT NOT NULL, [Address] INT, [Equipment] VARCHAR (50) NOT NULL)
INSERT INTO @ServiceRequestForEquipment ([EDISID], [Address], [Equipment])
SELECT 
    --[C].[ID] AS [CallID],
    [C].[EDISID],
    --[CR].[AdditionalInfo],
    CAST(CASE 
        WHEN
            (CHARINDEX(@EquipmentStart, [CR].[AdditionalInfo], 0) - 1 - 0) > 0 -- Must have found an end point
        THEN
            LEFT([CR].[AdditionalInfo], (CHARINDEX(@EquipmentStart, [CR].[AdditionalInfo], 0)-1))
        ELSE
            NULL
    END AS INT) AS [Address],
    CASE 
        WHEN
            (CHARINDEX(@EquipmentStart, [CR].[AdditionalInfo], 0) + 1) <> 1 -- After the Start of the string
             AND
            (CHARINDEX(@EquipmentEnd, [CR].[AdditionalInfo], 0) - 1 - CHARINDEX(@EquipmentStart, [CR].[AdditionalInfo], 0)) > 1 -- Must have found an end point
        THEN
            RTRIM(LTRIM(SUBSTRING(
                [CR].[AdditionalInfo], 
                (CHARINDEX(@EquipmentStart, [CR].[AdditionalInfo], 0) + 1), 
                (CHARINDEX(@EquipmentEnd, [CR].[AdditionalInfo], 0) - 1 - CHARINDEX(@EquipmentStart, [CR].[AdditionalInfo], 0))
            ))) 
        ELSE
            NULL
    END AS [Equipment]
FROM [dbo].[Calls] AS [C]
JOIN [dbo].[Sites] AS [S] ON [C].[EDISID] = [S].[EDISID]
JOIN [dbo].[CallReasons] AS [CR]
    ON [C].[ID] = [CR].[CallID]
WHERE [ClosedOn] IS NULL -- Only Open/Outstanding Calls
AND [AbortReasonID] = 0 -- Not Aborted
AND [CR].[ReasonTypeID] IN (@FaultAmbient, @FaultRecirc)
AND (CHARINDEX(@EquipmentStart, [CR].[AdditionalInfo], 0) + 1) <> 1
AND (CHARINDEX(@EquipmentEnd, [CR].[AdditionalInfo], 0) - 1 - CHARINDEX(@EquipmentStart, [CR].[AdditionalInfo], 0)) > 1
*/

/* Get relevant descriptions */
-- Combine all the active job descriptions
-- JOB WATCH
DECLARE @ServiceRequestForEquipment TABLE ([EDISID] INT NOT NULL, [Address] INT, [Equipment] VARCHAR (50) NOT NULL)
INSERT INTO @ServiceRequestForEquipment ([EDISID], [Address], [Equipment])
SELECT
    [EquipmentItems].[EDISID],
    [EquipmentItems].[InputID],
    [EquipmentItems].[Description]
FROM [dbo].[JobWatchCalls]
JOIN [dbo].[JobWatchCallsData] ON [JobWatchCalls].[JobId] = [JobWatchCallsData].[JobId]
JOIN [dbo].[EquipmentItems] ON [JobWatchCalls].[EdisID] = [EquipmentItems].[EDISID] AND [JobWatchCallsData].[EquipmentAddress] = [EquipmentItems].[InputID]
WHERE [JobWatchCalls].[JobActive] = 1
AND [JobWatchCallsData].[CallReasonTypeID] IN (@FaultAmbient, @FaultRecirc)

IF @DebugService = 1
BEGIN
    SELECT * 
    FROM @ServiceRequestForEquipment 
END

CREATE TABLE #Exceptions ([EDISID] INT NOT NULL, [InputID] INT NOT NULL, [EquipmentDescription] VARCHAR(512) NOT NULL)

INSERT INTO #Exceptions ([EDISID], [InputID], [EquipmentDescription])
SELECT 
    [S].[EDISID],
    [EI].[InputID],
    [ET].[Description] + 
    CASE WHEN [EI].[Description] IS NULL OR [EI].[Description] = ''
         THEN ''
         ELSE ' (' + [EI].[Description] + ')'
         END AS [EquipmentDescription]
--    COUNT([ER].[Value]) AS [Readings]
FROM [dbo].[EquipmentItems] AS [EI]
JOIN [dbo].[EquipmentTypes] AS [ET] ON [EI].[EquipmentTypeID] = [ET].[ID]
JOIN [dbo].[Sites] AS [S] ON [EI].[EDISID] = [S].[EDISID]
JOIN (
    SELECT 
        [EDISID],
        MAX([StartTime]) AS [MaxDispense]
    FROM [dbo].[DispenseActions]
    WHERE [StartTime] >= @From
    AND (@EDISID IS NULL OR [EDISID] = @EDISID)
    GROUP BY [EDISID]
) AS [DA] ON [S].[EDISID] = [DA].[EDISID]
LEFT JOIN [dbo].[EquipmentReadings] AS [ER] ON [EI].[InputID] = [ER].[InputID] AND [EI].[EDISID] = [ER].[EDISID] AND [ER].[LogDate] BETWEEN @From AND @To
LEFT JOIN @ServiceRequestForEquipment AS [SR] ON [S].[EDISID] = [SR].[EDISID]
WHERE
    [S].[LastDownload] >= @From
AND (@EDISID IS NULL OR [S].[EDISID] = @EDISID)
AND (@Auditor IS NULL OR LOWER([S].[SiteUser]) = LOWER(@Auditor))
AND [EI].[InUse] = 1
AND [SR].[EDISID] IS NULL -- Exclude
GROUP BY
    [S].[EDISID],
    [EI].[InputID],
    [ET].[Description] + 
    CASE WHEN [EI].[Description] IS NULL OR [EI].[Description] = ''
         THEN ''
         ELSE ' (' + [EI].[Description] + ')'
         END
HAVING COUNT([ER].[Value]) = 0

SELECT 
    [Exceptions].[EDISID],
    [EquipmentList] AS [Detail]
FROM (
    SELECT DISTINCT
        [EDISID],
        SUBSTRING(
            (   SELECT 
                    --';' + CAST([InputID] AS VARCHAR(10)) + '|' + [Type]
                    ';' + CAST([InputID] AS VARCHAR(10)) + '|' + [EquipmentDescription]
                FROM #Exceptions
                WHERE [EDISID] = [E].[EDISID] 
                FOR XML PATH (''), TYPE).value('.','VARCHAR(4000)')
            ,2, 4000) AS [EquipmentList]
        FROM #Exceptions AS [E]
    GROUP BY 
        [E].[EDISID]
    ) AS [Exceptions]

DROP TABLE #Exceptions

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ExceptionEquipmentFailed] TO PUBLIC
    AS [dbo];

