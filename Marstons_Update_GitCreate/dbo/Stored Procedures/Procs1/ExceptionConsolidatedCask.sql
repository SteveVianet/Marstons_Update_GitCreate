CREATE PROCEDURE [dbo].[ExceptionConsolidatedCask]
(
	@EDISID INT = NULL,
	@Auditor VARCHAR(255) = NULL
)
AS

/* For Testing */
--DECLARE @Auditor VARCHAR(255) = NULL
--DECLARE @EDISID INT = NULL --30
--DECLARE @SiteID VARCHAR (15) = '532458'
--IF @SiteID IS NOT NULL
--    SELECT @EDISID = [EDISID] FROM [dbo].[Sites] WHERE [SiteID] = @SiteID

SET NOCOUNT ON;
SET DATEFIRST 1;

DECLARE @EnableLogging BIT = 1
DECLARE @DebugParameters BIT = 0
DECLARE @DebugDelivery BIT = 0
DECLARE @DebugConsolidated BIT = 0
DECLARE @DebugDates BIT = 0

--DECLARE @CurrentWeek	DATETIME = CAST(GETDATE() AS DATE)
--SET @CurrentWeek = DATEADD(dd, 1-DATEPART(dw, @CurrentWeek), @CurrentWeek)

/* For testing */
--SET @EnableLogging = 0
--SET @DebugParameters = 1
--SET @DebugDelivery = 1
--SET @DebugConsolidated = 1
--SET @DebugDates = 1
--SET @BaseFrom = DATEADD(WEEK, -4, @BaseFrom) 
--SET @BaseTo = DATEADD(WEEK, -4, @BaseTo)

DECLARE @CurrentWeekFrom		DATETIME
DECLARE @To						DATETIME
DECLARE @Today					DATETIME
DECLARE @ReviewWeekFrom			DATETIME

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

-- KG Testing
--SET @CurrentWeekFrom = DATEADD(WEEK, -1, @CurrentWeekFrom)

SET @To = DATEADD(day, 6, @CurrentWeekFrom)
SET @ReviewWeekFrom = DATEADD(week, -11, @CurrentWeekFrom)

DECLARE @WeekDifference	INT
SELECT @WeekDifference = DATEDIFF(week, @ReviewWeekFrom, @CurrentWeekFrom) + 1

IF @DebugDates = 1
BEGIN
    SELECT @CurrentWeekFrom, @ReviewWeekFrom, @WeekDifference
END

IF @EnableLogging = 1
BEGIN
    DECLARE @DatabaseID INT
    SELECT @DatabaseID = [ID] FROM [SQL1\SQL1].[ServiceLogger].[dbo].[EDISDatabases] WHERE [Name] = DB_NAME()
    DECLARE @NotificationTypeID INT
    SELECT @NotificationTypeID = [NotificationTypeID] FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationType] WHERE [StoredProcedure] = OBJECT_NAME(@@PROCID)
    IF @NotificationTypeID IS NOT NULL
    BEGIN
        EXEC [SQL1\SQL1].[Auditing].[dbo].[AddNotificationTypeGenerationLog] @NotificationTypeID, @DatabaseID, @EDISID, @ReviewWeekFrom, @To
    END
END
ELSE
BEGIN
    PRINT 'Logging Disabled'
END

CREATE TABLE #Sites(EDISID INT, Hidden BIT)

INSERT INTO #Sites
(EDISID, Hidden)
SELECT Sites.EDISID, Hidden
FROM Sites
WHERE Hidden = 0
AND (@EDISID IS NULL OR Sites.EDISID = @EDISID)
AND [Status] IN (1, 3, 10)
AND SiteOnline <= @To
AND (@Auditor is null or LOWER(SiteUser) = LOWER(@Auditor))

DECLARE @ConsCaskADisp int
DECLARE @ConsCaskADelPerc int
--DECLARE @ConsCaskBDispLow int
DECLARE @ConsCaskBDispHigh int
DECLARE @ConsCaskBDelPerc int
--DECLARE @ConsCaskCDispLow int
DECLARE @ConsCaskCDispHigh int
DECLARE @ConsCaskCDelPerc int
--DECLARE @ConsCaskDDisp int
DECLARE @ConsCaskDDelPerc int

