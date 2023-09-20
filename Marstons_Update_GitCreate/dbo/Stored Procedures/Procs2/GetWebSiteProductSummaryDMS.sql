CREATE PROCEDURE [dbo].[GetWebSiteProductSummaryDMS] 
(
	@EDISID			INT,
	@From			DATETIME,
	@To				DATETIME,
	@IncludeCasks	BIT,
	@IncludeKegs	BIT,
	@IncludeMetric	BIT
)

AS

/*
RW: Use cache version as it's miles quicker and this has an issue on delivered-only products
SELECT COALESCE(DLData.Product, Delivery.ProductID) AS ProductID,
	   COALESCE(Products.[Description], Delivery.Product) AS Product,
	   0 AS QuantityDispensed,
	   0 AS DrinksDispensed,
	   0 AS OperationalYield,
       0 AS [Sold],
	   0 AS RetailYield,
	   COALESCE(Products.IsCask, Delivery.IsCask) AS IsCask,
	   0 AS MinPouringYield,
	   0 AS MaxPouringYield 
FROM dbo.MasterDates
JOIN dbo.DLData ON MasterDates.[ID] = DLData.DownloadID AND MasterDates.EDISID = @EDISID AND MasterDates.[Date] BETWEEN @From AND @To
FULL OUTER JOIN (
	SELECT Delivery.Product AS ProductID,
		   Products.[Description] AS Product,
		   Products.IsCask
	FROM dbo.Delivery
	JOIN dbo.MasterDates ON MasterDates.[ID] = Delivery.DeliveryID
	JOIN dbo.Products ON Products.[ID] = Delivery.Product
	JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
	WHERE MasterDates.EDISID = @EDISID
	AND MasterDates.[Date] BETWEEN @From AND @To
	AND Products.IsWater = 0
	AND (Products.IsCask = 0 OR @IncludeCasks = 1)
	AND (Products.IsCask = 1 OR @IncludeKegs = 1)
	AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
	AND MasterDates.Date > = Sites.SiteOnline
	GROUP BY Delivery.Product, Products.[Description], Products.IsCask
	) AS Delivery ON Delivery.ProductID = DLData.Product
JOIN dbo.Products ON Products.ID = COALESCE(DLData.Product, Delivery.ProductID)
JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
WHERE Products.IsWater = 0
AND (Products.IsCask = 0 OR @IncludeCasks = 1)
AND (Products.IsCask = 1 OR @IncludeKegs = 1)
AND (Products.IsMetric = 0 OR @IncludeMetric = 1) 
AND MasterDates.Date > = Sites.SiteOnline
GROUP BY COALESCE(DLData.Product, Delivery.ProductID), COALESCE(Products.[Description], Delivery.Product), COALESCE(Products.IsCask, Delivery.IsCask)
ORDER BY COALESCE(Products.[Description], Delivery.Product)
*/

SELECT ProductID AS ProductID,
	   Products.[Description] AS Product,
	   SUM(Dispensed) AS QuantityDispensed,
	   0 AS DrinksDispensed,
	   0 AS OperationalYield,
       0 AS [Sold],
	   0 AS RetailYield,
	   Products.IsCask AS IsCask,
	   0 AS MinPouringYield,
	   0 AS MaxPouringYield,
	   POSYieldCashValue,
	   CleaningCashValue,
	   0 AS BeerInLineCleaning
FROM dbo.PeriodCacheVariance
JOIN dbo.Products ON Products.ID = PeriodCacheVariance.ProductID
JOIN dbo.Sites ON Sites.EDISID = PeriodCacheVariance.EDISID
JOIN dbo.Owners ON Owners.ID = Sites.OwnerID
WHERE PeriodCacheVariance.EDISID = @EDISID
AND Products.IsWater = 0
AND (Products.IsCask = 0 OR @IncludeCasks = 1)
AND (Products.IsCask = 1 OR @IncludeKegs = 1)
AND (Products.IsMetric = 0 OR @IncludeMetric = 1) 
AND PeriodCacheVariance.WeekCommencing >= Sites.SiteOnline
GROUP BY ProductID, Products.[Description], Products.IsCask, POSYieldCashValue, CleaningCashValue
ORDER BY Products.[Description]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteProductSummaryDMS] TO PUBLIC
    AS [dbo];

