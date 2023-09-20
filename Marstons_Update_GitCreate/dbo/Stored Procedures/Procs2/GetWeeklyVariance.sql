CREATE PROCEDURE [dbo].[GetWeeklyVariance]
(
    @EDISID                 INT = NULL,
    @GroupID                INT = NULL,
    @From                   DATE,
    @To                     DATE,
    @IncludeConsolidated    BIT = 1,
    @IncludeCasks           BIT = 1,
    @IncludeKegs            BIT = 1,
    @IncludeMetric          BIT = 1,
    @Tied                   BIT = NULL
)
AS

/* For Testing */
--DECLARE    @EDISID                 INT = 1256 --3399
--DECLARE    @GroupID                INT = NULL--21 --40
--DECLARE    @From                   DATE = '2016-08-08'
--DECLARE    @To                     DATE = '2016-10-30'
--DECLARE    @IncludeConsolidated    BIT = 1
--DECLARE    @IncludeCasks           BIT = 1
--DECLARE    @IncludeKegs            BIT = 1
--DECLARE    @IncludeMetric          BIT = 1
--DECLARE    @Tied                   BIT = NULL

/* Parameter Sniffing (Bad Plan) Work-around */
DECLARE    @xEDISID                 INT = @EDISID
DECLARE    @xGroupID                INT = @GroupID
DECLARE    @xFrom                   DATE = @From
DECLARE    @xTo                     DATE = @To
DECLARE    @xIncludeConsolidated    BIT = @IncludeConsolidated
DECLARE    @xIncludeCasks           BIT = @IncludeCasks
DECLARE    @xIncludeKegs            BIT = @IncludeKegs
DECLARE    @xIncludeMetric          BIT = @IncludeMetric
DECLARE    @xTied                   BIT = @Tied

SET NOCOUNT ON
-- Change the first day of the week to Monday (default is Sunday/7)
SET DATEFIRST 1

DECLARE @ToGallons FLOAT = 0.125     -- {Pint Value} * @ToGallons
DECLARE @ToLitres FLOAT = 0.568261   -- {Pint Value} * @ToLitres

DECLARE @TrendThreshold INT = -5

--Adjust Dates appropriately (Monday - Sunday)
SET @xFrom = DATEADD(WEEK, DATEDIFF(WEEK, 0, @xFrom), 0)
-- If To Date *IS NOT* a Sunday, select the previous Sunday
IF DATEPART(WEEKDAY, @xTo) <> 7
BEGIN
    SET @xTo = DATEADD(WEEK, DATEDIFF(WEEK,0, @xTo)-1, 6)
END

/* Based on PeriodCacheVarianceInternalRebuild */

IF OBJECT_ID('tempdb..#PeriodVarianceInternal') IS NOT NULL
DROP TABLE #PeriodVarianceInternal

CREATE TABLE #PeriodVarianceInternal (
	[EDISID] INT NOT NULL,
	[WeekCommencing] DATE NOT NULL,
	[ProductID] INT NOT NULL,
	[IsTied] BIT NOT NULL,
	[Delivered] FLOAT NOT NULL,
	[Dispensed] FLOAT NOT NULL,
	[Variance] FLOAT NOT NULL,
	[StockDate] DATE NULL,
	[Stock] FLOAT NULL,
	[StockAdjustedDelivered] FLOAT NOT NULL,
	[StockAdjustedDispensed] FLOAT NOT NULL,
	[StockAdjustedVariance] FLOAT NOT NULL,
	[IsAudited] BIT NOT NULL,
    PRIMARY KEY ([EDISID], [WeekCommencing], [ProductID]))


DECLARE @AccurateDeliveryProvided AS BIT
SELECT @AccurateDeliveryProvided = CASE WHEN Configuration.PropertyValue = 'False' THEN 0 ELSE 1 END
FROM [dbo].[Configuration]
WHERE PropertyName = 'Accurate Stock'

/* For Testing */ 
--SELECT @AccurateDeliveryProvided AS [AccurateStock]

DECLARE @WebAudit AS DATETIME
SELECT @WebAudit = DATEADD(day, -DATEPART(dw, CAST(Configuration.PropertyValue AS DATETIME)) +1, CAST(Configuration.PropertyValue AS DATETIME) + 7)
FROM [dbo].[Configuration]
WHERE PropertyName = 'AuditDate'

--Merge products groups
DECLARE @PrimaryProducts TABLE(ProductID INT NOT NULL, PrimaryProductID INT NOT NULL)
INSERT INTO @PrimaryProducts (ProductID, PrimaryProductID)
SELECT ProductID, ProductGroupPrimaries.PrimaryProductID
FROM ProductGroupProducts
JOIN ProductGroups ON ProductGroups.ID = ProductGroupProducts.ProductGroupID
JOIN (
	SELECT ProductGroupID, ProductID AS PrimaryProductID
	FROM ProductGroupProducts
	JOIN ProductGroups ON ProductGroups.ID = ProductGroupProducts.ProductGroupID
	WHERE TypeID = 1 AND IsPrimary = 1
) AS ProductGroupPrimaries ON ProductGroupPrimaries.ProductGroupID = ProductGroups.ID
WHERE TypeID = 1 AND IsPrimary = 0

--Get relevant Sites
DECLARE @Sites TABLE ([EDISID] INT NOT NULL)
IF @xEDISID IS NOT NULL
BEGIN
    INSERT INTO @Sites ([EDISID])
    SELECT @xEDISID
END
ELSE IF @xGroupID IS NOT nULL
BEGIN 
    INSERT INTO @Sites ([EDISID])
    SELECT [EDISID]
    FROM [dbo].[SiteGroupSites]
    WHERE [SiteGroupID] = @xGroupID
END

--Merge system groups
DECLARE @PrimaryEdisID int = null;
DECLARE @PrimaryEDIS TABLE(PrimaryEDISID INT, EDISID INT NOT NULL)


IF @xGroupID is not null
BEGIN -- Site Group (only support Multi-Cellar)
	SELECT @xGroupID = SiteGroupID 
	FROM SiteGroupSites sgs
	JOIN SiteGroups sg on TypeID = 1 and sg.ID = sgs.SiteGroupID 
	WHERE sgs.EDISID = @xEDISID
    
    SELECT @PrimaryEdisID = EDISID 
    FROM SiteGroupSites sgs
    WHERE 
	    
         sgs.SiteGroupID = @xGroupID

    INSERT INTO @PrimaryEDIS ([PrimaryEDISID], [EDISID])
    SELECT @PrimaryEdisID, EDISID
    FROM SiteGroupSites sgs
    WHERE SiteGroupID = @xGroupID
END

IF @xGroupID is null 
BEGIN -- Individual Site
    SELECT @PrimaryEdisID = @xEDISID
    
	INSERT INTO @PrimaryEDIS ([PrimaryEDISID], [EDISID])
    SELECT @PrimaryEdisID, EDISID
    FROM Sites AS s
	WHERE EDISID = @xEDISID
END 

/* **************************************************************************************************************************************************
    Sites and Stock
*/
DECLARE @MinStock DATE
DECLARE @StockWeeksBack INT
SELECT @StockWeeksBack = [PropertyValue] FROM [dbo].[Configuration] WHERE [PropertyName] = 'Oldest Stock Weeks Back'
SET @MinStock = DATEADD(WEEK, -@StockWeeksBack, @xFrom)


