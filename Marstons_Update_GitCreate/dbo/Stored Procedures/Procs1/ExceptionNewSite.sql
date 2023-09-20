CREATE PROCEDURE [dbo].[ExceptionNewSite]
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

DECLARE @DatabaseID INT
SELECT @DatabaseID = [ID] FROM [SQL1\SQL1].[ServiceLogger].[dbo].[EDISDatabases] WHERE [Name] = DB_NAME()
DECLARE @NotificationTypeID INT
SELECT @NotificationTypeID = [NotificationTypeID] FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationType] WHERE [StoredProcedure] = OBJECT_NAME(@@PROCID)
IF @NotificationTypeID IS NOT NULL
BEGIN
    DECLARE @xFrom DATETIME = DATEADD(week, -4, @CurrentWeekFrom)
    EXEC [SQL1\SQL1].[Auditing].[dbo].[AddNotificationTypeGenerationLog] @NotificationTypeID, @DatabaseID, @EDISID, @xFrom, @To
END

CREATE TABLE #Sites(EDISID INT, Hidden BIT, BirthDate DATETIME)

INSERT INTO #Sites
(EDISID, Hidden, BirthDate)
SELECT Sites.EDISID, Hidden, BirthDate
FROM Sites
WHERE Hidden = 0
AND (@EDISID IS NULL OR Sites.EDISID = @EDISID)
AND(@Auditor IS NULL OR LOWER(SiteUser) = LOWER(@Auditor))
AND SiteOnline <= @To
AND [Status] IN (1,10,3)

SELECT	EDISID
FROM	#Sites
WHERE	BirthDate >= DATEADD(week, -4, @CurrentWeekFrom)

DROP TABLE #Sites
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ExceptionNewSite] TO PUBLIC
    AS [dbo];

