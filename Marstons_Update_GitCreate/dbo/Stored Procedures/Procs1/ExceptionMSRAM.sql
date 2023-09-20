CREATE PROCEDURE [dbo].[ExceptionMSRAM]
(
	@EDISID int = NULL,
	@Auditor varchar(255) = NULL
)
AS
--DECLARE @EDISID INT = NULL

SET DATEFIRST 1;

DECLARE @CurrentWeek	DATETIME = GETDATE()
SET @CurrentWeek = DATEADD(dd, 1-DATEPART(dw, @CurrentWeek), @CurrentWeek)

DECLARE @CurrentWeekFrom		DATETIME
DECLARE @To						DATETIME
DECLARE @Today					DATETIME


SET @CurrentWeekFrom = CAST(DATEADD(week, -1, @CurrentWeek) AS DATE)
SET @To = DATEADD(day, 6, @CurrentWeekFrom)
DECLARE @ThreeMonthsAgo datetime = DATEADD(week, -11, @CurrentWeekFrom)

DECLARE @StartDate datetime = CAST(CAST(YEAR(@ThreeMonthsAgo) AS VARCHAR(4)) + '/' + CAST(MONTH(@ThreeMonthsAgo) AS VARCHAR(2)) + '/01' AS DATETIME)
DECLARE @EndDate datetime = CAST(CAST(YEAR(@To) AS VARCHAR(4)) + '/' + CAST(MONTH(@To) AS VARCHAR(2)) + '/01' AS DATETIME)
DECLARE @MonthCount int = DATEDIFF(MONTH, @StartDate, @EndDate) + 1

DECLARE @DatabaseID INT
SELECT @DatabaseID = [ID] FROM [SQL1\SQL1].[ServiceLogger].[dbo].[EDISDatabases] WHERE [Name] = DB_NAME()
DECLARE @NotificationTypeID INT
SELECT @NotificationTypeID = [NotificationTypeID] FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationType] WHERE [StoredProcedure] = 'ExceptionMSRAM' -- Do we have permission to access this?
IF @NotificationTypeID IS NOT NULL
BEGIN
    EXEC [SQL1\SQL1].[Auditing].[dbo].[AddNotificationTypeGenerationLog] @NotificationTypeID, @DatabaseID, @EDISID, @StartDate, @EndDate
END

CREATE TABLE #Sites(EDISID INT, Hidden BIT, LastDownload datetime, SystemTypeID int)

INSERT INTO #Sites
(EDISID, Hidden, LastDownload, SystemTypeID)
SELECT Sites.EDISID, Hidden, LastDownload, SystemTypeID
FROM Sites
WHERE Hidden = 0
AND (@EDISID IS NULL OR Sites.EDISID = @EDISID)
AND (@Auditor IS NULL OR LOWER(SiteUser) = LOWER(@Auditor))
AND SiteOnline <= @To
AND [Status] IN (1,3,10)

SELECT Sites.EDISID
FROM FaultStack  WITH (NOLOCK)
JOIN MasterDates ON FaultStack.FaultID = MasterDates.ID AND MasterDates.[Date] >= @StartDate AND MasterDates.[Date] <= @EndDate
JOIN #Sites AS Sites ON Sites.EDISID = MasterDates.EDISID
WHERE (FaultStack.[Description] LIKE 'Shadow RAM Copied%' OR FaultStack.[Description] LIKE 'Data copied to shadow RAM%')
AND Sites.SystemTypeID = 1
GROUP BY Sites.EDISID, Sites.LastDownload
HAVING COUNT(*) < (@MonthCount)

DROP TABLE #Sites
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ExceptionMSRAM] TO PUBLIC
    AS [dbo];