DECLARE @MinimumTrend INT = 5
DECLARE @Variance TABLE (
    [WeekCommencing] DATE NOT NULL, 
    [IsCask] BIT NOT NULL DEFAULT(0), 
    [IsKeg] BIT NOT NULL DEFAULT(0),
    [IsMetric] BIT NOT NULL DEFAULT(0), 
    [Dispensed] FLOAT NOT NULL DEFAULT(0), 
    [Delivered] FLOAT NOT NULL DEFAULT(0), 
    [Variance] FLOAT NOT NULL DEFAULT(0), 
    [StockVariance] FLOAT,
    [Stock] FLOAT, 
    [CumulativeVariance] FLOAT NOT NULL DEFAULT(0),
    [CumulativeStockVariance] FLOAT, 
    [IsTied] BIT NOT NULL DEFAULT(0),
    [IsConsolidated] BIT NOT NULL DEFAULT(0), 
    [IsAdjusted] BIT NOT NULL DEFAULT (0),
    [IsOnFontSetup] BIT NOT NULL DEFAULT (0),
    [Trending] BIT NOT NULL DEFAULT(0),
    [Trend] FLOAT,
    [TrendTotal] FLOAT,
    [ID] INT IDENTITY (1,1), -- Req. to work around SQL Server bug (https://support.microsoft.com/en-gb/kb/960770)
    UNIQUE CLUSTERED ([WeekCommencing])
    )

DECLARE @ProductTies TABLE (
    [ProductID] INT NOT NULL, 
    [IsTied] BIT NOT NULL
    UNIQUE CLUSTERED ([ProductID], [IsTied])
    )

DECLARE @SiteProductStock TABLE ([EDISID] INT NOT NULL, [WeekCommencing] DATE NOT NULL, [ProductID] INT NOT NULL DEFAULT(0), [BeforeDelivery] BIT NOT NULL, [IsCask] BIT NOT NULL, [Stock] FLOAT NOT NULL PRIMARY KEY ([EDISID], [WeekCommencing], [ProductID]))
DECLARE @SiteDates TABLE ([EDISID] INT NOT NULL, [StockWC] DATE, [StockDate] DATE, [VisitDate] DATE, [COTDate] DATE)

IF @xGroupID is not null 
BEGIN
	IF NOT EXISTS (SELECT ID FROM SiteGroups sg WHERE TypeID = 2 and sg.ID = @xGroupID) --If not a multi operator
	BEGIN
		INSERT INTO @SiteDates ([EDISID], [StockWC], [StockDate], [VisitDate], [COTDate])
		SELECT 
			[S].[EDISID],
			DATEADD(DD, -(DATEPART(DW, [CurrentStock].[LatestStock])-1), [CurrentStock].[LatestStock]) AS [LastestStock], -- The WC date for which the Stock becomes usable
			[CurrentStock].[LatestStock] ,
			[VR].[WeekCommencing] AS [VisitDate],
			[COT].[WeekCommencing] AS [COTDate]
		FROM [dbo].[Sites] AS [S]
		LEFT JOIN (
			SELECT
				[VR].[EDISID],
				--COUNT([VD].DamagesID) AS [Damages],
				--MAX([VR].[VisitDate]) AS [LatestVisit],
				MAX(CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, [VR].[VisitDate]), 0) AS DATE)) AS [WeekCommencing]
			FROM [dbo].[VisitRecords] AS [VR]
			JOIN [dbo].[VisitDamages] AS [VD] ON [VR].[ID] = [VD].[VisitRecordID]
			JOIN [dbo].[Sites] AS [S] ON [VR].[EDISID] = [S].[EDISID]
			WHERE 
				--[VR].[DamagesObtained] = 1
			--AND [VR].[Deleted] = 0
				[S].[SiteOnline] <= [VR].[VisitDate]
			--AND (@xEDISID IS NULL OR [S].[EDISID] = @xEDISID)
			--AND [VR].[VisitOutcomeID] IN 
			--    (1,2,7,9,11) 
				/*
				 1  - Buying-out - full admission (lessee), 
				 2  - Buying-out - full admission (not lessee), 
				 7  - Tampering found - full admission, 
				 9  - Tampering found - no admission (admitted buying out), 
				 11 - Buying-out & Tampering - Full admission
				 */
			AND [VR].[VisitDate] >= @xFrom -- Anything earlier is irrelevant 
			AND [VR].[VisitDate] <= @xTo-- Anything later is not yet relevant
			GROUP BY 
				[VR].[EDISID]
			) AS [VR] ON [S].[EDISID] = [VR].[EDISID]
		LEFT JOIN (
			SELECT
				[SC].[EDISID],
				MAX(CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, [SC].[Date]), 0) AS DATE)) AS [WeekCommencing]
			FROM [dbo].[SiteComments] AS [SC]
			WHERE 
				[SC].[HeadingType] IN (3004) -- Change of Tenancy  (16 also exists, but doesn't appear to be used anymore?)
			AND [SC].[Date] >= @xFrom -- Anything earlier is irrelevant
			AND [SC].[Date] <= @xTo -- Anything later is not yet relevant
			GROUP BY 
				[SC].[EDISID]
			) AS [COT] ON [S].[EDISID] = [COT].[EDISID]
		LEFT JOIN (
			SELECT 
				[S].[EDISID],
				MAX([MD].[Date]) AS [LatestStock]
			FROM [dbo].[Sites] AS [S]
			JOIN [dbo].[MasterDates] AS [MD] ON [S].[EDISID] = [MD].[EDISID]
			JOIN [dbo].[Stock] AS [St] ON [MD].[ID] = [St].[MasterDateID] 
			WHERE ([MD].[Date] >= @MinStock AND [MD].[Date] <= @xTo)
			AND [MD].[Date] >= [S].[SiteOnline]
			GROUP BY [S].[EDISID]
			) AS [CurrentStock] ON [S].[EDISID] = [CurrentStock].[EDISID]
		JOIN @PrimaryEDIS AS PrimarySites ON [S].EDISID = PrimarySites.EDISID
		LEFT JOIN SiteGroupSites AS sgs ON sgs.EDISID = PrimarySites.EDISID
		WHERE 
			([S].[EDISID] = @xEDISID OR @xEDISID IS NULL)
	END
	ELSE
	BEGIN
		INSERT INTO @SiteDates ([EDISID])
		SELECT [EDISID]
		FROM [dbo].[SiteGroupSites]
		WHERE [SiteGroupID] = @xGroupID
	END
END
IF @xGroupID is null
BEGIN
		INSERT INTO @SiteDates ([EDISID], [StockWC], [StockDate], [VisitDate], [COTDate])
		SELECT 
			[S].[EDISID],
			DATEADD(DD, -(DATEPART(DW, [CurrentStock].[LatestStock])-1), [CurrentStock].[LatestStock]) AS [LastestStock], -- The WC date for which the Stock becomes usable
			[CurrentStock].[LatestStock] ,
			[VR].[WeekCommencing] AS [VisitDate],
			[COT].[WeekCommencing] AS [COTDate]
		FROM [dbo].[Sites] AS [S]
		LEFT JOIN (
			SELECT
				[VR].[EDISID],
				--COUNT([VD].DamagesID) AS [Damages],
				--MAX([VR].[VisitDate]) AS [LatestVisit],
				MAX(CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, [VR].[VisitDate]), 0) AS DATE)) AS [WeekCommencing]
			FROM [dbo].[VisitRecords] AS [VR]
			JOIN [dbo].[VisitDamages] AS [VD] ON [VR].[ID] = [VD].[VisitRecordID]
			JOIN [dbo].[Sites] AS [S] ON [VR].[EDISID] = [S].[EDISID]
			WHERE 
				--[VR].[DamagesObtained] = 1
			--AND [VR].[Deleted] = 0
				[S].[SiteOnline] <= [VR].[VisitDate]
			--AND (@xEDISID IS NULL OR [S].[EDISID] = @xEDISID)
			--AND [VR].[VisitOutcomeID] IN 
			--    (1,2,7,9,11) 
				/*
				 1  - Buying-out - full admission (lessee), 
				 2  - Buying-out - full admission (not lessee), 
				 7  - Tampering found - full admission, 
				 9  - Tampering found - no admission (admitted buying out), 
				 11 - Buying-out & Tampering - Full admission
				 */
			AND [VR].[VisitDate] >= @xFrom -- Anything earlier is irrelevant 
			AND [VR].[VisitDate] <= @xTo-- Anything later is not yet relevant
			GROUP BY 
				[VR].[EDISID]
			) AS [VR] ON [S].[EDISID] = [VR].[EDISID]
		LEFT JOIN (
			SELECT
				[SC].[EDISID],
				MAX(CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, [SC].[Date]), 0) AS DATE)) AS [WeekCommencing]
			FROM [dbo].[SiteComments] AS [SC]
			WHERE 
				[SC].[HeadingType] IN (3004) -- Change of Tenancy  (16 also exists, but doesn't appear to be used anymore?)
			AND [SC].[Date] >= @xFrom -- Anything earlier is irrelevant
			AND [SC].[Date] <= @xTo -- Anything later is not yet relevant
			GROUP BY 
				[SC].[EDISID]
			) AS [COT] ON [S].[EDISID] = [COT].[EDISID]
		LEFT JOIN (
			SELECT 
				[S].[EDISID],
				MAX([MD].[Date]) AS [LatestStock]
			FROM [dbo].[Sites] AS [S]
			JOIN [dbo].[MasterDates] AS [MD] ON [S].[EDISID] = [MD].[EDISID]
			JOIN [dbo].[Stock] AS [St] ON [MD].[ID] = [St].[MasterDateID] 
			WHERE ([MD].[Date] >= @MinStock AND [MD].[Date] <= @xTo)
			AND [MD].[Date] >= [S].[SiteOnline]
			GROUP BY [S].[EDISID]
			) AS [CurrentStock] ON [S].[EDISID] = [CurrentStock].[EDISID]
		JOIN @PrimaryEDIS AS PrimarySites ON [S].EDISID = PrimarySites.EDISID
		WHERE 
			([S].[EDISID] = @xEDISID OR @xEDISID IS NULL)
END 


/* For Testing */
--SELECT * FROM @SiteDates

INSERT INTO @SiteProductStock ([EDISID], [ProductID], [BeforeDelivery], [IsCask], [Stock], [WeekCommencing])
SELECT
    [S].[EDISID],
    [St].[ProductID],
    [St].[BeforeDelivery],
    [P].[IsCask],
    [St].[Quantity],
    CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, [MD].[Date]), 0) AS DATE) AS [WeekCommencing]
FROM [dbo].[Stock] AS [St]
JOIN [dbo].[MasterDates] AS [MD] ON [St].[MasterDateID] = [MD].[ID]
JOIN (
    SELECT 
        [S].[EDISID],
        MAX([MD].[Date]) AS [StockDate]
    FROM [dbo].[Sites] AS [S]
    JOIN [dbo].[MasterDates] AS [MD] ON [S].[EDISID] = [MD].[EDISID]
    JOIN [dbo].[Stock] AS [St] ON [MD].[ID] = [St].[MasterDateID] 
    JOIN @PrimaryEDIS AS PrimarySites ON [S].EDISID = PrimarySites.EDISID
    WHERE ([MD].[Date] >= @MinStock AND [MD].[Date] <= @xTo)
	AND [MD].[Date] >= [S].[SiteOnline]
    AND ([S].[EDISID] = @xEDISID OR @xEDISID IS NULL)
    GROUP BY [S].[EDISID]
) AS [S] ON [MD].[EDISID] = [S].[EDISID]
JOIN [dbo].[Sites] AS [Si] ON [S].[EDISID] = [Si].[EDISID]
JOIN [dbo].[Products] AS [P] ON [St].[ProductID] = [P].[ID]
WHERE 
    [S].[StockDate] = [MD].[Date]

