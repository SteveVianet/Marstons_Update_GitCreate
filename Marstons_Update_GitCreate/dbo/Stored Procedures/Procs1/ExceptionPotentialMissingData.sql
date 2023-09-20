CREATE PROCEDURE [dbo].[ExceptionPotentialMissingData]
(
	@EDISID int = NULL,
	@Auditor varchar(255) = NULL
)
AS

SET DATEFIRST 1;

DECLARE @CurrentWeek	DATETIME = GETDATE()
SET @CurrentWeek = DATEADD(dd, 1-DATEPART(dw, @CurrentWeek), @CurrentWeek)

DECLARE @CurrentWeekFrom		DATETIME
DECLARE @To						DATETIME
DECLARE @Today					DATETIME


SET @CurrentWeekFrom = @CurrentWeek
SET @To = DATEADD(day, 6, @CurrentWeekFrom)
DECLARE @WeekFromTwelveWeeks datetime = DATEADD(week, -12, @CurrentWeekFrom)
DECLARE @MonthCount int = DATEDIFF(MONTH, CAST(CAST(YEAR(@WeekFromTwelveWeeks) AS VARCHAR(4)) + '/' + CAST(MONTH(@WeekFromTwelveWeeks) AS VARCHAR(2)) + '/01' AS DATETIME), CAST(CAST(YEAR(@To) AS VARCHAR(4)) + '/' + CAST(MONTH(@To) AS VARCHAR(2)) + '/01' AS DATETIME)) + 1

DECLARE @DatabaseID INT
SELECT @DatabaseID = [ID] FROM [SQL1\SQL1].[ServiceLogger].[dbo].[EDISDatabases] WHERE [Name] = DB_NAME()
DECLARE @NotificationTypeID INT
SELECT @NotificationTypeID = [NotificationTypeID] FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationType] WHERE [StoredProcedure] = 'ExceptionPotentialMissingData' -- Do we have permission to access this?
IF @NotificationTypeID IS NOT NULL
BEGIN
    EXEC [SQL1\SQL1].[Auditing].[dbo].[AddNotificationTypeGenerationLog] @NotificationTypeID, @DatabaseID, @EDISID, @WeekFromTwelveWeeks, @To
END

CREATE TABLE #Sites(EDISID INT, Hidden BIT, LastDownload datetime, SystemTypeID int)

INSERT INTO #Sites
(EDISID, Hidden, LastDownload, SystemTypeID)
SELECT Sites.EDISID, Hidden, LastDownload, SystemTypeID
FROM Sites
WHERE Hidden = 0
AND (@EDISID IS NULL OR Sites.EDISID = @EDISID)
AND(@Auditor IS NULL OR LOWER(SiteUser) = LOWER(@Auditor))
AND SiteOnline <= @To
AND Quality = 0

SELECT MasterDates.EDISID
FROM FaultStack  WITH (NOLOCK)
JOIN MasterDates ON FaultStack.FaultID = MasterDates.ID AND MasterDates.[Date] BETWEEN @WeekFromTwelveWeeks AND @To
JOIN #Sites AS Sites ON Sites.EDISID = MasterDates.EDISID
WHERE FaultStack.[Description] LIKE 'Warning: Possibility of gap%'
AND Sites.SystemTypeID = 2
AND Sites.Hidden = 0
GROUP BY MasterDates.EDISID

DROP TABLE #Sites

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ExceptionPotentialMissingData] TO PUBLIC
    AS [dbo];

