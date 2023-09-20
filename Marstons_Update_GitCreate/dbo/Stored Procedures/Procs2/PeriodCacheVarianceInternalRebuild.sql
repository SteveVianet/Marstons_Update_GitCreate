CREATE PROCEDURE [dbo].[PeriodCacheVarianceInternalRebuild]
(
	@From 					DATETIME = NULL,
	@To						DATETIME = NULL,
	@FirstDayOfWeek			INT = 1,
	@OnlyRefreshUsersSites	BIT = 0
)
AS

SET NOCOUNT ON

SET DATEFIRST @FirstDayOfWeek

CREATE TABLE #Sites(EDISID INT)

DECLARE @WebAudit AS DATETIME
DECLARE @MultipleAuditors BIT

SELECT @WebAudit = DATEADD(day, -DATEPART(dw, CAST(Configuration.PropertyValue AS DATETIME)) +1, CAST(Configuration.PropertyValue AS DATETIME) + 7)
FROM Configuration
WHERE PropertyName = 'AuditDate'

DECLARE @AccurateDeliveryProvided AS BIT
SELECT @AccurateDeliveryProvided = CASE WHEN Configuration.PropertyValue = 'False' THEN 0 ELSE 1 END
FROM Configuration
WHERE PropertyName = 'Accurate Stock'

SELECT @MultipleAuditors = MultipleAuditors
FROM [SQL1\SQL1].ServiceLogger.dbo.EDISDatabases
WHERE Name = DB_NAME()
AND (LimitToClient = HOST_NAME() OR LimitToClient IS NULL)

--SET TO START OF WEEK
SET @From = DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, @From) + 1, @From)))
--SET @To = DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, @To) + 1, @To)))

INSERT INTO #Sites
(EDISID)
SELECT EDISID
FROM Sites
JOIN Configuration ON PropertyName = 'AuditorName'
WHERE ((CASE WHEN @MultipleAuditors = 0 THEN UPPER(Configuration.PropertyValue) ELSE UPPER(dbo.udfNiceName(SiteUser)) END) = UPPER(dbo.udfNiceName(SUSER_SNAME())) OR @OnlyRefreshUsersSites = 0) 

DELETE
FROM PeriodCacheVarianceInternal
WHERE ((WeekCommencing BETWEEN @From AND @To) OR (@From IS NULL AND @To IS NULL))
AND EDISID IN (SELECT EDISID FROM #Sites)

--Merge products groups
DECLARE @PrimaryProducts TABLE(ProductID INT NOT NULL, PrimaryProductID INT NOT NULL)
INSERT INTO @PrimaryProducts
(ProductID, PrimaryProductID)
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


--Merge system groups
DECLARE @PrimaryEDIS TABLE(PrimaryEDISID INT NOT NULL, EDISID INT NOT NULL)
INSERT INTO @PrimaryEDIS
SELECT MAX(PrimaryEDISID) AS PrimaryEDISID, SiteGroupSites.EDISID
FROM(
	SELECT SiteGroupID, SiteGroupSites.EDISID AS PrimaryEDISID
	FROM SiteGroupSites
	JOIN #Sites AS Sites ON Sites.EDISID = SiteGroupSites.EDISID 
	WHERE SiteGroupID IN (SELECT ID FROM SiteGroups WHERE TypeID = 1)
	AND IsPrimary = 1
	GROUP BY SiteGroupID, SiteGroupSites.EDISID
) AS PrimarySites
JOIN SiteGroupSites ON SiteGroupSites.SiteGroupID = PrimarySites.SiteGroupID
LEFT JOIN PumpSetup ON PumpSetup.EDISID = SiteGroupSites.EDISID
GROUP BY SiteGroupSites.EDISID
ORDER BY PrimaryEDISID

;WITH cte_WeekStock AS (
	--If there have been multiple stock takes in the same week we only keep the newest
	SELECT EDISID, ProductID, Date, CASE [Hour] WHEN 0 THEN 7 ELSE [Hour] END AS Hour, BeforeDelivery, (Quantity*8) AS Quantity, IsAudited
	FROM (
		SELECT COALESCE(PrimarySites.PrimaryEDISID, MasterDates.EDISID) AS EDISID, COALESCE(PrimaryProducts.PrimaryProductID, Stock.ProductID) AS ProductID, DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 1, MasterDates.Date))) AS WeekCommencing, 
		RANK() OVER (PARTITION BY COALESCE(PrimarySites.PrimaryEDISID, MasterDates.EDISID), DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 1, MasterDates.Date))) ORDER BY Date DESC) AS Ranked,
		Date, Stock.Hour, BeforeDelivery, SUM(Stock.Quantity) AS Quantity, CASE WHEN MasterDates.Date < @WebAudit THEN 1 ELSE 0 END AS IsAudited
		FROM Stock
		JOIN MasterDates ON MasterDates.ID = MasterDateID  
						 AND ((MasterDates.Date BETWEEN @From AND @To) OR (@From IS NULL AND @To IS NULL))
		JOIN #Sites AS Sites ON Sites.EDISID = MasterDates.EDISID
		LEFT JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = Stock.ProductID 
		LEFT JOIN @PrimaryEDIS AS PrimarySites ON MasterDates.EDISID = PrimarySites.EDISID
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
		JOIN MasterDates ON MasterDates.ID = MasterDateID  
						 AND ((MasterDates.Date BETWEEN @From AND @To) OR (@From IS NULL AND @To IS NULL))
		JOIN #Sites AS Sites ON Sites.EDISID = MasterDates.EDISID
		LEFT JOIN @PrimaryEDIS AS PrimarySites ON MasterDates.EDISID = PrimarySites.EDISID
		GROUP BY COALESCE(PrimarySites.PrimaryEDISID, MasterDates.EDISID), DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 1, MasterDates.Date))), Date, Hour, BeforeDelivery
	) AS OrderedStock
	WHERE Ranked = 1
	GROUP BY EDISID, Date, IsAudited
)