/* Sites and Stock
   **************************************************************************************************************************************************
*/

/* For Testing */
--SELECT [SPS].* , [P].[Description]
--FROM @SiteProductStock [SPS]
--JOIN [dbo].[Products] [P] ON [SPS].[ProductID] = [P].[ID]
--ORDER BY [P].[Description]

/* **************************************************************************************************************************************************
   Product Ties

   We calculate what the correct Tie status for each product should be while taking into account and site specific overrides.
   As the existing software/reports have no concept of historical tie, we override the values stored in the PeriodCacheVariance table as 
   it's possible for it to have inconsistent results depending on the date ranges being refreshed versus those being reported on.
*/

INSERT INTO @ProductTies
    ([ProductID], [IsTied])
SELECT
    [P].[ID],
    COALESCE([SP].[Tied], [SPC].[Tied], [P].[Tied]) AS [Tied]
    --[P].[Tied] AS [ProductTied],
    --[SPC].[Tied] AS [SiteCategoryTied],
    --[SP].[Tied] AS [SiteProductTied]
FROM [dbo].[Products] AS [P]
LEFT JOIN [dbo].[SiteProductCategoryTies] AS [SPC] 
    ON [P].[CategoryID] = [SPC].[ProductCategoryID]
    AND [SPC].[EDISID] = @xEDISID
LEFT JOIN [dbo].[SiteProductTies] AS [SP]
    ON [P].[ID] = [SP].[ProductID]
    AND [SP].[EDISID] = @xEDISID
ORDER BY [P].[Description]


/* For Testing */
--SELECT * FROM @ProductTies AS [PT] JOIN Products ON [PT].[ProductID] = Products.ID

/* Product Ties
   **************************************************************************************************************************************************
*/

;WITH cte_WeekStock AS (
	--If there have been multiple stock takes in the same week we only keep the newest
	SELECT EDISID, ProductID, Date, CASE [Hour] WHEN 0 THEN 7 ELSE [Hour] END AS Hour, BeforeDelivery, (Quantity*8) AS Quantity, IsAudited
	FROM (
		SELECT COALESCE(PrimarySites.PrimaryEDISID, MasterDates.EDISID) AS EDISID, COALESCE(PrimaryProducts.PrimaryProductID, Stock.ProductID) AS ProductID, DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 1, MasterDates.Date))) AS WeekCommencing, 
		RANK() OVER (PARTITION BY COALESCE(PrimarySites.PrimaryEDISID, MasterDates.EDISID), DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 1, MasterDates.Date))) ORDER BY Date DESC) AS Ranked,
		Date, Stock.Hour, BeforeDelivery, SUM(Stock.Quantity) AS Quantity, CASE WHEN MasterDates.Date < @WebAudit THEN 1 ELSE 0 END AS IsAudited
		FROM Stock
		JOIN MasterDates ON MasterDates.ID = MasterDateID  
        JOIN @Sites AS Sites ON Sites.EDISID = MasterDates.EDISID
        JOIN @SiteDates AS [S] ON Sites.[EDISID] = [S].[EDISID]
		LEFT JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = Stock.ProductID 
		LEFT JOIN @PrimaryEDIS AS PrimarySites ON MasterDates.EDISID = PrimarySites.EDISID
        WHERE (MasterDates.Date BETWEEN 
            CASE WHEN ISNULL([S].[StockWC], @xFrom) > @xFrom THEN @xFrom ELSE ISNULL([S].[StockWC], @xFrom) END 
            AND 
            @xTo)
		GROUP BY COALESCE(PrimarySites.PrimaryEDISID, MasterDates.EDISID), COALESCE(PrimaryProducts.PrimaryProductID, Stock.ProductID), DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 1, MasterDates.Date))), Date, Hour, BeforeDelivery
	) AS OrderedStock
	WHERE Ranked = 1
	
), cte_BlankStock AS (
	--If there has been a stock take at the site but no row for a product we need to add a dummy zero row
	SELECT EDISID, Date, CASE MAX(Hour) WHEN 0 THEN 7 ELSE MAX(Hour) END AS Hour, MAX(BeforeDelivery+0) AS BeforeDelivery, SUM(0) AS Quantity, IsAudited
	FROM (
		SELECT COALESCE(PrimarySites.PrimaryEDISID, MasterDates.EDISID) AS EDISID, DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 1, MasterDates.Date))) AS WeekCommencing, 
		RANK() OVER (PARTITION BY COALESCE(PrimarySites.PrimaryEDISID, MasterDates.EDISID), DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 1, MasterDates.Date))) ORDER BY Date DESC) AS Ranked,
		Date, Stock.Hour, BeforeDelivery, CASE WHEN MasterDates.Date < @WebAudit THEN 1 ELSE 0 END AS IsAudited
		FROM Stock 
		JOIN MasterDates ON MasterDates.ID = Stock.MasterDateID  
        JOIN @Sites AS Sites ON Sites.EDISID = MasterDates.EDISID
        JOIN @SiteDates AS [S] ON Sites.[EDISID] = [S].[EDISID]
		LEFT JOIN @PrimaryEDIS AS PrimarySites ON MasterDates.EDISID = PrimarySites.EDISID
        WHERE (MasterDates.Date BETWEEN 
            CASE WHEN ISNULL([S].[StockWC], @xFrom) > @xFrom THEN @xFrom ELSE ISNULL([S].[StockWC], @xFrom) END 
            AND 
            @xTo)
		GROUP BY COALESCE(PrimarySites.PrimaryEDISID, MasterDates.EDISID), DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 1, MasterDates.Date))), Date, Hour, BeforeDelivery
	) AS OrderedStock
	WHERE Ranked = 1
	GROUP BY EDISID, Date, IsAudited
)

INSERT INTO #PeriodVarianceInternal
(EDISID, WeekCommencing, ProductID, IsTied, Delivered, Dispensed, Variance, StockDate, Stock, StockAdjustedDelivered, StockAdjustedDispensed, StockAdjustedVariance, IsAudited)	
SELECT	Cache.EDISID, WeekDate, Cache.ProductID,
		COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) AS IsTied,
		ISNULL(SUM(Delivered), 0) AS Delivered, 
		ISNULL(SUM(Dispensed), 0) AS Dispensed, 
		ISNULL(SUM(Delivered), 0) - ISNULL(SUM(Dispensed), 0) AS Variance,
		MAX(StockDate) AS StockDate, 
		MAX(Stock) AS Stock, 
		ISNULL(MAX(Stock) + SUM(DeliveryAfterStockTake), SUM(Delivered)) AS StockAdjustedDelivered,
		CASE WHEN MAX(StockDate) IS NULL THEN SUM(Dispensed) ELSE ISNULL(SUM(StockAdjustedDispense), 0) END AS StockAdjustedDispense,
		(
			ISNULL(MAX(Stock) + SUM(DeliveryAfterStockTake), SUM(Delivered)) -
			CASE WHEN MAX(StockDate) IS NULL THEN SUM(Dispensed) ELSE ISNULL(SUM(StockAdjustedDispense), 0) END
		) AS StockAdjustedVariance,
		IsAudited
        /* For Testing */
        --,SUM(DeliveryAfterStockTake) AS DeliveryAfterStockTake,SUM(DeliveryBeforeStockTake) AS DeliveryBeforeStockTake
	    	
