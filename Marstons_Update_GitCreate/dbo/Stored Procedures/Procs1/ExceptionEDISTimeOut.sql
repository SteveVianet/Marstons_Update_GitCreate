CREATE PROCEDURE [dbo].[ExceptionEDISTimeOut]
(
	@EDISID INT = NULL,
	@Auditor VARCHAR(255) = NULL
)
AS

--/* For Testing */
--DECLARE @Auditor VARCHAR(255) = NULL
--DECLARE @EDISID INT = NULL --30
--DECLARE @SiteID VARCHAR (15) = '030301'
--IF @SiteID IS NOT NULL
--    SELECT @EDISID = [EDISID] FROM [dbo].[Sites] WHERE [SiteID] = @SiteID

SET NOCOUNT ON;
SET DATEFIRST 1;

DECLARE @EnableLogging BIT = 1
DECLARE @DebugDates BIT = 0
DECLARE @DebugSites BIT = 0
DECLARE @DebugComments BIT = 0

DECLARE @CurrentWeek	DATETIME = GETDATE()
SET @CurrentWeek = DATEADD(dd, 1-DATEPART(dw, @CurrentWeek), @CurrentWeek)

DECLARE @CurrentWeekFrom		DATETIME
DECLARE @To						DATETIME
DECLARE @Today					DATETIME

DECLARE @TimeoutMinutes INT = 15

SET @CurrentWeekFrom = @CurrentWeek
SET @To = DATEADD(day, 6, @CurrentWeekFrom)

/* Debugging */
--SET @EnableLogging = 0
--SET @DebugDates = 1
--SET @DebugSites = 1
--SET @DebugComments = 1

IF @DebugDates = 1
BEGIN
    SELECT @CurrentWeekFrom AS [CurrentWeekFrom], @To AS [To]
END

IF @EnableLogging = 1
BEGIN
    DECLARE @DatabaseID INT
    SELECT @DatabaseID = [ID] FROM [SQL1\SQL1].[ServiceLogger].[dbo].[EDISDatabases] WHERE [Name] = DB_NAME()
    DECLARE @NotificationTypeID INT
    SELECT @NotificationTypeID = [NotificationTypeID] FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationType] WHERE [StoredProcedure] = 'ExceptionEDISTimeOut' -- Do we have permission to access this?
    IF @NotificationTypeID IS NOT NULL
    BEGIN
        EXEC [SQL1\SQL1].[Auditing].[dbo].[AddNotificationTypeGenerationLog] @NotificationTypeID, @DatabaseID, @EDISID, @CurrentWeekFrom, @To
    END
END
ELSE
BEGIN
    PRINT 'Logging Disabled'
END

CREATE TABLE #Sites(EDISID INT NOT NULL, [Hidden] BIT NOT NULL, SystemTypeID int, [LastDownload] DATE)

INSERT INTO #Sites (EDISID, [Hidden], SystemTypeID, [LastDownload])
SELECT EDISID, [Hidden], SystemTypeID, [LastDownload]
FROM Sites
WHERE [Status] IN (1,3,10)
AND (@EDISID IS NULL OR Sites.EDISID = @EDISID)
AND SiteOnline <= @To
AND (@Auditor IS NULL OR LOWER(SiteUser) = LOWER(@Auditor)) -- may only work for customers using per-site assignments (default is per-customer)
AND LastDownload >= DATEADD(day, -1, @CurrentWeekFrom) -- only sites which have downloaded up to last Sunday
    
IF @DebugSites = 1
BEGIN
    SELECT * 
    FROM #Sites
    ORDER BY [EDISID]
END

IF @DebugComments = 1
BEGIN
    SELECT
        s.[EDISID],
        [Text],
        [Date]
    FROM [dbo].[SiteComments]
    INNER JOIN #Sites s ON [SiteComments].EDISID = s.EDISID
    WHERE 
        [HeadingType] = 2004
    AND [Text] LIKE 'Date and time set %'
    AND CAST([Date] AS DATE) >= CAST([LastDownload] AS DATE)

    SELECT	CAST(REPLACE(REPLACE(ReportText, 'EDIS time is out by ', ''), ' minutes', '') AS float) AS MinutesOut, dr.EDISID, *
    FROM	DownloadReports dr
    INNER JOIN #Sites s ON dr.EDISID = s.EDISID
    LEFT JOIN (
        SELECT
            [SC].[EDISID],
            [SC].[Date]
        FROM [dbo].[SiteComments] AS [SC]
        JOIN #Sites AS [S] ON [SC].[EDISID] = [S].[EDISID]
        WHERE 
            [HeadingType] = 2004
        AND [Text] LIKE 'Date and time set %'
        AND CAST([Date] AS DATE) >= CAST([LastDownload] AS DATE)
        ) AS [TimeSet] ON [s].[EDISID] = [TimeSet].[EDISID] AND [dr].[DownloadedOn] <= [TimeSet].[Date]
    WHERE ReportText LIKE 'EDIS time is out by %'
    --AND DownloadedOn >= DATEADD(day, -1, @CurrentWeekFrom)
    AND LastDownload >= DATEADD(day, -1, @CurrentWeekFrom)
    AND	s.SystemTypeID = 2 --EDISBOX
    AND [TimeSet].[Date] IS NULL -- Time has not been set since the issue was logged
END

DECLARE @Timeout TABLE 
(
	EDISID int,
	MinutesOut float
)

INSERT INTO @Timeout (MinutesOut, EDISID)
SELECT	DISTINCT CAST(REPLACE(REPLACE(ReportText, 'EDIS time is out by ', ''), ' minutes', '') AS float) AS MinutesOut, dr.EDISID
FROM	DownloadReports dr
INNER JOIN #Sites s ON dr.EDISID = s.EDISID
LEFT JOIN (
    SELECT
        [SC].[EDISID],
        [SC].[Date]
    FROM [dbo].[SiteComments] AS [SC]
        JOIN #Sites AS [S] ON [SC].[EDISID] = [S].[EDISID]
    WHERE 
        [HeadingType] = 2004
    AND [Text] LIKE 'Date and time set %'
    AND CAST([Date] AS DATE) >= CAST([LastDownload] AS DATE)
    ) AS [TimeSet] ON [s].[EDISID] = [TimeSet].[EDISID] AND [dr].[DownloadedOn] <= [TimeSet].[Date]
WHERE ReportText LIKE 'EDIS time is out by %'
AND DownloadedOn >= DATEADD(day, -1, @CurrentWeekFrom)
AND	s.SystemTypeID = 2 --EDISBOX
AND [TimeSet].[Date] IS NULL -- Time has not been set since the issue was logged

SELECT DISTINCT EDISID FROM @Timeout
WHERE MinutesOut > @TimeoutMinutes

DROP TABLE #Sites
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ExceptionEDISTimeOut] TO PUBLIC
    AS [dbo];

