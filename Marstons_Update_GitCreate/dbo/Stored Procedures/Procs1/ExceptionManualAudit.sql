CREATE PROCEDURE [dbo].[ExceptionManualAudit]
(
	@EDISID int = NULL,
	@Auditor varchar(255) = NULL
)
AS

--DECLARE	@EDISID     INT = NULL
--DECLARE	@Auditor    VARCHAR(255) = NULL

SET DATEFIRST 1;

DECLARE @EnableLogging BIT = 1
DECLARE @DebugDates BIT = 0
DECLARE @DebugSites BIT = 0
DECLARE @DebugSitesComplete BIT = 0

/* For Testing */
--SET @EnableLogging = 0
--SET @DebugDates = 1
--SET @DebugSites = 1
--SET @DebugSitesComplete = 1

-- Configuration
DECLARE @ManualAudit_WeeksBehind INT

SELECT  @ManualAudit_WeeksBehind = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'ManualAudit-WeeksBehind'

DECLARE @To DATETIME = DATEADD(DAY, -1, GETDATE())
-- DEBUG
--SET @To = '2017-06-12 09:00'
--SET @To = '2017-06-19 09:00'
--SET @To = '2017-06-23 09:00'
--SET @To = '2017-06-29 09:00'
--SET @To = '2017-06-26 09:15:37'
--SET @To = '2017-07-10 10:00'
DECLARE @From DATE = DATEADD(WEEK, -@ManualAudit_WeeksBehind, DATEADD(WEEK, DATEDIFF(WEEK, 0, @To), 0))

--Debug
IF @DebugDates = 1
BEGIN
    SELECT @From [From], @To [To]
END
--SELECT @From [From], @To [To]
--SET @To = DATEADD(WEEK, DATEDIFF(WEEK, 0, @To), 0)

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

IF OBJECT_ID('tempdb..#Sites') IS NOT NULL
    DROP TABLE #Sites

CREATE TABLE #Sites(EDISID INT)

INSERT INTO #Sites (EDISID)
SELECT Sites.EDISID
FROM Sites
WHERE 
    (@EDISID IS NULL OR Sites.EDISID = @EDISID)
AND (@Auditor IS NULL OR LOWER(SiteUser) = LOWER(@Auditor))
AND SiteOnline <= @To
AND	[Status] IN (1,3,10)

IF @DebugSites = 1
BEGIN
    SELECT 
        Sites.EDISID, 
        S.SiteID, 
        S.[Name], 
        OutdatedAudits.LatestAudit AS OutdatedAudit, -- Audit's too old
        HistoricalAudits.LatestAudit, -- Latest Audit (ever)
        FutureAudits.LatestAudit AS FutureAudit, -- Audit's too new (in the future, dates altered via debugging?)
        ValidAudits.LatestAudit AS ValidAudit, -- Audit is within the expected period
        COUNT(SiteAudits.EDISID) AS AcceptableAuditCount
    FROM #Sites AS Sites
    JOIN Sites AS S ON Sites.EDISID = S.EDISID
    LEFT JOIN SiteAudits 
      ON SiteAudits.EDISID = Sites.EDISID 
     AND SiteAudits.[TimeStamp] BETWEEN @From AND @To
    LEFT JOIN (
        SELECT EDISID, MAX([TimeStamp]) AS LatestAudit
        FROM SiteAudits 
        WHERE SiteAudits.[TimeStamp] <= @To
        GROUP BY EDISID
    ) AS HistoricalAudits 
      ON Sites.EDISID = HistoricalAudits.EDISID
    LEFT JOIN (
        SELECT EDISID, MAX([TimeStamp]) AS LatestAudit
        FROM SiteAudits 
        WHERE SiteAudits.[TimeStamp] < @From
        GROUP BY EDISID
    ) AS OutdatedAudits 
      ON Sites.EDISID = OutdatedAudits.EDISID
    LEFT JOIN (
        SELECT EDISID, MAX([TimeStamp]) AS LatestAudit
        FROM SiteAudits 
        WHERE SiteAudits.[TimeStamp] > @To
        GROUP BY EDISID
    ) AS FutureAudits 
      ON Sites.EDISID = FutureAudits.EDISID
    LEFT JOIN (
        SELECT EDISID, MAX([TimeStamp]) AS LatestAudit
        FROM SiteAudits 
        WHERE SiteAudits.[TimeStamp] BETWEEN @From AND @To
        GROUP BY EDISID
    ) AS ValidAudits 
      ON Sites.EDISID = ValidAudits.EDISID
    GROUP BY 
        Sites.EDISID, 
        S.SiteID, 
        S.[Name], 
        OutdatedAudits.LatestAudit,
        HistoricalAudits.LatestAudit,
        FutureAudits .LatestAudit,
        ValidAudits.LatestAudit
    HAVING (@DebugSitesComplete = 1 OR COUNT(SiteAudits.EDISID) = 0)
    ORDER BY S.SiteID
END

SELECT
    Sites.EDISID--,
    --S.SiteID,
    --S.[Name]
FROM #Sites AS Sites
JOIN Sites AS S ON Sites.EDISID = S.EDISID
LEFT JOIN SiteAudits 
    ON SiteAudits.EDISID = Sites.EDISID 
    AND SiteAudits.[TimeStamp] BETWEEN @From AND @To
GROUP BY 
    Sites.EDISID--,
--    S.SiteID,
--    S.[Name]
HAVING COUNT(SiteAudits.EDISID) = 0
--ORDER BY 
--    S.SiteID

DROP TABLE #Sites

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ExceptionManualAudit] TO PUBLIC
    AS [dbo];