FROM(
--DELIVERY AND STOCK
	SELECT DeliveredAndStock.EDISID,
		   DeliveredAndStock.WeekDate,
		   DeliveredAndStock.ProductID,
		   DeliveredAndStock.Delivered,
		   DeliveredAndStock.DeliveryDate,
		   DeliveredAndStock.Dispensed,
		   DeliveredAndStock.StockDate,
		   DeliveredAndStock.Stock,
		   DeliveredAndStock.BeforeDelivery,
		   SUM(0) AS StockAdjustedDispense,
		   CASE WHEN StockDate IS NULL THEN NULL ELSE
				CASE WHEN ( (DeliveryDate < StockDate) OR (DeliveryDate = StockDate AND BeforeDelivery = 0) ) AND @AccurateDeliveryProvided = 1
				THEN DeliveredAndStock.Delivered
				WHEN (BeforeDelivery = 0) AND @AccurateDeliveryProvided = 0
				THEN DeliveredAndStock.Delivered
				ELSE 0
				END
			END AS DeliveryBeforeStockTake,
		   CASE WHEN StockDate IS NULL THEN NULL ELSE
				CASE WHEN ( (DeliveryDate > StockDate) OR (DeliveryDate = StockDate AND BeforeDelivery = 1) ) AND @AccurateDeliveryProvided = 1
				THEN DeliveredAndStock.Delivered
				WHEN (BeforeDelivery = 1) AND @AccurateDeliveryProvided = 0
				THEN DeliveredAndStock.Delivered
				ELSE 0
				END
			END AS DeliveryAfterStockTake,		
			IsAudited
	FROM (
		--SELECT DELIVERY DATA WITH ANY DUMMY STOCK ROWS
		SELECT EDISID, WeekDate, EOW, ProductID, SUM(Delivered) AS Delivered, 
			   DeliveryDate, SUM(Dispensed) AS Dispensed, 
			   MAX(StockDate) AS StockDate, SUM(Stock) AS Stock, MAX(BeforeDelivery+0) AS BeforeDelivery, 
			   SUM(StockAdjustedDispense) AS StockAdjustedDispense, IsAudited
		FROM (
			SELECT  COALESCE(PrimarySites.EDISID, MasterDates.EDISID) AS EDISID,
					DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 1, MasterDates.Date))) As WeekDate,
					DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 7, MasterDates.Date))) As EOW,
					COALESCE(PrimaryProducts.PrimaryProductID, Delivery.Product) AS ProductID,
					SUM(Delivery.Quantity + 0.0) * 8.0 AS Delivered,
					MasterDates.Date AS DeliveryDate,
					SUM(0) AS Dispensed,
					COALESCE(SiteStock.Date, DummyStock.Date) AS StockDate,
					COALESCE(SiteStock.Hour, DummyStock.Hour) AS StockHour,
					DummyStock.Quantity AS Stock,
					COALESCE(SiteStock.BeforeDelivery, DummyStock.BeforeDelivery) AS BeforeDelivery,
					SUM(0) AS StockAdjustedDispense,
					CASE WHEN MasterDates.Date < @WebAudit THEN 1 ELSE 0 END AS IsAudited
			FROM MasterDates
            JOIN @Sites AS CurrentSites ON CurrentSites.EDISID = MasterDates.EDISID
			JOIN Sites ON Sites.EDISID = MasterDates.EDISID 
            JOIN @SiteDates AS [S] ON Sites.[EDISID] = [S].[EDISID]
			JOIN Delivery ON Delivery.DeliveryID = MasterDates.ID
			LEFT JOIN Products ON Products.[ID] = Delivery.Product
			LEFT JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = Products.ID
			LEFT JOIN @PrimaryEDIS AS PrimarySites ON MasterDates.EDISID = PrimarySites.EDISID
			LEFT JOIN cte_WeekStock AS SiteStock ON DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 1, MasterDates.Date)))
													= DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, SiteStock.Date) + 1, SiteStock.Date)))
												 AND COALESCE(PrimarySites.EDISID, MasterDates.EDISID) = SiteStock.EDISID
												 AND COALESCE(PrimaryProducts.PrimaryProductID, Delivery.Product) = SiteStock.ProductID
												 
			LEFT JOIN cte_BlankStock AS DummyStock ON DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 1, MasterDates.Date)))
												     = DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, DummyStock.Date) + 1, DummyStock.Date)))
												  AND COALESCE(PrimarySites.EDISID, MasterDates.EDISID) = DummyStock.EDISID
            WHERE (MasterDates.Date BETWEEN 
                    CASE WHEN ISNULL([S].[StockWC], @xFrom) > @xFrom THEN @xFrom ELSE ISNULL([S].[StockWC], @xFrom) END 
                    AND 
                    @xTo)
            AND (@xIncludeCasks = 1 OR [IsCask] = 0) -- Also disables Consolidated Casks
            AND (@xIncludeKegs = 1 OR ([IsCask] = 1 OR [IsMetric] = 1))
            AND (@xIncludeMetric = 1 OR [IsMetric] = 0)
			GROUP BY COALESCE(PrimarySites.EDISID, MasterDates.EDISID),
					MasterDates.Date,
					COALESCE(PrimaryProducts.PrimaryProductID, Delivery.Product),
					COALESCE(SiteStock.Date, DummyStock.Date),
					COALESCE(SiteStock.Hour, DummyStock.Hour),
					DummyStock.Quantity,
					COALESCE(SiteStock.BeforeDelivery, DummyStock.BeforeDelivery),
					CASE WHEN MasterDates.Date < @WebAudit THEN 1 ELSE 0 END
					
			UNION
			--SELECT ANY ACTUAL STOCK ROWS
			SELECT  WeekStock.EDISID,
					DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, WeekStock.Date) + 1, WeekStock.Date))) As WeekDate,
					DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, WeekStock.Date) + 7, WeekStock.Date))) As EOW,
					ProductID,
					SUM(0) AS Delivered,
					NULL AS DeliveryDate,
					SUM(0) AS Dispensed,
					WeekStock.Date AS StockDate,
					WeekStock.Hour AS StockHour,
					SUM(WeekStock.Quantity) AS Stock,
					WeekStock.BeforeDelivery AS BeforeDelivery,
					SUM(0) AS StockAdjustedDispense,
					IsAudited
			FROM cte_WeekStock AS WeekStock
			GROUP BY WeekStock.EDISID,
					WeekStock.Date,
					WeekStock.Hour,
					WeekStock.BeforeDelivery,
					WeekStock.ProductID,
					WeekStock.IsAudited
		) AS UngroupedDeliveryAndStock
		GROUP BY EDISID, ProductID, WeekDate, EOW, DeliveryDate, IsAudited
	) AS DeliveredAndStock	
	GROUP BY DeliveredAndStock.EDISID,
		   DeliveredAndStock.WeekDate,
		   DeliveredAndStock.ProductID,
		   DeliveredAndStock.Delivered,
		   DeliveredAndStock.DeliveryDate,
		   DeliveredAndStock.Dispensed,
		   DeliveredAndStock.StockDate,
		   DeliveredAndStock.Stock,
		   DeliveredAndStock.BeforeDelivery,
		   DeliveredAndStock.IsAudited

	UNION
	--DISPENSE WITH DUMMY STOCK INFO AND DISPENSE SINCE STOCKDATE VALUE
	SELECT  COALESCE(PrimarySites.EDISID, MasterDates.EDISID) AS EDISID,
			DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 1, MasterDates.Date))) As WeekDate,
			COALESCE(PrimaryProducts.PrimaryProductID, DLData.Product) AS ProductID,
			SUM(0) AS Delivered,
			NULL AS DeliveryDate,
			SUM(DLData.Quantity) AS Dispensed,
			COALESCE(SiteStock.Date, DummyStock.Date) AS StockDate,
			COALESCE(SiteStock.Quantity, DummyStock.Quantity) AS Stock,
			COALESCE(SiteStock.BeforeDelivery, DummyStock.BeforeDelivery) AS BeforeDelivery,
			StockDisp.Dispensed AS StockAdjustedDispense,
			SUM(0) AS DeliveryBeofreStockTake,
			SUM(0) AS DeliveryAfterStockTake,
			CASE WHEN MasterDates.Date < @WebAudit THEN 1 ELSE 0 END AS IsAudited
	FROM MasterDates
    JOIN @Sites AS CurrentSites ON CurrentSites.EDISID = MasterDates.EDISID
	JOIN Sites ON Sites.EDISID = MasterDates.EDISID  
    JOIN @SiteDates AS [S] ON Sites.[EDISID] = [S].[EDISID]
	LEFT JOIN @PrimaryEDIS AS PrimarySites ON MasterDates.EDISID = PrimarySites.EDISID
	JOIN DLData ON DLData.DownloadID = MasterDates.ID
	LEFT JOIN Products ON Products.[ID] = DLData.Product
	LEFT JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = Products.ID
	LEFT JOIN cte_WeekStock AS SiteStock ON DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 1, MasterDates.Date)))
											= DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, SiteStock.Date) + 1, SiteStock.Date)))
										 AND COALESCE(PrimarySites.EDISID, MasterDates.EDISID) = SiteStock.EDISID
										 AND COALESCE(PrimaryProducts.PrimaryProductID, DLData.Product) = SiteStock.ProductID
										 
	LEFT JOIN cte_BlankStock AS DummyStock ON DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 1, MasterDates.Date)))
											  = DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, DummyStock.Date) + 1, DummyStock.Date)))
										   AND COALESCE(PrimarySites.EDISID, MasterDates.EDISID) = DummyStock.EDISID
												  
	LEFT JOIN (--DISPENSE BETWEEN STOCK TAKE AND END OF WEEK
		SELECT EDISID, ProductID, EOW,
			   SUM(Dispensed) AS Dispensed
		FROM (
			SELECT  COALESCE(PrimarySites.EDISID, MasterDates.EDISID) AS EDISID,
					MasterDates.Date,
					(DLData.Shift - 1) AS Hour,
					DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 7, MasterDates.Date))) As EOW,
					COALESCE(PrimaryProducts.PrimaryProductID, DLData.Product) AS ProductID,
					SUM(DLData.Quantity) AS Dispensed,
					COALESCE(SiteStock.Date, DummyStock.Date) AS SiteStockDate,
					COALESCE(SiteStock.Hour, DummyStock.Hour) AS SiteStockHour,
					CASE WHEN MasterDates.Date < @WebAudit THEN 1 ELSE 0 END AS IsAudited
			FROM MasterDates
            JOIN @Sites AS CurrentSites ON CurrentSites.EDISID = MasterDates.EDISID
			JOIN Sites ON Sites.EDISID = MasterDates.EDISID  
            JOIN @SiteDates AS [S] ON Sites.[EDISID] = [S].[EDISID]
			JOIN DLData ON DLData.DownloadID = MasterDates.ID
			LEFT JOIN Products ON Products.[ID] = DLData.Product
			LEFT JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = Products.ID
			LEFT JOIN @PrimaryEDIS AS PrimarySites ON MasterDates.EDISID = PrimarySites.EDISID
												   
			LEFT JOIN cte_WeekStock AS SiteStock ON DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 1, MasterDates.Date)))
													= DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, SiteStock.Date) + 1, SiteStock.Date)))
												 AND COALESCE(PrimarySites.EDISID, MasterDates.EDISID) = SiteStock.EDISID
												 AND COALESCE(PrimaryProducts.PrimaryProductID, DLData.Product) = SiteStock.ProductID
												 
			LEFT JOIN cte_BlankStock AS DummyStock ON DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 1, MasterDates.Date)))
											  = DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, DummyStock.Date) + 1, DummyStock.Date)))
										   AND COALESCE(PrimarySites.EDISID, MasterDates.EDISID) = DummyStock.EDISID
			
			WHERE (
				(MasterDates.Date > COALESCE(SiteStock.Date, DummyStock.Date) OR COALESCE(SiteStock.Date, DummyStock.Date) IS NULL) 
				OR (COALESCE(SiteStock.Date, DummyStock.Date) = MasterDates.Date AND (DLData.Shift - 1) > COALESCE(SiteStock.Hour, DummyStock.Hour))
			    )
            AND (MasterDates.Date BETWEEN 
                    CASE WHEN ISNULL([S].[StockWC], @xFrom) > @xFrom THEN @xFrom ELSE ISNULL([S].[StockWC], @xFrom) END 
                    AND 
                    @xTo)
				
			GROUP BY COALESCE(PrimarySites.EDISID, MasterDates.EDISID),
					MasterDates.Date,
					DLData.Shift,
					DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 7, MasterDates.Date))), 
					COALESCE(PrimaryProducts.PrimaryProductID, DLData.Product),
					COALESCE(SiteStock.Date, DummyStock.Date),
					COALESCE(SiteStock.Hour, DummyStock.Hour),
					CASE WHEN MasterDates.Date < @WebAudit THEN 1 ELSE 0 END 
		) AS DispenseSinceStock
		GROUP BY EDISID, ProductID, EOW 
				
	) AS StockDisp ON COALESCE(PrimarySites.EDISID, MasterDates.EDISID) = StockDisp.EDISID
				   AND COALESCE(PrimaryProducts.PrimaryProductID, DLData.Product) = StockDisp.ProductID
				   AND DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 7, MasterDates.Date))) = StockDisp.EOW											  
	WHERE (MasterDates.Date BETWEEN 
                    CASE WHEN ISNULL([S].[StockWC], @xFrom) > @xFrom THEN @xFrom ELSE ISNULL([S].[StockWC], @xFrom) END 
                    AND 
                    @xTo) 
    GROUP BY COALESCE(PrimarySites.EDISID, MasterDates.EDISID),
			DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 1, MasterDates.Date))),
			COALESCE(PrimaryProducts.PrimaryProductID, DLData.Product),
			COALESCE(SiteStock.Date, DummyStock.Date),
			COALESCE(SiteStock.Quantity, DummyStock.Quantity),
			COALESCE(SiteStock.BeforeDelivery, DummyStock.BeforeDelivery),
			StockDisp.Dispensed,
			CASE WHEN MasterDates.Date < @WebAudit THEN 1 ELSE 0 END
            
) AS Cache
JOIN @Sites AS Sites ON Sites.EDISID = Cache.EDISID
JOIN Products ON Products.ID = Cache.ProductID
LEFT JOIN SiteProductCategoryTies ON SiteProductCategoryTies.ProductCategoryID = Products.CategoryID AND Cache.EDISID = SiteProductCategoryTies.EDISID
LEFT JOIN SiteProductTies ON SiteProductTies.ProductID = Products.ID AND Cache.EDISID = SiteProductTies.EDISID
/* For Testing */
--WHERE Cache.[ProductID] = 4443
GROUP BY Cache.EDISID, 
		 WeekDate,
		 Cache.ProductID,
		 COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied),
		 IsAudited
		 

