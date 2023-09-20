CREATE PROCEDURE [dbo].[ExceptionSiteReopened]
(
	@EDISID int = NULL,
	@Auditor varchar(255) = NULL
)
AS

/* For Testing */
--DECLARE @EDISID INT = NULL
--DECLARE @Auditor VARCHAR(255) = NULL

SET NOCOUNT ON;
SET DATEFIRST 1;

DECLARE @DisableUpdate BIT = 0
DECLARE @DebugParameters BIT = 0

/* For Testing */
--SET @DisableUpdate = 1
--SET @DebugParameters = 1

DECLARE @CurrentWeekFrom		DATETIME
DECLARE @To						DATETIME
DECLARE @Today					DATETIME

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

SET @To = DATEADD(day, 6, @CurrentWeekFrom)

--SELECT @CurrentWeekFrom, @To

CREATE TABLE #Sites(EDISID INT, Hidden BIT)

INSERT INTO #Sites
(EDISID, Hidden)
SELECT Sites.EDISID, Hidden
FROM Sites
WHERE Hidden = 0
AND (@EDISID IS NULL OR Sites.EDISID = @EDISID)
AND(@Auditor IS NULL OR LOWER(SiteUser) = LOWER(@Auditor))
AND [Status] IN (2, 8)
AND SiteOnline <= @To

DECLARE @DatabaseID INT
SELECT @DatabaseID = [ID] FROM [SQL1\SQL1].[ServiceLogger].[dbo].[EDISDatabases] WHERE [Name] = DB_NAME()
DECLARE @NotificationTypeID INT
SELECT @NotificationTypeID = [NotificationTypeID] FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationType] WHERE [StoredProcedure] = OBJECT_NAME(@@PROCID)
IF @NotificationTypeID IS NOT NULL
BEGIN
    EXEC [SQL1\SQL1].[Auditing].[dbo].[AddNotificationTypeGenerationLog] @NotificationTypeID, @DatabaseID, @EDISID, @CurrentWeekFrom, @To
END

DECLARE @MinimumDispense INT

SELECT @MinimumDispense = CAST(ParameterValue AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'ReOpenMinDispense'

IF @DebugParameters = 1
BEGIN
    SELECT @MinimumDispense AS [ReOpenMinDispense]
END

CREATE TABLE #Reopened
(
	EDISID INT
)

INSERT INTO #Reopened
--WORKING CODE HERE
SELECT [Dispense].EDISID
FROM (
    SELECT	s.EDISID, SUM(dis.Quantity) AS [Quantity]
    FROM	#Sites s
    LEFT JOIN MasterDates md on s.EDISID = md.EDISID AND md.[Date] >= @CurrentWeekFrom AND md.[Date] <= @To
    LEFT JOIN PumpSetup ps ON s.EDISID = ps.EDISID
    LEFT JOIN DLData dis on ps.Pump = dis.Pump AND md.ID = dis.DownloadID
    GROUP BY s.EDISID
    HAVING COUNT(dis.DownloadID) > 0
    UNION
    SELECT	s.EDISID, SUM(wat.Volume) AS [Quantity]
    FROM	#Sites s
    LEFT JOIN MasterDates md on s.EDISID = md.EDISID AND md.[Date] >= @CurrentWeekFrom AND md.[Date] <= @To
    LEFT JOIN PumpSetup ps ON s.EDISID = ps.EDISID
    LEFT JOIN WaterStack wat on ps.Pump = wat.Line AND md.ID = wat.WaterID
    GROUP BY s.EDISID
    HAVING COUNT(wat.WaterID) > 0
    ) AS [Dispense]
WHERE [Quantity] >= @MinimumDispense
GROUP BY [Dispense].[EDISID]
UNION
SELECT	s.EDISID 
FROM	#Sites s
LEFT JOIN MasterDates md on s.EDISID = md.EDISID AND md.[Date] >= @CurrentWeekFrom AND md.[Date] <= @To
LEFT JOIN Delivery del ON md.ID = del.DeliveryID
GROUP BY s.EDISID
HAVING COUNT(del.DeliveryID) > 0

SELECT DISTINCT EDISID FROM #Reopened

IF @DisableUpdate = 0
BEGIN
    DECLARE @CurrentEDISID INT

    DECLARE @SiteCursor CURSOR

    SET @SiteCursor = CURSOR FAST_FORWARD FOR
    SELECT EDISID
    FROM #Reopened
     
    OPEN @SiteCursor;
    FETCH NEXT FROM @SiteCursor INTO @CurrentEDISID

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC dbo.UpdateSiteStatus @CurrentEDISID, 1

        FETCH NEXT FROM @SiteCursor INTO @CurrentEDISID
    END

    CLOSE @SiteCursor;
    DEALLOCATE @SiteCursor;
END
ELSE
BEGIN
    PRINT 'Site Status Update Disabled'
END
    
DROP TABLE #Reopened
DROP TABLE #Sites
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ExceptionSiteReopened] TO PUBLIC
    AS [dbo];

