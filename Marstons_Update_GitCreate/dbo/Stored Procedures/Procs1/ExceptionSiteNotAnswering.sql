CREATE PROCEDURE [dbo].[ExceptionSiteNotAnswering]
(
	@EDISID int = NULL,
	@Auditor varchar(255) = NULL
)
AS

/* For Testing */
--DECLARE @EDISID INT = NULL
--DECLARE @Auditor VARCHAR(50) = NULL
--DECLARE @SiteID VARCHAR(15) = NULL --'031622'
--IF @SiteID IS NOT NULL
--    SELECT @EDISID = [EDISID] FROM [dbo].[Sites] WHERE [SiteID] = @SiteID

SET DATEFIRST 1;
SET NOCOUNT ON;

DECLARE @CurrentWeek	DATETIME = GETDATE()
SET @CurrentWeek = DATEADD(dd, 1-DATEPART(dw, @CurrentWeek), @CurrentWeek)

DECLARE @CurrentWeekFrom		DATETIME
DECLARE @To						DATETIME
DECLARE @Today					DATETIME

SET @CurrentWeekFrom = @CurrentWeek

--Get Audit Day for customer, the day in which the audit period will be classed as an extra week forward
DECLARE @AuditDay INT
SELECT @AuditDay = ISNULL(CAST([PropertyValue] AS INTEGER), NULL) FROM [dbo].[Configuration] WHERE [PropertyName] = 'AuditDay'

SET @To = DATEADD(day, 6, @CurrentWeekFrom)

CREATE TABLE #Sites(EDISID INT, Hidden BIT, LastDownload DATETIME, SystemTypeID int)

INSERT INTO #Sites
(EDISID, Hidden, LastDownload, SystemTypeID)
SELECT Sites.EDISID, Hidden, LastDownload, SystemTypeID
FROM Sites
WHERE Hidden = 0
AND (@EDISID IS NULL OR Sites.EDISID = @EDISID)
AND(@Auditor IS NULL OR LOWER(SiteUser) = LOWER(@Auditor))
AND SiteOnline <= @To
AND	[Status] IN (1,3,10)

--WORKING CODE HERE
DECLARE @PreviousSunday datetime = CAST(DATEADD(day, -1, @CurrentWeekFrom) AS Date)
IF @AuditDay IS NOT NULL
BEGIN
	--Get Current Day
	DECLARE @CurrentDay INT
	SET @CurrentDay = DATEPART(dw,GETDATE())

	IF @CurrentDay < @AuditDay
	BEGIN 
		SET @PreviousSunday =  CAST(DATEADD(day, -8, @CurrentWeekFrom) AS Date)
	END
END

DECLARE @DatabaseID INT
SELECT @DatabaseID = [ID] FROM [SQL1\SQL1].[ServiceLogger].[dbo].[EDISDatabases] WHERE [Name] = DB_NAME()
DECLARE @NotificationTypeID INT
SELECT @NotificationTypeID = [NotificationTypeID] FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationType] WHERE [StoredProcedure] = 'ExceptionSiteNotAnswering' -- Do we have permission to access this?
IF @NotificationTypeID IS NOT NULL
BEGIN
    EXEC [SQL1\SQL1].[Auditing].[dbo].[AddNotificationTypeGenerationLog] @NotificationTypeID, @DatabaseID, @EDISID, NULL, @PreviousSunday
END

--DECLARE @DatabaseID int

SELECT	@DatabaseID = ID
FROM	[SQL1\SQL1].[ServiceLogger].[dbo].[EDISDatabases] AS [d]
WHERE	[d].[Name] = DB_NAME()

DECLARE @CannotConnect INT = 29
DECLARE @SystemNotRecording INT = 30

SELECT DISTINCT s.EDISID --ones with NO call already open
FROM	#Sites s
LEFT JOIN (
    SELECT 
        [JobWatchCalls].[EdisID],
        [JobWatchCalls].[JobId],
        [JobWatchCalls].[JobReference]
    FROM [dbo].[JobWatchCalls]
    JOIN [dbo].[JobWatchCallsData] ON [JobWatchCalls].[JobId] = [JobWatchCallsData].[JobId]
    WHERE 
        [JobWatchCalls].[JobActive] = 1
    AND [JobWatchCallsData].[CallReasonTypeID] IN (@CannotConnect,@SystemNotRecording)
) sc ON s.EDISID = sc.[EdisID]
WHERE	
	LastDownload < @PreviousSunday
	AND sc.[EdisID] IS NULL
    
DROP TABLE #Sites

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ExceptionSiteNotAnswering] TO PUBLIC
    AS [dbo];