/* For Testing */
--SELECT 
--    [Products].[Description] AS [Product],
--    [PVI].*
--FROM #PeriodVarianceInternal AS [PVI]
--JOIN [dbo].[Products] ON [PVI].[ProductID] = [Products].[ID]
----WHERE [PVI].[ProductID] = 4443
--ORDER BY 
--    EDISID, 
--    WeekCommencing, 
--    ProductID

/* **************************************************************************************************************************************************
   Stock Variance
*/
DECLARE @StockVariance TABLE ([EDISID] INT NOT NULL, [WeekCommencing] DATE NOT NULL, [StockVariance] FLOAT, [StockCumulativeVariance] FLOAT, [ProductType] INT, [UsableStockDate] DATE)

INSERT INTO @StockVariance ([EDISID], [WeekCommencing], [StockVariance], [ProductType], [UsableStockDate])
SELECT -- Consolidated "Everything"
    [Consolidated].[EDISID],
    [Consolidated].[WeekCommencing],
    --[Consolidated].[Delivered],
    --[Consolidated].[AdjustedDelivered],
    --[Consolidated].[Dispensed],
    --[Consolidated].[AdjustedDispensed],
    --[Consolidated].[Stock],
    --[Consolidated].[StockBeforeDelivery],
    --[Consolidated].[StockAfterDelivery],
    [Consolidated].[StockVariance],
    --CASE WHEN [WeekCommencing] = [S].[StockWC] 
    --     THEN CASE WHEN [SPS].[BeforeDelivery] = 0
    --               THEN [StockAfterDelivery] 
    --               ELSE [StockBeforeDelivery] + [Delivered] END - [AdjustedDispensed]
    --      ELSE [StockVariance]
    --END AS [StockVariance],
    1 AS [ProductType],
    CASE WHEN @xFrom >= COALESCE([S].[VisitDate], @xFrom) AND @xFrom >= COALESCE([S].[COTDate], @xFrom)
         THEN @xFrom
         WHEN [S].[VisitDate] >= COALESCE([S].[COTDate], [S].[VisitDate])
         THEN [S].[VisitDate]
         ELSE [S].[COTDate]
         END AS [UsableStockDate]
FROM (
    SELECT
        [PCVI].[EDISID],
        [PCVI].[WeekCommencing],
        --[P].[Description] AS [Product],
        SUM([PCVI].[Delivered] * @ToGallons) AS [Delivered],
        SUM([PCVI].[StockAdjustedDelivered] * @ToGallons) AS [AdjustedDelivered],
        SUM([PCVI].[Dispensed] * @ToGallons) AS [Dispensed],
        SUM([PCVI].[StockAdjustedDispensed] * @ToGallons) AS [AdjustedDispensed],
        SUM(CASE WHEN [PCVI].[WeekCommencing] >= [S].[StockWC] -- Only use the current Stock Take
                 THEN [PCVI].[Stock] * @ToGallons
                 ELSE NULL END) AS [Stock],
        [SPS].[StockAfterDelivery],
        [SPS].[StockBeforeDelivery],
        SUM([PCVI].[StockAdjustedVariance] * @ToGallons) AS [StockVariance]
    FROM #PeriodVarianceInternal AS [PCVI]
    JOIN @SiteDates AS [S] ON [PCVI].[EDISID] = [S].[EDISID]
    JOIN [dbo].[Sites] AS [Si] ON [S].[EDISID] = [Si].[EDISID]
    JOIN [dbo].[Products] AS [P] ON [PCVI].[ProductID] = [P].[ID]
    JOIN (
        SELECT
            [EDISID],
            SUM(CASE WHEN [BeforeDelivery] = 1 THEN [Stock] ELSE 0 END) AS [StockBeforeDelivery],
            SUM(CASE WHEN [BeforeDelivery] = 0 THEN [Stock] ELSE 0 END) AS [StockAfterDelivery]
        FROM @SiteProductStock AS [SPS]
        GROUP BY 
            [EDISID]
        ) AS [SPS] ON [S].[EDISID] = [SPS].[EDISID]
    WHERE (@xEDISID IS NULL OR [PCVI].[EDISID] = @xEDISID)
    AND [Si].[Status] NOT IN (2, 10) -- Closed & Free-of-Tie
    AND [PCVI].[WeekCommencing] BETWEEN [S].[StockWC] AND @xTo
    AND [PCVI].[IsTied] = 1 -- Exclude Untied
    AND [P].[IsWater] = 0 -- Used to filter out corrupted data (discovered in some UAT databases)
    --AND [P].[Description] = 'Consolidated Casks' /* For Testing */
    GROUP BY
        [PCVI].[EDISID],
        [PCVI].[WeekCommencing],
        [SPS].[StockAfterDelivery],
        [SPS].[StockBeforeDelivery]--,
        --[S].[StockDate]
    --    [P].[Description]
    ) AS [Consolidated]
JOIN @SiteDates AS [S] ON [Consolidated].[EDISID] = [S].[EDISID]
JOIN [dbo].[Sites] AS [Si] ON [S].[EDISID] = [Si].[EDISID]
JOIN (
    SELECT
        [EDISID],
        CAST(MAX(CAST([BeforeDelivery] AS INT)) AS BIT) AS [BeforeDelivery] -- Consolidated can't mix this as dispense isn't seperate, so use it if any related product has it enabled
    FROM @SiteProductStock AS [SPS]
    GROUP BY 
        [EDISID]) AS [SPS] ON [S].[EDISID] = [SPS].[EDISID]

