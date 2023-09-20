CREATE PROCEDURE [dbo].[ExceptionWaterLine]
(
	@EDISID INT = NULL,
	@Auditor VARCHAR(255) = NULL
)
AS

/* For Testing */
--DECLARE @Auditor VARCHAR(255) = NULL
--DECLARE @EDISID INT = NULL --30
--DECLARE @SiteID VARCHAR(15) = NULL --'T002'
--IF @SiteID IS NOT NULL
--    SELECT @EDISID = [EDISID] FROM [dbo].[Sites] WHERE [SiteID] = @SiteID

SET NOCOUNT ON;
SET DATEFIRST 1;

DECLARE @EnableLogging BIT = 1
DECLARE @DebugDates BIT = 0

--DECLARE @CurrentWeek	DATETIME = GETDATE()
--SET @CurrentWeek = DATEADD(dd, 1-DATEPART(dw, @CurrentWeek), @CurrentWeek)

DECLARE @CurrentWeekFrom		DATETIME
DECLARE @To						DATETIME
DECLARE @Today					DATETIME
DECLARE @StartDateOfInterest	DATETIME

DECLARE @AuditWeeksBack INT = 1
SELECT @AuditWeeksBack = ISNULL(CAST([PropertyValue] AS INTEGER), 1) FROM [dbo].[Configuration] WHERE [PropertyName] = 'AuditWeeksBehind'

--Get Audit Day for customer, the day in which the audit period will be classed as an extra week forward
DECLARE @AuditDay INT
SELECT @AuditDay = ISNULL(CAST([PropertyValue] AS INTEGER), NULL) FROM [dbo].[Configuration] WHERE [PropertyName] = 'AuditDay'

IF @AuditDay IS NOT NULL
BEGIN
	--Get Current Day
	DECLARE @CurrentDay INT
	SET @CurrentDay = DATEPART(dw,GETDATE())

	IF @CurrentDay >= @AuditDay
		BEGIN
			SET @CurrentWeekFrom = DATEADD(WEEK, -(@AuditWeeksBack-2), DATEADD(WEEK, DATEDIFF(WEEK, 6, GETDATE()), 0)) --take back 1 and a half weeks
		END
	ELSE
		BEGIN 
			SET @CurrentWeekFrom = DATEADD(WEEK, -(@AuditWeeksBack-1), DATEADD(WEEK, DATEDIFF(WEEK, 6, GETDATE()), 0)) -- take back 2 weeks
		END
END

IF @AuditDay IS NULL
	BEGIN 
		SET @CurrentWeekFrom = DATEADD(WEEK, -(@AuditWeeksBack-1), DATEADD(WEEK, DATEDIFF(WEEK, 6, GETDATE()), 0))
	END

/* Debugging */
--SET @EnableLogging = 0
--SET @DebugDates = 1
--SET @CurrentWeekFrom = DATEADD(WEEK, -1, @CurrentWeekFrom)

SET @To = CAST(DATEADD(day, 6, @CurrentWeekFrom) AS Date)
SET @StartDateOfInterest = DATEADD(week, -3, @CurrentWeekFrom)

/* Debugging */
IF @DebugDates = 1
BEGIN
    SELECT @StartDateOfInterest, @To
END

IF @EnableLogging = 1
BEGIN
    DECLARE @DatabaseID INT
    SELECT @DatabaseID = [ID] FROM [SQL1\SQL1].[ServiceLogger].[dbo].[EDISDatabases] WHERE [Name] = DB_NAME()
    DECLARE @NotificationTypeID INT
    SELECT @NotificationTypeID = [NotificationTypeID] FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationType] WHERE [StoredProcedure] = OBJECT_NAME(@@PROCID)
    IF @NotificationTypeID IS NOT NULL
    BEGIN
        EXEC [SQL1\SQL1].[Auditing].[dbo].[AddNotificationTypeGenerationLog] @NotificationTypeID, @DatabaseID, @EDISID, @StartDateOfInterest, @To
    END
END
ELSE 
BEGIN
    PRINT 'Logging Disabled'
END

CREATE TABLE #Sites([EDISID] INT NOT NULL, [Hidden] BIT NOT NULL)

INSERT INTO #Sites
([EDISID], [Hidden])
SELECT 
    [EDISID], [Hidden]
FROM [dbo].[Sites]
WHERE 
    [Hidden] = 0
AND (@EDISID IS NULL OR [EDISID] = @EDISID)
AND (@Auditor IS NULL OR LOWER([SiteUser]) = LOWER(@Auditor))
AND [SiteOnline] <= @To
AND [LastDownload] >= @To
AND [Status] IN (1,3,10)

