CREATE PROCEDURE [dbo].[ExceptionTamperRule]
(
	@EDISID int = NULL,
	@Auditor varchar(255) = NULL
)
AS

--FOR TESTING ONLY
--DECLARE @EDISID INT = NULL

SET DATEFIRST 1;

DECLARE @CurrentWeek DATE = GETDATE()
SET @CurrentWeek = DATEADD(dd, 1-DATEPART(dw, @CurrentWeek), @CurrentWeek)

DECLARE @To	DATE

SET @To =DATEADD(day, -1, @CurrentWeek)

DECLARE @DatabaseID INT
SELECT @DatabaseID = [ID] FROM [SQL1\SQL1].[ServiceLogger].[dbo].[EDISDatabases] WHERE [Name] = DB_NAME()
DECLARE @NotificationTypeID INT
SELECT @NotificationTypeID = [NotificationTypeID] FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationType] WHERE [StoredProcedure] = 'ExceptionTamperRule' -- Do we have permission to access this?
IF @NotificationTypeID IS NOT NULL
BEGIN
    EXEC [SQL1\SQL1].[Auditing].[dbo].[AddNotificationTypeGenerationLog] @NotificationTypeID, @DatabaseID, @EDISID, @CurrentWeek, @To
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
AND [Status] IN (1,10,3)

SELECT DISTINCT TamperCases.EDISID
FROM TamperCaseEvents
JOIN TamperCases ON TamperCases.CaseID = TamperCaseEvents.CaseID
JOIN (
	SELECT EDISID, MAX(EventDate) AS MaxCaseDate
	FROM TamperCases
	JOIN TamperCaseEvents ON TamperCaseEvents.CaseID = TamperCases.CaseID
	GROUP BY EDISID
) AS CurrentCases ON CurrentCases.EDISID = TamperCases.EDISID AND CurrentCases.MaxCaseDate = TamperCaseEvents.EventDate
JOIN #Sites ON TamperCases.EDISID = #Sites.EDISID
WHERE SeverityID <> 0
AND StateID IN (2, 5)
GROUP BY TamperCases.EDISID

DROP TABLE #Sites

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ExceptionTamperRule] TO PUBLIC
    AS [dbo];