/* Calculate Cumulative Stock */
UPDATE [SV_Core]
SET [StockCumulativeVariance] = [SV_CV].[StockCumulativeVariance]
FROM @StockVariance AS [SV_Core]
JOIN (
    SELECT
        [SV].[WeekCommencing],
        [SV].[StockVariance],
        SUM([SV_Prev].[StockVariance]) AS [StockCumulativeVariance]
    FROM @StockVariance AS [SV]
    LEFT JOIN @StockVariance AS [SV_Prev] ON [SV].[WeekCommencing] >= [SV_Prev].[WeekCommencing]
    GROUP BY 
        [SV].[WeekCommencing],
        [SV].[StockVariance]
    --ORDER BY 
    --    [SV].[Product], 
    --    [SV].[WeekCommencing]
    ) AS [SV_CV]
      ON [SV_Core].[WeekCommencing] = [SV_CV].[WeekCommencing]

/*
UPDATE [SV1]
SET [StockCumulativeVariance] = ISNULL([SV1].[StockCumulativeVariance], [SV1].[StockVariance]) + [SV2].[StockVariance]
FROM @StockVariance AS [SV1]
JOIN @StockVariance AS [SV2] ON [SV1].[WeekCommencing] = DATEADD(WEEK, +1, [SV2].[WeekCommencing]) AND [SV1].[ProductID] = [SV2].[ProductID]
*/

/* For Testing */
--SELECT * FROM @StockVariance

/* Stock Variance
   **************************************************************************************************************************************************
*/


/* **************************************************************************************************************************************************
   Consolidated

   We add variance data for two new "fake" products for "Tied Consolidated Draught" (Cask, Keg) and "Tied Consolidated Post-Mix" (Metric).
   We mark these rows with the IsConsolidated column.
   IsCask/IsKeg cannot be trusted as the data for them is combined. IsMetric can be relied upon.
*/

---- Draught
--INSERT INTO @Variance
--    ([WeekCommencing], [Product], [ProductCategory], [IsCask], [IsKeg], [IsMetric], [Dispensed], [Delivered], [Variance], [Stock], [StockVariance], [IsTied], [IsConsolidated])
--SELECT
--    [PeriodCacheVarianceInternal].[WeekCommencing] AS [WeekCommencing], 
--    'Tied Consolidated Draught' AS [Product], 
--    'N/A' AS [Category],
--	1 AS [IsCask],
--    1 AS [IsKeg], 
--	0 AS [IsMetric],
--    SUM([PeriodCacheVarianceInternal].[Dispensed]) * @ToGallons AS [Dispensed],
--	SUM([PeriodCacheVarianceInternal].[Delivered]) * @ToGallons AS [Delivered],
--	SUM([PeriodCacheVarianceInternal].[Variance]) * @ToGallons AS [Variance],
--    -1,--[SPS].[Stock],
--    -1,--[SV].[StockVariance],
--	1 AS [IsTied],
--    1 AS [IsConsolidated]
--FROM [PeriodCacheVarianceInternal]
--JOIN @SiteDates AS [S] ON [PeriodCacheVarianceInternal].[EDISID] = [S].[EDISID]
--JOIN [Products] ON [PeriodCacheVarianceInternal].[ProductID] = [Products].[ID]
--JOIN [ProductCategories] ON [Products].[CategoryID] = [ProductCategories].[ID]
--JOIN @ProductTies AS [ProductTies] ON [Products].[ID] = [ProductTies].[ProductID]
--WHERE [PeriodCacheVarianceInternal].[EDISID] = @xEDISID
--    AND [Products].[IsMetric] = 0
--    AND [PeriodCacheVarianceInternal].[WeekCommencing] BETWEEN [S].[StockWC] AND @xTo
--    AND [ProductTies].[IsTied] = 1
--GROUP BY
--    [PeriodCacheVarianceInternal].[WeekCommencing]

-- Consolidated
INSERT INTO @Variance
    ([WeekCommencing], [IsCask], [IsKeg], [IsMetric], [Dispensed], [Delivered], [Variance], [Stock], [StockVariance], [CumulativeStockVariance], [IsTied], [IsConsolidated], [IsAdjusted])
SELECT
    [PeriodCacheVarianceInternal].[WeekCommencing] AS [WeekCommencing], 
	1 AS [IsCask],
    1 AS [IsKeg], 
	1 AS [IsMetric],
    SUM([PeriodCacheVarianceInternal].[Dispensed]) * @ToGallons AS [Dispensed],
	SUM([PeriodCacheVarianceInternal].[Delivered]) * @ToGallons AS [Delivered],
	SUM([PeriodCacheVarianceInternal].[Variance]) * @ToGallons AS [Variance],
    AVG([SPS].[Stock]),
    AVG([SV].[StockVariance]),
    AVG([SV].[StockCumulativeVariance]),
	1 AS [IsTied],
    1 AS [IsConsolidated],
    0 AS [IsAdjusted]
FROM #PeriodVarianceInternal AS [PeriodCacheVarianceInternal]
JOIN @SiteDates AS [S] ON [PeriodCacheVarianceInternal].[EDISID] = [S].[EDISID]
JOIN [Products] ON [PeriodCacheVarianceInternal].[ProductID] = [Products].[ID]
JOIN [ProductCategories] ON [Products].[CategoryID] = [ProductCategories].[ID]
JOIN @ProductTies AS [ProductTies] ON [Products].[ID] = [ProductTies].[ProductID]
LEFT JOIN (
    SELECT
        [WeekCommencing],
        SUM([Stock]) AS [Stock],
        SUM(CASE WHEN [BeforeDelivery] = 1 THEN [Stock] ELSE 0 END) AS [StockBeforeDelivery],
        SUM(CASE WHEN [BeforeDelivery] = 0 THEN [Stock] ELSE 0 END) AS [StockAfterDelivery]
    FROM @SiteProductStock AS [SPS]
    --WHERE [IsCask] = 1
    GROUP BY 
        [WeekCommencing]
    ) AS [SPS] ON [PeriodCacheVarianceInternal].[WeekCommencing] = [SPS].[WeekCommencing]
LEFT JOIN @StockVariance AS [SV] ON [S].[EDISID] = [SV].[EDISID] AND [PeriodCacheVarianceInternal].[WeekCommencing] = [SV].[WeekCommencing]
WHERE ([PeriodCacheVarianceInternal].[EDISID] = @xEDISID OR @xEDISID IS NULL) -- If we allow NULLs here then the data in the table must always be relevant, drop this clause?
    AND [PeriodCacheVarianceInternal].[WeekCommencing] 
        BETWEEN 
            CASE WHEN ISNULL([S].[StockWC], @xFrom) > @xFrom THEN @xFrom ELSE ISNULL([S].[StockWC], @xFrom) END
        AND 
            @xTo
    AND [ProductTies].[IsTied] = 1
GROUP BY
    [PeriodCacheVarianceInternal].[WeekCommencing]

--SELECT * FROM @Variance

/* Consolidated
   **************************************************************************************************************************************************
*/

-- Fill any gaps where Products are missing weeks (Trend Period only)
INSERT INTO @Variance
    ([WeekCommencing], [IsCask], [IsKeg], [IsMetric], [Dispensed], [Delivered], [Variance], [IsTied], [IsConsolidated])
SELECT
    [Complete].[WeekCommencing],
    [Complete].[IsCask],
    [Complete].[IsKeg],
    [Complete].[IsMetric],
    0 AS [Dispensed],
    0 AS [Delivered],
    0 AS [Variance],
    [Complete].[IsTied],
    [Complete].[IsConsolidated]
FROM (
    SELECT
        [Calendar].[FirstDateOfWeek] AS [WeekCommencing],
        [Variance].[IsCask],
        [Variance].[IsKeg],
        [Variance].[IsMetric],
        [Variance].[IsTied],
        [Variance].[IsConsolidated]
    FROM (
        SELECT DISTINCT 
            [Calendar].[FirstDateOfWeek]
        FROM [Calendar]
        WHERE [FirstDateOfWeek] BETWEEN @xFrom AND @xTo
        ) AS [Calendar]
    CROSS APPLY  (
        SELECT DISTINCT 
            [IsCask],
            [IsKeg],
            [IsMetric],
            [IsTied],
            [IsConsolidated]
        FROM @Variance
        ) AS [Variance]
    ) AS [Complete]
LEFT JOIN @Variance AS [Variance]
    ON [Complete].[WeekCommencing] = [Variance].[WeekCommencing]
WHERE [Variance].[WeekCommencing] IS NULL

IF NOT EXISTS(SELECT * FROM @Variance)
BEGIN
	INSERT INTO @Variance
	([WeekCommencing], [IsCask], [IsKeg], [IsMetric], [Dispensed], [Delivered], [Variance], [IsTied], [IsConsolidated])
	SELECT
		[Calendar].[FirstDateOfWeek],
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0
	FROM
	(
		SELECT DISTINCT 
            [Calendar].[FirstDateOfWeek]
        FROM [Calendar]
        WHERE [FirstDateOfWeek] BETWEEN @xFrom AND @xTo
	) AS Calendar
END

--SELECT * FROM @Variance

/* **************************************************************************************************************************************************
   Cumulative Variance & Trend
*/


DECLARE @CurrentWC DATE
DECLARE @CurrentVariance FLOAT
DECLARE @CurrentCV FLOAT = 0
DECLARE @CurrentTrend FLOAT = 0
DECLARE @CurrentStockVariance FLOAT
DECLARE @CurrentStockCV FLOAT = 0

DECLARE @PreviousWC DATE = NULL
DECLARE @PreviousCV FLOAT = 0
DECLARE @PreviousTrend FLOAT = 0
DECLARE @PreviousStockCV FLOAT = 0