DECLARE @NotRecordingDispense INT = 22

SELECT DISTINCT -- Sites with Water Lines but no dispense on those lines
    [WL].[EDISID]
FROM
    (   SELECT -- Site has Water based products on the *current* font setup
            [S].[EDISID]
        FROM #Sites AS [S]
        JOIN [dbo].[PumpSetup] AS [PS] 
            ON [S].[EDISID] = [PS].[EDISID] AND [PS].[ValidTo] IS NULL
        JOIN [dbo].[Products] AS [P] 
            ON [PS].[ProductID] = [P].[ID] 
        WHERE [P].[IsWater] = 1
        GROUP BY [S].[EDISID]
	    EXCEPT -- Exclude...
        SELECT -- ...water line showing (any) volume within last 4 weeks
            [S].[EDISID]
        FROM #Sites AS [S]
        JOIN [dbo].[MasterDates] AS [MD] 
            ON [S].[EDISID] = [MD].[EDISID]
        JOIN [dbo].[PumpSetup] AS [PS]
            ON [S].[EDISID] = [PS].[EDISID]
            AND (
                ([MD].[Date] >= [PS].[ValidFrom] AND [PS].[ValidTo] IS NULL) -- Current
                OR
                ([MD].[Date] >= [PS].[ValidFrom] AND [MD].[Date] < [PS].[ValidTo]) -- Historical
                )
        JOIN [dbo].[Products] AS [P] 
            ON [PS].[ProductID] = [P].[ID]
        LEFT JOIN [dbo].[WaterStack] AS [WS] 
            ON [MD].[ID] = [WS].[WaterID]
            AND [PS].[Pump] = [WS].[Line]
        LEFT JOIN [dbo].[CleaningStack] AS [CS] 
            ON [MD].[ID] = [CS].[CleaningID]
            AND [PS].[Pump] = [CS].[Line]
        LEFT JOIN [dbo].[DLData] AS [DS] 
            ON [MD].[ID] = [DS].[DownloadID]
            AND [DS].[Product] = [PS].[Pump]
        WHERE 
            [P].[IsWater] = 1
        AND ([MD].[Date] BETWEEN @StartDateOfInterest AND @To)
        AND (
                [WS].[WaterID] IS NOT NULL
                OR
                [CS].[CleaningID] IS NOT NULL
                OR
                [DS].[DownloadID] IS NOT NULL
            )
        GROUP BY 
            [S].[EDISID]
    ) AS [WL]
EXCEPT -- Exclude...
SELECT -- ...when service call raised for water line
    [JobWatchCalls].[EdisID]
FROM [dbo].[JobWatchCalls]
JOIN [dbo].[JobWatchCallsData] ON [JobWatchCalls].[JobId] = [JobWatchCallsData].[JobId]
JOIN [dbo].[PumpSetup] ON [JobWatchCallsData].[Pump] = [PumpSetup].[Pump]
JOIN [dbo].[Products] ON [PumpSetup].[ProductID] = [Products].[ID] AND [Products].[IsWater] = 1
WHERE 
    [JobWatchCalls].[JobActive] = 1
AND [JobWatchCallsData].[CallReasonTypeID] IN (@NotRecordingDispense)
AND [PumpSetup].[ValidTo] IS NULL
GROUP BY
    [JobWatchCalls].[EdisID]
/*
SELECT -- ...when service call raised for water line
    [S].[EDISID]
FROM [dbo].[PumpSetup] AS [PS]
JOIN #Sites AS [S] ON [PS].[EDISID] = [S].[EDISID]
JOIN [dbo].[Products] AS [P] ON [PS].[ProductID] = [P].[ID] AND [P].[IsWater] = 1
JOIN [dbo].[Calls] AS [C] ON [S].[EDISID] = [C].[EDISID]
JOIN [dbo].[CallReasons] AS [CR] ON [C].[ID] = [CR].[CallID] AND [CR].[ReasonTypeID] = 22
LEFT JOIN [dbo].[CallStatusHistory] AS [CSH] ON [C].[ID] = [CSH].[CallID] AND [CSH].[StatusID] = 4
WHERE
    [PS].[ValidTo] IS NULL
AND [CR].[AdditionalInfo] LIKE CAST([PS].[Pump] AS VARCHAR(50)) + ':%'
AND [CSH].[CallID] IS NULL
GROUP BY 
    [S].[EDISID]
*/

DROP TABLE #Sites

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ExceptionWaterLine] TO PUBLIC
    AS [dbo];

