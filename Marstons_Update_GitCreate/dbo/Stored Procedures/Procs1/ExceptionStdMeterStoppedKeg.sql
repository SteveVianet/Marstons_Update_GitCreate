CREATE PROCEDURE [dbo].[ExceptionStdMeterStoppedKeg]
(
	@EDISID int = NULL,
	@Auditor varchar(255) = NULL
)
AS

/* For Testing */
--DECLARE @Auditor VARCHAR(255) = NULL
--DECLARE @EDISID INT = NULL --16933
--DECLARE @SiteID VARCHAR (15) = NULL
--IF @SiteID IS NOT NULL
--    SELECT @EDISID = [EDISID] FROM [dbo].[Sites] WHERE [SiteID] = @SiteID

--Calculate dates for latest week of audit period and last 2 weeks of audit period
SET DATEFIRST 1;
SET NOCOUNT ON;

DECLARE @CurrentWeek DATETIME = GETDATE()
SET @CurrentWeek = DATEADD(dd, 1-DATEPART(dw, @CurrentWeek), @CurrentWeek)

DECLARE @OneWeekAgoFrom DATETIME
DECLARE @TwoWeeksAgoWeekFrom DATETIME
DECLARE @To DATETIME
DECLARE @TwoWeeksAgoWeekTo DATETIME

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
			SET @OneWeekAgoFrom = DATEADD(WEEK, -(@AuditWeeksBack-2), DATEADD(WEEK, DATEDIFF(WEEK, 6, GETDATE()), 0)) --take back 1 and a half weeks
		END
	ELSE
		BEGIN 
			SET @OneWeekAgoFrom = DATEADD(WEEK, -(@AuditWeeksBack-1), DATEADD(WEEK, DATEDIFF(WEEK, 6, GETDATE()), 0)) -- take back 2 weeks
		END
END

IF @AuditDay IS NULL
	BEGIN 
		SET @OneWeekAgoFrom = DATEADD(WEEK, -(@AuditWeeksBack-1), DATEADD(WEEK, DATEDIFF(WEEK, 6, GETDATE()), 0))
	END

SET @TwoWeeksAgoWeekFrom = CAST(DATEADD(week, -2, @OneWeekAgoFrom) AS DATE)
SET @To = DATEADD(day, 6, @OneWeekAgoFrom)
SET @TwoWeeksAgoWeekTo = CAST(DATEADD(day, 13, @TwoWeeksAgoWeekFrom) AS DATE)

--SELECT @TwoWeeksAgoWeekFrom AS [2 From], @TwoWeeksAgoWeekTo AS [2 To], @OneWeekAgoFrom AS [1 From], @To AS [1 To]


--Configurable Parameters, assigns the chosen report option from the parameter value in the Notification Parameter table. 

DECLARE @DatabaseID INT
SELECT @DatabaseID = [ID] FROM [SQL1\SQL1].[ServiceLogger].[dbo].[EDISDatabases] WHERE [Name] = DB_NAME()
DECLARE @NotificationTypeID INT
SELECT @NotificationTypeID = [NotificationTypeID] FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationType] WHERE [StoredProcedure] = OBJECT_NAME(@@PROCID)
IF @NotificationTypeID IS NOT NULL
BEGIN
    EXEC [SQL1\SQL1].[Auditing].[dbo].[AddNotificationTypeGenerationLog] @NotificationTypeID, @DatabaseID, @EDISID, @OneWeekAgoFrom, @To
END

DECLARE @ProductsToShow VARCHAR(50)

SELECT 
	@ProductsToShow = CASE
						WHEN [ParameterName] = 'ProductsToShow' 
							THEN [NP].[ParameterValue] 
						ELSE
							@ProductsToShow
					END
FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP]

CREATE TABLE #Sites(EDISID INT, Hidden BIT)

INSERT INTO #Sites
(EDISID, Hidden)
SELECT Sites.EDISID, Hidden
FROM Sites
WHERE Hidden = 0
AND (@EDISID IS NULL OR Sites.EDISID = @EDISID)
AND(@Auditor IS NULL OR LOWER(SiteUser) = LOWER(@Auditor))
AND SiteOnline <= @To
AND [Status] IN (1,3,10)

DECLARE @SitesStoppedLinesReasons TABLE
(
	EDISID int,
	Reason VARCHAR(8000),
	ProductID int,
	Pump int
)

-- Stopped line(s)
DECLARE @Reason VARCHAR(8000) 
DECLARE @NotRecordingDispense INT = 22

INSERT INTO @SitesStoppedLinesReasons (EDISID, Reason, ProductID, Pump)
SELECT
    Sites.EDISID,
    COALESCE(@Reason + ';', '') + CAST(Last2WeeksDispense.Pump AS VARCHAR) + ',' + CAST(Product AS VARCHAR),
    ProductID,
    Last2WeeksDispense.Pump