DECLARE Cursor_Variance CURSOR FAST_FORWARD FOR
SELECT 
    [V].[WeekCommencing],
    [V].[Variance],
    ISNULL([V].[StockVariance], 0)
FROM @Variance AS [V] 
ORDER BY WeekCommencing

OPEN Cursor_Variance

FETCH NEXT FROM Cursor_Variance INTO @CurrentWC, @CurrentVariance, @CurrentStockVariance

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @CurrentWC >= @xFrom -- Cumulative Variance/Trends only work within the period
    BEGIN
        SELECT
            @CurrentCV = @PreviousCV + @CurrentVariance,
            @CurrentTrend = CASE WHEN @CurrentVariance < 0                      -- Current Variance value is negative
                                 THEN @PreviousTrend + @CurrentVariance         -- Continue the Trend
                            ELSE CASE WHEN @PreviousTrend >= 0                  -- Positive Trend, detect if it has already been reset
                                      THEN @PreviousTrend + @CurrentVariance    -- Previous Trend value was positive, Continue the Trend
                                      WHEN @PreviousTrend > @TrendThreshold    -- Detect if the Trend had reached the threshold
                                      THEN @PreviousTrend + @CurrentVariance    -- Previous Trend was negative but above Threshold, Continue the Trend
                                      ELSE @CurrentVariance                     -- Previous Trend had passed threshold, Start a new Trend
                                      END
                            END 

        UPDATE @Variance 
        SET [CumulativeVariance] = @CurrentCV,
            [Trend] = @CurrentTrend,
            [Trending] = CASE WHEN @CurrentTrend <= @TrendThreshold THEN 1 ELSE 0 END
        WHERE
            [WeekCommencing] = @CurrentWC
    END

    -- Stock works over the entire available data
    SELECT 
        @CurrentStockCV = @PreviousStockCV + @CurrentStockVariance
    
    UPDATE @Variance
    SET [CumulativeStockVariance] = @CurrentStockCV
    WHERE
        [WeekCommencing] = @CurrentWC

    /* For Testing */
    --IF @CurrentProduct = 'Becks Vier'
    --BEGIN
    --    SELECT  @CurrentWC AS WC, 
    --            @CurrentProduct AS Product, 
    --            @CurrentVariance AS CV,
    --            @CurrentStandardCV AS StdCV,
    --            @PreviousStandardCV AS PrevStdCV,
    --            @CurrentStandardTrend AS StdTrend
    --END

    SELECT  @PreviousWC = @CurrentWC, 
            @PreviousCV = @CurrentCV,
            @PreviousStockCV = @CurrentStockCV,
            @PreviousTrend = @CurrentTrend

    FETCH NEXT FROM Cursor_Variance INTO @CurrentWC, @CurrentVariance, @CurrentStockVariance
END

CLOSE Cursor_Variance
DEALLOCATE Cursor_Variance

--SELECT * FROM #Variance 
--ORDER BY EDISID, Product, WeekCommencing

-- Set the Trend Totals
UPDATE [V1]
SET [V1].[TrendTotal] = 
        CASE WHEN [V1].[WeekCommencing] >=
            (CASE WHEN @xFrom >= COALESCE([S].[VisitDate], @xFrom) AND @xFrom >= COALESCE([S].[COTDate], @xFrom)
                  THEN @xFrom
                  WHEN [S].[VisitDate] >= COALESCE([S].[COTDate], [S].[VisitDate])
                  THEN [S].[VisitDate]
                  ELSE [S].[COTDate]
                  END) -- "Trend From" Date (adjusting for VRS Visit / Change of Tenancy)
             THEN CASE WHEN [V1].[Trending] = 1 AND [V2].[Trending] = 0
                       THEN [V1].[Trend]
                       ELSE NULL END
             ELSE NULL END
FROM @Variance AS [V1]
JOIN @Variance AS [V2]
    ON [V1].[WeekCommencing] = DATEADD(DAY, -7, [V2].[WeekCommencing]) -- match to the previous week
CROSS APPLY @SiteDates AS [S]

--SELECT * FROM @Variance 
--ORDER BY EDISID, Product, WeekCommencing


/*  Close hanging Trends
    Where the Trend hasn't "completed" as it's still ongoing, we manually complete the final week for the selected period.
    This could be done at the initial point of calculation but for simplicity (avoiding nested CASE statements) I'm doing it here instead
*/


UPDATE [Variance]
SET [TrendTotal] = [Trend]
FROM @Variance AS [Variance]
JOIN (  SELECT
            [PotentialHanging].[HangingTrendWeek]
        FROM (  SELECT
                    MAX([WeekCommencing]) AS [HangingTrendWeek]
                FROM @Variance AS [Variance]
                WHERE
                    [Trending] = 1
                AND [TrendTotal] IS NULL
                AND [WeekCommencing] = DATEADD(WEEK, DATEDIFF(WEEK, 6, @xTo), 0)
            ) AS [PotentialHanging]
        LEFT JOIN (  SELECT
                    MAX([WeekCommencing]) AS [CompletedTrendWeek]
                FROM @Variance
                WHERE
                    [Trending] = 1
                AND [TrendTotal] IS NOT NULL
            ) AS [CompletedTrends]
            ON DATEADD(WEEK, 1, [PotentialHanging].[HangingTrendWeek]) = [CompletedTrends].[CompletedTrendWeek]
        WHERE 
            [CompletedTrends].[CompletedTrendWeek] IS NULL
    ) AS [TrendsToClose]
    ON [Variance].[WeekCommencing] = [TrendsToClose].[HangingTrendWeek]




/*
-- Calculate the Cumulative Variance & Trend within a recursive CTE
;WITH [V] AS
(   SELECT 
        [WeekCommencing],
        [Product],
        [Variance],
        [Stock],
        [StockVariance],
        ROW_NUMBER() OVER (ORDER BY [Product], [WeekCommencing]) AS [RowNum]
    FROM @Variance
    WHERE [WeekCommencing] >= @xFrom -- Everything except for Stock needs to work within the current period
), [W] AS
(   -- Anchor Definition
    SELECT 
        [WeekCommencing],
        [V].[Product],
        [Variance],
        [Stock],
        [StockVariance],
        [StockCV] = [StockVariance],
        [V].[RowNum],
        [CV] = [Variance],
        [Trend] = [Variance]
    FROM [V]
    JOIN (  
        SELECT
            [Product],
            MIN([RowNum]) AS [RowNum]
        FROM [V]
        GROUP BY [Product]
        )
     AS [X] 
        ON [V].[RowNum] = [X].[RowNum]

    UNION ALL 

    -- Recursive Definition   V = Current, W = Previous
    SELECT
        [V].[WeekCommencing],
        [V].[Product],
        [V].[Variance],
        [V].[Stock],
        [V].[StockVariance],
        [W].[StockVariance] +
             CASE WHEN [V].[Stock] IS NULL
                  THEN ISNULL([W].[StockCV], 0) + [V].[StockVariance]
                  ELSE [W].[StockVariance]
                  END AS [StockCV],
        [V].[RowNum],
        [W].[CV] + [V].[Variance],
        CASE WHEN [V].[Variance] < 0                        -- Current Variance value is negative
             THEN [W].[Trend] + [V].[Variance]              -- Continue the Trend
             ELSE CASE WHEN [W].[Trend] >= 0                -- Positive Trend, detect if it has already been reset
                       THEN [W].[Trend] + [V].[Variance]    -- Previous Trend value was positive, Continue the Trend
                       WHEN [W].[Trend] >= -5               -- Detect if the Trend had reached the threshold
                       THEN [W].[Trend] + [V].[Variance]    -- Previous Trend was negative but above Threshold, Continue the Trend
                       ELSE [V].[Variance]                  -- Previous Trend had passed threshold, Start a new Trend
                       END
             END AS [Trend]
    FROM [W] 
    INNER JOIN [V]
        ON [V].[RowNum] = ([W].[RowNum] + 1)
       AND [V].[Product] = [W].[Product]
)
UPDATE @Variance
SET [CumulativeVariance] = [CV].[Cumulative],
    [CumulativeStockVariance] = ISNULL([CV].[StockCV], -1000),
    [Trend] = [CV].[Trend],
    [Trending] = CASE WHEN [CV].[Trend] < -@MinimumTrend THEN 1 ELSE 0 END
FROM @Variance AS [V]
JOIN (  SELECT
            [WeekCommencing],
            [Product],
            [Variance],
            [Cumulative] = [CV],
            [StockCV],
            [Trend],
            [RowNum]
        FROM [W] )
    AS [CV]
    ON [V].[WeekCommencing] = [CV].[WeekCommencing]
    AND [V].[Product] = [CV].[Product]
OPTION (MAXRECURSION 10000)

-- Set the Trend Totals
UPDATE [V1]
SET [V1].[TrendTotal] = 
        CASE WHEN [V1].[Trending] = 1 AND [V2].[Trending] = 0
             THEN [V1].[Trend]
             ELSE NULL
             END
FROM @Variance AS [V1]
JOIN @Variance AS [V2]
    ON [V1].[WeekCommencing] = DATEADD(DAY, -7, [V2].[WeekCommencing]) -- match to the previous week
    AND [V1].[Product] = [V2].[Product]

/* Cumulative Variance & Trend
   **************************************************************************************************************************************************
*/
*/

/* For Testing */
--SELECT * 
--FROM @Variance
--ORDER BY 
--    [Product],
--    [WeekCommencing]