INSERT INTO PeriodCacheVarianceInternal
(EDISID, WeekCommencing, ProductID, IsTied, DeliveredBeforeStock, DeliveredAfterStock, Delivered, Dispensed, Variance, StockDate, Stock, StockAdjustedDelivered, StockAdjustedDispensed, StockAdjustedVariance, IsAudited)	
SELECT	Cache.EDISID, WeekDate, Cache.ProductID,
		COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) AS IsTied,
		CASE WHEN MAX(StockDate) IS NULL THEN NULL ELSE SUM(DeliveryBeofreStockTake) END AS DeliveryBeofreStockTake,
		CASE WHEN MAX(StockDate) IS NULL THEN NULL ELSE SUM(DeliveryAfterStockTake) END AS DeliveryAfterStockTake,
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
			END AS DeliveryBeofreStockTake,
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
			SELECT  COALESCE(PrimarySites.PrimaryEDISID, MasterDates.EDISID) AS EDISID,
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
			JOIN #Sites AS CurrentSites ON CurrentSites.EDISID = MasterDates.EDISID
			JOIN Sites ON Sites.EDISID = MasterDates.EDISID 
					   AND ( (MasterDates.Date BETWEEN @From AND @To) OR (@From IS NULL AND @To IS NULL) )
			JOIN Delivery ON Delivery.DeliveryID = MasterDates.ID
			LEFT JOIN Products ON Products.[ID] = Delivery.Product
			LEFT JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = Products.ID
			LEFT JOIN @PrimaryEDIS AS PrimarySites ON MasterDates.EDISID = PrimarySites.EDISID
			LEFT JOIN cte_WeekStock AS SiteStock ON DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 1, MasterDates.Date)))
													= DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, SiteStock.Date) + 1, SiteStock.Date)))
												 AND COALESCE(PrimarySites.PrimaryEDISID, MasterDates.EDISID) = SiteStock.EDISID
												 AND COALESCE(PrimaryProducts.PrimaryProductID, Delivery.Product) = SiteStock.ProductID
												 
			LEFT JOIN cte_BlankStock AS DummyStock ON DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 1, MasterDates.Date)))
												     = DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, DummyStock.Date) + 1, DummyStock.Date)))
												  AND COALESCE(PrimarySites.PrimaryEDISID, MasterDates.EDISID) = DummyStock.EDISID
			GROUP BY COALESCE(PrimarySites.PrimaryEDISID, MasterDates.EDISID),
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
	SELECT  COALESCE(PrimarySites.PrimaryEDISID, MasterDates.EDISID) AS EDISID,
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
	JOIN #Sites AS CurrentSites ON CurrentSites.EDISID = MasterDates.EDISID
	JOIN Sites ON Sites.EDISID = MasterDates.EDISID  
			   AND ( (MasterDates.Date BETWEEN @From AND @To) OR (@From IS NULL AND @To IS NULL) )
	LEFT JOIN @PrimaryEDIS AS PrimarySites ON MasterDates.EDISID = PrimarySites.EDISID
	JOIN DLData ON DLData.DownloadID = MasterDates.ID
	LEFT JOIN Products ON Products.[ID] = DLData.Product
	LEFT JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = Products.ID
	LEFT JOIN cte_WeekStock AS SiteStock ON DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 1, MasterDates.Date)))
											= DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, SiteStock.Date) + 1, SiteStock.Date)))
										 AND COALESCE(PrimarySites.PrimaryEDISID, MasterDates.EDISID) = SiteStock.EDISID
										 AND COALESCE(PrimaryProducts.PrimaryProductID, DLData.Product) = SiteStock.ProductID
										 
	LEFT JOIN cte_BlankStock AS DummyStock ON DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 1, MasterDates.Date)))
											  = DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, DummyStock.Date) + 1, DummyStock.Date)))
										   AND COALESCE(PrimarySites.PrimaryEDISID, MasterDates.EDISID) = DummyStock.EDISID
												  
	LEFT JOIN (--DISPENSE BETWEEN STOCK TAKE AND END OF WEEK
		SELECT EDISID, ProductID, EOW,
			   SUM(Dispensed) AS Dispensed
		FROM (
			SELECT  COALESCE(PrimarySites.PrimaryEDISID, MasterDates.EDISID) AS EDISID,
					MasterDates.Date,
					(DLData.Shift - 1) AS Hour,
					DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 7, MasterDates.Date))) As EOW,
					COALESCE(PrimaryProducts.PrimaryProductID, DLData.Product) AS ProductID,
					SUM(DLData.Quantity) AS Dispensed,
					COALESCE(SiteStock.Date, DummyStock.Date) AS SiteStockDate,
					COALESCE(SiteStock.Hour, DummyStock.Hour) AS SiteStockHour,
					CASE WHEN MasterDates.Date < @WebAudit THEN 1 ELSE 0 END AS IsAudited
			FROM MasterDates
			JOIN #Sites AS CurrentSites ON CurrentSites.EDISID = MasterDates.EDISID
			JOIN Sites ON Sites.EDISID = MasterDates.EDISID  
					   AND ( (MasterDates.Date BETWEEN @From AND @To) OR (@From IS NULL AND @To IS NULL) )
			JOIN DLData ON DLData.DownloadID = MasterDates.ID
			LEFT JOIN Products ON Products.[ID] = DLData.Product
			LEFT JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = Products.ID
			LEFT JOIN @PrimaryEDIS AS PrimarySites ON MasterDates.EDISID = PrimarySites.EDISID
												   
			LEFT JOIN cte_WeekStock AS SiteStock ON DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 1, MasterDates.Date)))
													= DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, SiteStock.Date) + 1, SiteStock.Date)))
												 AND COALESCE(PrimarySites.PrimaryEDISID, MasterDates.EDISID) = SiteStock.EDISID
												 AND COALESCE(PrimaryProducts.PrimaryProductID, DLData.Product) = SiteStock.ProductID
												 
			LEFT JOIN cte_BlankStock AS DummyStock ON DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 1, MasterDates.Date)))
											  = DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, DummyStock.Date) + 1, DummyStock.Date)))
										   AND COALESCE(PrimarySites.PrimaryEDISID, MasterDates.EDISID) = DummyStock.EDISID
			
			WHERE (
				(MasterDates.Date > COALESCE(SiteStock.Date, DummyStock.Date) OR COALESCE(SiteStock.Date, DummyStock.Date) IS NULL) 
				OR (COALESCE(SiteStock.Date, DummyStock.Date) = MasterDates.Date AND (DLData.Shift - 1) > COALESCE(SiteStock.Hour, DummyStock.Hour))
			)
				
			GROUP BY COALESCE(PrimarySites.PrimaryEDISID, MasterDates.EDISID),
					MasterDates.Date,
					DLData.Shift,
					DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 7, MasterDates.Date))), 
					COALESCE(PrimaryProducts.PrimaryProductID, DLData.Product),
					COALESCE(SiteStock.Date, DummyStock.Date),
					COALESCE(SiteStock.Hour, DummyStock.Hour),
					CASE WHEN MasterDates.Date < @WebAudit THEN 1 ELSE 0 END 
		) AS DispenseSinceStock
		GROUP BY EDISID, ProductID, EOW 
				
	) AS StockDisp ON COALESCE(PrimarySites.PrimaryEDISID, MasterDates.EDISID) = StockDisp.EDISID
				   AND COALESCE(PrimaryProducts.PrimaryProductID, DLData.Product) = StockDisp.ProductID
				   AND DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 7, MasterDates.Date))) = StockDisp.EOW
												  
	GROUP BY COALESCE(PrimarySites.PrimaryEDISID, MasterDates.EDISID),
			DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 1, MasterDates.Date))),
			COALESCE(PrimaryProducts.PrimaryProductID, DLData.Product),
			COALESCE(SiteStock.Date, DummyStock.Date),
			COALESCE(SiteStock.Quantity, DummyStock.Quantity),
			COALESCE(SiteStock.BeforeDelivery, DummyStock.BeforeDelivery),
			StockDisp.Dispensed,
			CASE WHEN MasterDates.Date < @WebAudit THEN 1 ELSE 0 END

	--ORDER BY COALESCE(PrimarySites.PrimaryEDISID, MasterDates.EDISID), 
	--DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, MasterDates.Date) + 1, MasterDates.Date))),
	--COALESCE(PrimaryProducts.ProductID, DLData.Product)


) AS Cache
JOIN #Sites AS Sites ON Sites.EDISID = Cache.EDISID
JOIN Products ON Products.ID = Cache.ProductID
LEFT JOIN SiteProductCategoryTies ON SiteProductCategoryTies.ProductCategoryID = Products.CategoryID AND Cache.EDISID = SiteProductCategoryTies.EDISID
LEFT JOIN SiteProductTies ON SiteProductTies.ProductID = Products.ID AND Cache.EDISID = SiteProductTies.EDISID

GROUP BY Cache.EDISID, 
		 WeekDate,
		 Cache.ProductID,
		 COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied),
		 IsAudited
		 
ORDER BY Cache.EDISID, WeekDate, Cache.ProductID


DROP TABLE #Sites

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[PeriodCacheVarianceInternalRebuild] TO PUBLIC
    AS [dbo];