/* Removed use of 'duplicate' values so A-B-C-D have to work together. Avoids possibility of gaps (such as bwtween B-C 30-31g in original spec) */
SELECT @ConsCaskADisp       = CAST(ParameterValue AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'ConsCaskADisp'     -- A: 10g
SELECT @ConsCaskADelPerc    = CAST(ParameterValue AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'ConsCaskADelPerc'  -- A: 30%
--SELECT @ConsCaskBDispLow  = CAST(ParameterValue AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'ConsCaskBDispLow'  -- B: 10g -- use ConsCaskADisp
SELECT @ConsCaskBDispHigh   = CAST(ParameterValue AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'ConsCaskBDispHigh' -- B: 30g
SELECT @ConsCaskBDelPerc    = CAST(ParameterValue AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'ConsCaskBDelPerc'  -- B: 25%
--SELECT @ConsCaskCDispLow  = CAST(ParameterValue AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'ConsCaskCDispLow'  -- C: 31g -- use ConsCaskBDispHigh
SELECT @ConsCaskCDispHigh   = CAST(ParameterValue AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'ConsCaskCDispHigh' -- C: 50g
SELECT @ConsCaskCDelPerc    = CAST(ParameterValue AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'ConsCaskCDelPerc'  -- C: 20%
--SELECT @ConsCaskDDisp     = CAST(ParameterValue AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'ConsCaskDDisp'     -- D: 50g -- use ConsCaskCDispHigh
SELECT @ConsCaskDDelPerc    = CAST(ParameterValue AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'ConsCaskDDelPerc'  -- D: 15%

IF @DebugParameters = 1
BEGIN
    SELECT 
        @ConsCaskADisp [ConsCaskADisp],
        @ConsCaskADelPerc [ConsCaskADelPerc],

        --@ConsCaskBDispLow [ConsCaskBDispLow],
        @ConsCaskBDispHigh [ConsCaskBDispHigh],
        @ConsCaskBDelPerc [ConsCaskBDelPerc],

        --@ConsCaskCDispLow [ConsCaskCDispLow],
        @ConsCaskCDispHigh [ConsCaskCDispHigh],
        @ConsCaskCDelPerc [ConsCaskCDelPerc],

        --@ConsCaskDDisp [ConsCaskDDisp],
        @ConsCaskDDelPerc [ConsCaskDDelPerc]
END

IF @DebugDelivery = 1
BEGIN
    SELECT	s.EDISID, SUM(d.Quantity) AS Delivered, DATEADD(dd, 1-DATEPART(dw, md.[Date]), md.[Date]) AS WeekCommencing
	FROM	#Sites s
	INNER JOIN MasterDates md ON s.EDISID = md.EDISID
	INNER JOIN Delivery d on md.ID = d.DeliveryID
	INNER JOIN Products p ON d.Product = p.ID
    LEFT JOIN [dbo].[SiteProductTies] AS [SPT] 
        ON [p].[ID] = [SPT].[ProductID] AND [s].[EDISID] = [SPT].[EDISID]
    LEFT JOIN [dbo].[SiteProductCategoryTies] AS [SPCT] 
        ON [p].[CategoryID] = [SPCT].[ProductCategoryID] AND [s].[EDISID] = [SPCT].[EDISID]
	WHERE	md.[Date] >= @ReviewWeekFrom AND md.[Date] <= @To
	AND		p.IsCask = 1 AND p.IsWater = 0 AND p.IsMetric = 0
    AND	COALESCE([SPT].[Tied], [SPCT].[Tied], [p].[Tied]) = 1 -- Only Tied 
	GROUP BY s.EDISID, DATEADD(dd, 1-DATEPART(dw, md.[Date]), md.[Date])
    ORDER BY WeekCommencing

    SELECT	s.EDISID, p.[Description] AS Product, d.Quantity AS Delivered, md.[Date], DATEADD(dd, 1-DATEPART(dw, md.[Date]), md.[Date]) AS WeekCommencing
	FROM	#Sites s
	INNER JOIN MasterDates md ON s.EDISID = md.EDISID
	INNER JOIN Delivery d on md.ID = d.DeliveryID
	INNER JOIN Products p ON d.Product = p.ID
    LEFT JOIN [dbo].[SiteProductTies] AS [SPT] 
        ON [p].[ID] = [SPT].[ProductID] AND [s].[EDISID] = [SPT].[EDISID]
    LEFT JOIN [dbo].[SiteProductCategoryTies] AS [SPCT] 
        ON [p].[CategoryID] = [SPCT].[ProductCategoryID] AND [s].[EDISID] = [SPCT].[EDISID]
	WHERE	md.[Date] >= @ReviewWeekFrom AND md.[Date] <= @To
	AND		p.IsCask = 1 AND p.IsWater = 0 AND p.IsMetric = 0 
    AND	COALESCE([SPT].[Tied], [SPCT].[Tied], [p].[Tied]) = 1 -- Only Tied
    ORDER BY WeekCommencing, p.[Description]
END

IF @DebugConsolidated = 1
BEGIN
    ;WITH Cask_Deliveries (EDISID, Quantity)
    AS
    (
	    SELECT SubDelivery.EDISID, SUM(Delivered) / @WeekDifference
	    FROM (
			    SELECT	s.EDISID, SUM(d.Quantity) AS Delivered, DATEADD(dd, 1-DATEPART(dw, md.[Date]), md.[Date]) AS WeekCommencing
			    FROM	#Sites s
			    INNER JOIN MasterDates md ON s.EDISID = md.EDISID
			    INNER JOIN Delivery d on md.ID = d.DeliveryID
			    INNER JOIN Products p ON d.Product = p.ID
                LEFT JOIN [dbo].[SiteProductTies] AS [SPT] 
                    ON [p].[ID] = [SPT].[ProductID] AND [s].[EDISID] = [SPT].[EDISID]
                LEFT JOIN [dbo].[SiteProductCategoryTies] AS [SPCT] 
                    ON [p].[CategoryID] = [SPCT].[ProductCategoryID] AND [s].[EDISID] = [SPCT].[EDISID]
			    WHERE	md.[Date] >= @ReviewWeekFrom AND md.[Date] <= @To
			    AND		p.IsCask = 1 AND p.IsWater = 0 AND p.IsMetric = 0 -- Only Cask
                AND	COALESCE([SPT].[Tied], [SPCT].[Tied], [p].[Tied]) = 1 -- Only Tied
			    GROUP BY s.EDISID, DATEADD(dd, 1-DATEPART(dw, md.[Date]), md.[Date])
	    ) AS SubDelivery
	    GROUP BY SubDelivery.EDISID
    ), Cask_Dispense (EDISID, Quantity)
    AS
    (
	    SELECT SubDispense.EDISID, SUM(Dispense) / @WeekDifference
	    FROM
	    (
			    SELECT	s.EDISID,  SUM(d.Quantity) * 0.125 AS Dispense, DATEADD(dd, 1-DATEPART(dw, md.[Date]), md.[Date]) AS WeekCommencing
			    FROM	#Sites s
			    INNER JOIN	MasterDates md ON s.EDISID = md.EDISID AND md.[Date] >= @ReviewWeekFrom AND md.[Date] <= @To
			    INNER JOIN	DLData d ON md.ID = d.DownloadID
			    INNER JOIN	Products p ON d.Product = p.ID
                LEFT JOIN [dbo].[SiteProductTies] AS [SPT] 
                    ON [p].[ID] = [SPT].[ProductID] AND [s].[EDISID] = [SPT].[EDISID]
                LEFT JOIN [dbo].[SiteProductCategoryTies] AS [SPCT] 
                    ON [p].[CategoryID] = [SPCT].[ProductCategoryID] AND [s].[EDISID] = [SPCT].[EDISID]
			    WHERE	p.IsCask = 1 AND p.IsWater = 0 AND p.IsMetric = 0 -- Only Cask
                AND	COALESCE([SPT].[Tied], [SPCT].[Tied], [p].[Tied]) = 1 -- Only Tied
			    GROUP BY s.EDISID, DATEADD(dd, 1-DATEPART(dw, md.[Date]), md.[Date])
	    ) AS SubDispense
	    GROUP BY SubDispense.EDISID
	    HAVING COUNT(1) = @WeekDifference
    )
    SELECT *
    FROM
    (
	    SELECT	cdel.EDISID, cdis.Quantity AS AvgDispensed, cdel.Quantity AS AvgDelivered, (((cdis.Quantity - cdel.Quantity) / cdis.Quantity) * 100) AS DiffPercent
	    FROM	Cask_Deliveries cdel
	    INNER JOIN Cask_Dispense cdis ON cdel.EDISID =  cdis.EDISID
	    WHERE (cdel.Quantity - cdis.Quantity > 0) 
    ) AS CalculatedData
    WHERE
        CalculatedData.EDISID IN 
        (
	        SELECT	s.EDISID
	        FROM	#Sites s
	        INNER JOIN MasterDates md ON s.EDISID = md.EDISID
	        INNER JOIN Delivery d on md.ID = d.DeliveryID
	        INNER JOIN Products p ON d.Product = p.ID
	        WHERE	md.[Date] >= @CurrentWeekFrom AND md.[Date] <= @To
	        AND		p.IsCask = 1 AND p.IsWater = 0 AND p.IsMetric = 0
        )
END

;WITH Cask_Deliveries (EDISID, Quantity)
AS
(
	SELECT SubDelivery.EDISID, SUM(Delivered) / @WeekDifference
	FROM (
			SELECT	s.EDISID, SUM(d.Quantity) AS Delivered, DATEADD(dd, 1-DATEPART(dw, md.[Date]), md.[Date]) AS WeekCommencing
			FROM	#Sites s
			INNER JOIN MasterDates md ON s.EDISID = md.EDISID
			INNER JOIN Delivery d on md.ID = d.DeliveryID
			INNER JOIN Products p ON d.Product = p.ID
            LEFT JOIN [dbo].[SiteProductTies] AS [SPT] 
                ON [p].[ID] = [SPT].[ProductID] AND [s].[EDISID] = [SPT].[EDISID]
            LEFT JOIN [dbo].[SiteProductCategoryTies] AS [SPCT] 
                ON [p].[CategoryID] = [SPCT].[ProductCategoryID] AND [s].[EDISID] = [SPCT].[EDISID]
			WHERE	md.[Date] >= @ReviewWeekFrom AND md.[Date] <= @To
			AND		p.IsCask = 1 AND p.IsWater = 0 AND p.IsMetric = 0 -- Only Cask
            AND	COALESCE([SPT].[Tied], [SPCT].[Tied], [p].[Tied]) = 1 -- Only Tied
			GROUP BY s.EDISID, DATEADD(dd, 1-DATEPART(dw, md.[Date]), md.[Date])
	) AS SubDelivery
	GROUP BY SubDelivery.EDISID
), Cask_Dispense (EDISID, Quantity)
AS
(
	SELECT SubDispense.EDISID, SUM(Dispense) / @WeekDifference
	FROM
	(
			SELECT	s.EDISID,  SUM(d.Quantity) * 0.125 AS Dispense, DATEADD(dd, 1-DATEPART(dw, md.[Date]), md.[Date]) AS WeekCommencing
			FROM	#Sites s
			INNER JOIN	MasterDates md ON s.EDISID = md.EDISID AND md.[Date] >= @ReviewWeekFrom AND md.[Date] <= @To
			INNER JOIN	DLData d ON md.ID = d.DownloadID
			INNER JOIN	Products p ON d.Product = p.ID
            LEFT JOIN [dbo].[SiteProductTies] AS [SPT] 
                ON [p].[ID] = [SPT].[ProductID] AND [s].[EDISID] = [SPT].[EDISID]
            LEFT JOIN [dbo].[SiteProductCategoryTies] AS [SPCT] 
                ON [p].[CategoryID] = [SPCT].[ProductCategoryID] AND [s].[EDISID] = [SPCT].[EDISID]
			WHERE	p.IsCask = 1 AND p.IsWater = 0 AND p.IsMetric = 0 
            AND	COALESCE([SPT].[Tied], [SPCT].[Tied], [p].[Tied]) = 1 -- Only Tied
			GROUP BY s.EDISID, DATEADD(dd, 1-DATEPART(dw, md.[Date]), md.[Date])
	) AS SubDispense
	GROUP BY SubDispense.EDISID
	HAVING COUNT(1) = @WeekDifference
)
SELECT DISTINCT CalculatedData.EDISID, -1, NULL
    --,CASE WHEN (CalculatedData.AvgDispensed < @ConsCaskADisp AND CalculatedData.DiffPercent < -@ConsCaskADelPerc) THEN 1 ELSE 0 END AS [A]
    --,CASE WHEN ((CalculatedData.AvgDispensed >= @ConsCaskADisp AND CalculatedData.AvgDispensed <= @ConsCaskBDispHigh) AND CalculatedData.DiffPercent < -@ConsCaskBDelPerc) THEN 1 ELSE 0 END AS [B]
    --,CASE WHEN ((CalculatedData.AvgDispensed >= @ConsCaskBDispHigh AND CalculatedData.AvgDispensed <= @ConsCaskCDispHigh) AND CalculatedData.DiffPercent < -@ConsCaskCDelPerc) THEN 1 ELSE 0 END AS [C]
    --,CASE WHEN (CalculatedData.AvgDispensed > @ConsCaskCDispHigh AND CalculatedData.DiffPercent < -@ConsCaskDDelPerc) THEN 1 ELSE 0 END AS [D]
    --,CalculatedData.AvgDispensed
    --,@ConsCaskCDispHigh
    --,CalculatedData.DiffPercent
    --,-@ConsCaskDDelPerc
FROM
(
	SELECT	cdel.EDISID, cdis.Quantity AS AvgDispensed, cdel.Quantity AS AvgDelivered, (((cdis.Quantity - cdel.Quantity) / cdis.Quantity) * 100) AS DiffPercent
	FROM	Cask_Deliveries cdel
	INNER JOIN Cask_Dispense cdis ON cdel.EDISID =  cdis.EDISID
	WHERE (cdel.Quantity - cdis.Quantity > 0) 
) AS CalculatedData
WHERE
(
	(CalculatedData.AvgDispensed < @ConsCaskADisp AND CalculatedData.DiffPercent < -@ConsCaskADelPerc)
	OR
	((CalculatedData.AvgDispensed >= @ConsCaskADisp AND CalculatedData.AvgDispensed <= @ConsCaskBDispHigh) AND CalculatedData.DiffPercent < -@ConsCaskBDelPerc)
	OR
	((CalculatedData.AvgDispensed >= @ConsCaskBDispHigh AND CalculatedData.AvgDispensed <= @ConsCaskCDispHigh) AND CalculatedData.DiffPercent < -@ConsCaskCDelPerc)
	OR
	(CalculatedData.AvgDispensed > @ConsCaskCDispHigh AND CalculatedData.DiffPercent < -@ConsCaskDDelPerc)
)
AND CalculatedData.EDISID IN 
(
	SELECT	s.EDISID
	FROM	#Sites s
	INNER JOIN MasterDates md ON s.EDISID = md.EDISID
	INNER JOIN Delivery d on md.ID = d.DeliveryID
	INNER JOIN Products p ON d.Product = p.ID
	WHERE	md.[Date] >= @CurrentWeekFrom AND md.[Date] <= @To
	AND		p.IsCask = 1 AND p.IsWater = 0 AND p.IsMetric = 0
)

DROP TABLE #Sites
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ExceptionConsolidatedCask] TO PUBLIC
    AS [dbo];