/*  Close hanging Trends
    Where the Trend hasn't "completed" as it's still ongoing, we manually complete the final week for the selected period.
    This could be done at the initial point of calculation but for simplicity (avoiding nested CASE statements) I'm doing it here instead
*/


UPDATE [Variance]
SET [TrendTotal] = [Trend]
FROM @Variance AS [Variance]
JOIN (  SELECT
            [PotentialHanging].[HangingTrendWeek]
        FROM (  SELECT
                    MAX([WeekCommencing]) AS [HangingTrendWeek]
                FROM @Variance AS [Variance]
                WHERE
                    [Trending] = 1
                AND [TrendTotal] IS NULL
                AND [WeekCommencing] = DATEADD(WEEK, DATEDIFF(WEEK, 6, @xTo), 0)
            ) AS [PotentialHanging]
        LEFT JOIN (  SELECT
                    MAX([WeekCommencing]) AS [CompletedTrendWeek]
                FROM @Variance
                WHERE
                    [Trending] = 1
                AND [TrendTotal] IS NOT NULL
            ) AS [CompletedTrends]
            ON  DATEADD(WEEK, 1, [PotentialHanging].[HangingTrendWeek]) = [CompletedTrends].[CompletedTrendWeek]
        WHERE 
            [CompletedTrends].[CompletedTrendWeek] IS NULL
    ) AS [TrendsToClose]
    ON [Variance].[WeekCommencing] = [TrendsToClose].[HangingTrendWeek]


/* For Testing */
--SELECT * FROM @StockVariance

/* For Testing */
--SELECT 
--    [P].[ID],
--    [Product],
--    SUM([Delivered]) [Delivered],
--    SUM([Dispensed]) [Dispensed],
--    SUM([Stock]) [Stock]
--FROM @Variance AS [V]
--JOIN [dbo].[Products] AS [P] ON [V].[Product] = [P].[Description]
--WHERE [WeekCommencing] >= @xFrom
--GROUP BY [P].[ID], [Product]
--HAVING SUM([Delivered]) > 0 OR SUM([Dispensed]) > 0 OR SUM([Stock]) > 0
--ORDER BY [Product]

/* If we have no Tied products for a Site, we need to generate an empty variance */
DECLARE @Status INT
IF @xGroupID IS NULL
BEGIN
    SELECT @Status = [Status] 
    FROM Sites 
    WHERE EDISID = @EDISID
END
ELSE
BEGIN
    SELECT @Status = [Status] 
    FROM [Sites] 
    JOIN @PrimaryEDIS AS [PEDIS] ON [Sites].[EDISID] = [PEDIS].[PrimaryEDISID]
    WHERE [PEDIS].[PrimaryEDISID] = @EDISID
END

DECLARE @StockWC DATE

SELECT @StockWC = [StockWC] FROM @SiteDates WHERE [EDISID] = @PrimaryEdisID

-- Final Results
SELECT
    [Variance].[WeekCommencing] AS [Date], 
    [IsCask], 
    [IsKeg], 
    [IsMetric], 
    ROUND([Dispensed],2) AS Dispensed, 
    ROUND([Delivered],2) AS Delivered, 
    ROUND([Variance],2) AS Variance, 
    ROUND([CumulativeVariance], 2) AS CumulativeVariance,
    [IsTied],
    [IsConsolidated],
    [IsAdjusted],
    [IsOnFontSetup],
    CAST(0 AS BIT) AS [InUsePercent], -- Dummy value to maintain parity with WeeklyProductVariance procedure output
    [Trending],     -- If true, report colour should be purple. Otherwise use standard colouring.
    [Trend],        -- Calculated trend value, handy for testing if we are calculating it correctly but never display on a report.
    ROUND([TrendTotal],2) AS [TrendTotal],   -- Only populated when we have a 'Final' Trend value to display on report. Shows the last negative Trend total.
    CASE WHEN @StockWC IS NULL
         THEN NULL
         WHEN [Variance].[WeekCommencing] < @StockWC
         THEN NULL
         ELSE ROUND(ISNULL([CumulativeStockVariance], 0), 2)
         END AS Stock,

    ROUND([CumulativeStockVariance],2) AS [Stock],
    [Stock] AS [St],
    [StockVariance] AS [SV],
    CAST(CASE WHEN [VISIT].[WeekCommencing] = [Variance].[WeekCommencing]
              THEN 1
              ELSE 0
              END 
         AS BIT) AS [Visit],
    CAST(CASE WHEN [COT].[WeekCommencing] = [Variance].[WeekCommencing]
              THEN 1
              ELSE 0
              END 
         AS BIT) AS [COT],
    CAST(CASE WHEN [SERVICE].[WeekCommencing] = [Variance].[WeekCommencing]
              THEN 1
              ELSE 0
              END 
         AS BIT) AS [ServiceCall],
    RANK() OVER (ORDER BY [Variance].[WeekCommencing] ASC) AS [WeekNumber]
FROM @Variance AS [Variance]
CROSS JOIN
    (SELECT DISTINCT [EDISID], [StockWC] FROM @SiteDates WHERE [EDISID] = @PrimaryEdisID) AS [Sites]
LEFT JOIN (
    SELECT DISTINCT
        [VR].[EDISID],
        CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, [VR].[VisitDate]), 0) AS DATE) AS [WeekCommencing]
    FROM [dbo].[VisitRecords] AS [VR]
    JOIN [dbo].[VisitDamages] AS [VD] ON [VR].[ID] = [VD].[VisitRecordID]
    JOIN [dbo].[Sites] AS [S] ON [VR].[EDISID] = [S].[EDISID]
    --LEFT JOIN @PrimaryEDIS AS [PEDIS] ON [VR].[EDISID] = [PEDIS].[PrimaryEDISID]
    WHERE 
        --[VR].[DamagesObtained] = 1
    --AND [VR].[Deleted] = 0
        [S].[SiteOnline] <= [VR].[VisitDate]
    --AND (@xEDISID IS NULL OR [S].[EDISID] = @xEDISID)
    --AND [VR].[VisitOutcomeID] IN 
    --    (1,2,7,9,11) 
        /*
         1  - Buying-out - full admission (lessee), 
         2  - Buying-out - full admission (not lessee), 
         7  - Tampering found - full admission, 
         9  - Tampering found - no admission (admitted buying out), 
         11 - Buying-out & Tampering - Full admission
         */
    AND [VR].[VisitDate] >= @xFrom -- Anything earlier is irrelevant 
    AND [VR].[VisitDate] <= @xTo-- Anything later is not yet relevant
    ) AS [VISIT] ON [Sites].[EDISID] = [VISIT].[EDISID] AND [Variance].[WeekCommencing] = [VISIT].[WeekCommencing]
LEFT JOIN (
    SELECT DISTINCT
        [SC].[EDISID],
        CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, [SC].[Date]), 0) AS DATE) AS [WeekCommencing]
    FROM [dbo].[SiteComments] AS [SC]
    --LEFT JOIN @PrimaryEDIS AS [PEDIS] ON [SC].[EDISID] = [PEDIS].[PrimaryEDISID]
    CROSS JOIN @SiteDates AS [Sites]
    WHERE 
        [SC].[HeadingType] IN (3004) -- Change of Tenancy  (16 also exists, but doesn't appear to be used anymore?)
    AND [SC].[Date] >= @xFrom -- Anything earlier is irrelevant
    AND [SC].[Date] <= @xTo -- Anything later is not yet relevant
    AND ((@xEDISID IS NULL AND [Sites].[EDISID] IS NOT NULL) OR (@xEDISID IS NOT NULL AND [SC].[EDISID] = @xEDISID))
    ) AS [COT] ON [Sites].[EDISID] = [COT].[EDISID] AND [Variance].[WeekCommencing] = [COT].[WeekCommencing]
LEFT JOIN (
    SELECT DISTINCT
        [SC].[EDISID],
        CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, [SC].[VisitedOn]), 0) AS DATE) AS [WeekCommencing]
    FROM [dbo].[Calls] AS [SC]
    --LEFT JOIN @PrimaryEDIS AS [PEDIS] ON [SC].[EDISID] = [PEDIS].[PrimaryEDISID]
    CROSS JOIN @SiteDates AS [Sites]
    WHERE 
        [SC].[VisitedOn] >= @xFrom -- Anything earlier is irrelevant
    AND [SC].[VisitedOn] <= @xTo -- Anything later is not yet relevant
	AND [SC].[ClosedOn] IS NOT NULL
	AND [SC].[AbortDate] IS NULL
    AND ((@xEDISID IS NULL AND [Sites].[EDISID] IS NOT NULL) OR (@xEDISID IS NOT NULL AND [SC].[EDISID] = @xEDISID))
    ) AS [SERVICE] ON [Sites].[EDISID] = [SERVICE].[EDISID] AND [Variance].[WeekCommencing] = [SERVICE].[WeekCommencing]
WHERE 
    [Variance].[WeekCommencing] >= @xFrom
--AND (@xIncludeConsolidated = 1 OR [IsConsolidated] = 0)
--AND (@xIncludeCasks = 1 OR [IsCask] = 0) -- Also disables Consolidated Casks
--AND (@xIncludeKegs = 1 OR [IsKeg] = 0)
--AND (@xIncludeMetric = 1 OR [IsMetric] = 0)
AND (@xTied IS NULL OR (@xTied = 1 AND [IsTied] = 1))
ORDER BY 
    [IsConsolidated] DESC, 
    [Variance].[WeekCommencing]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWeeklyVariance] TO PUBLIC
    AS [dbo];