FROM #Sites AS Sites
	--Dispense in the last 2 weeks in excess of 4 pints
	LEFT JOIN (	
		SELECT EDISID, Pump, [Description]
		FROM
		(
            SELECT	s.EDISID, ps.Pump, p.[Description], DATEADD(dd, 1-DATEPART(dw, md.[Date]), md.[Date]) AS [WeekCommencing], SUM(ISNULL(dis.Quantity, 0)) AS Volume
            FROM	#Sites s
            INNER JOIN PumpSetup ps ON s.EDISID = ps.EDISID AND ps.ValidTo IS NULL
            INNER JOIN Products p ON ps.ProductID = p.ID
            LEFT JOIN MasterDates md ON s.EDISID = md.EDISID AND md.[Date] >= @TwoWeeksAgoWeekFrom AND md.[Date] <= @TwoWeeksAgoWeekTo
            LEFT JOIN DLData dis ON md.ID = dis.DownloadID AND dis.Pump = ps.Pump
            WHERE p.IsWater = 0 
            AND p.IsCask = 0
            GROUP BY s.EDISID, ps.Pump, p.[Description], DATEADD(dd, 1-DATEPART(dw, md.[Date]), md.[Date])
            HAVING SUM(ISNULL(dis.Quantity, 0)) > 4
		) AS DispenseWeeks
		GROUP BY EDISID, Pump, [Description]
		HAVING COUNT(1) >= 1
	) AS Last2WeeksDispense 
		ON Last2WeeksDispense.EDISID = Sites.EDISID
	--Last Weeks dispense
	LEFT JOIN (	
		SELECT	s.EDISID, ps.Pump, p.[Description], SUM(ISNULL(dis.Quantity, 0)) AS Volume
		FROM	#Sites s
		INNER JOIN PumpSetup ps ON s.EDISID = ps.EDISID AND ps.ValidTo IS NULL
		INNER JOIN Products p ON ps.ProductID = p.ID
		LEFT JOIN MasterDates md ON s.EDISID = md.EDISID AND md.[Date] >= @OneWeekAgoFrom AND md.[Date] <= @To
		LEFT JOIN DLData dis ON md.ID = dis.DownloadID AND dis.Pump = ps.Pump
		WHERE p.IsWater = 0 
		AND p.IsCask = 0
		GROUP BY s.EDISID, ps.Pump, p.[Description]
		HAVING SUM(ISNULL(dis.Quantity, 0)) > 0
	) AS LastWeeksDispense 
		ON LastWeeksDispense.EDISID = Last2WeeksDispense.EDISID
		AND LastWeeksDispense.Pump = Last2WeeksDispense.Pump
	--Get Product Information with pump setup to exclude water lines and casks
	LEFT JOIN ( SELECT EDISID, Pump, ProductID, Products.[Description] AS Product, IsWater, IsCask, IsMetric
				FROM PumpSetup
				JOIN Products ON Products.ID = PumpSetup.ProductID
				WHERE InUse = 1 
				AND ValidTo IS NULL
			) AS PumpSetup 
		ON PumpSetup.EDISID = Sites.EDISID
		AND PumpSetup.Pump = Last2WeeksDispense.Pump
	LEFT JOIN (
		SELECT 
            [JobWatchCalls].[EdisID],
            [JobWatchCallsData].[Pump]
        FROM [dbo].[JobWatchCalls]
        JOIN [dbo].[JobWatchCallsData] ON [JobWatchCalls].[JobId] = [JobWatchCallsData].[JobId]
        JOIN [dbo].[PumpSetup] ON [JobWatchCallsData].[Pump] = [PumpSetup].[Pump]
        WHERE 
            [JobWatchCalls].[JobActive] = 1
        AND [JobWatchCallsData].[CallReasonTypeID] IN (@NotRecordingDispense)
        AND [PumpSetup].[ValidTo] IS NULL
	) AS ServiceCall ON Sites.EDISID = ServiceCall.EdisID AND Last2WeeksDispense.Pump = ServiceCall.Pump
WHERE Sites.Hidden = 0
AND Last2WeeksDispense.EDISID IS NOT NULL
AND LastWeeksDispense.EDISID IS NULL
AND	ServiceCall.EdisID IS NULL
AND (
	(@ProductsToShow = 'KegAndSyrup')
	OR (@ProductsToShow = 'KegOnly' AND PumpSetup.IsMetric = 0)
	OR (@ProductsToShow = 'SyrupOnly' AND PumpSetup.IsMetric = 1))
AND PumpSetup.IsWater = 0 
AND PumpSetup.IsCask = 0

SELECT  EDISID, SUBSTRING (
		(
		SELECT ';' + Reason
		FROM @SitesStoppedLinesReasons WHERE 
			EDISID = Results.EDISID
		FOR XML PATH (''),TYPE).value('.','VARCHAR(4000)')
		,2,4000
	) AS ProductList, ProductID, Pump
FROM @SitesStoppedLinesReasons Results
--removed group by as we now need separate notifications for each product 
--(generate notifications should ensure multiple notifications aren't raised in SiteNotification, just stored against product) 

DROP TABLE #Sites

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ExceptionStdMeterStoppedKeg] TO PUBLIC
    AS [dbo];

