CREATE PROCEDURE [dbo].[GetWebSiteDeliveryVarianceWeekly]
(
	@EDISID			INT,
	@From			DATETIME,
	@To				DATETIME,
	@IncludeCasks	BIT,
	@IncludeKegs	BIT,
	@IncludeMetric	BIT
)

AS

SET NOCOUNT ON

-- Change the first day of the week to Monday (default is Sunday/7)
SET DATEFIRST 1

CREATE TABLE #PeriodAdjustedVariance (
	ProductID INT, 
	WeekCommencing DATETIME, 
	Dispensed FLOAT, 
	Delivered FLOAT, 
	Variance FLOAT, 
	StockDate DATETIME,
	Stock FLOAT,
	StockVariance FLOAT)
	
CREATE TABLE #PeriodStockAdjustedVariance (
	ProductID INT, 
	WeekCommencing DATETIME, 
	Dispensed FLOAT, 
	Delivered FLOAT, 
	Variance FLOAT, 
	CumulativeVariance FLOAT,
	Stock FLOAT,
	StockVariance FLOAT,
	CumulativeStockVariance FLOAT)

DECLARE @OldestStockFrom DATETIME
DECLARE @OldestStockWeekBack INT
DECLARE @StockDate DATETIME
DECLARE @StockMonday DATETIME

SELECT @OldestStockWeekBack = CAST(PropertyValue AS INTEGER) 
FROM Configuration
WHERE PropertyName = 'Oldest Stock Weeks Back'

SET @OldestStockFrom = DATEADD(WEEK, @OldestStockWeekBack * -1, @From)

SELECT @StockDate = MAX([Date]), @StockMonday = MAX(DATEADD(dw, -DATEPART(dw, [Date]) + 1, [Date]))
FROM Stock
JOIN MasterDates ON MasterDates.[ID] = Stock.MasterDateID
WHERE EDISID = @EDISID
AND Date BETWEEN @OldestStockFrom AND @To
GROUP BY EDISID
--HAVING MAX([Date]) >= @OldestStockFrom

INSERT INTO #PeriodAdjustedVariance
SELECT	PeriodCacheVariance.ProductID, 
		WeekCommencing, 
		Dispensed, 
		Delivered, 
		Variance, 
		RecentStockDate,
		CASE WHEN RecentStockDate <= WeekCommencing THEN Stock ELSE NULL END AS Stock,
		CASE WHEN RecentStockDate <= WeekCommencing THEN StockAdjustedVariance ELSE NULL END AS StockVariance
FROM PeriodCacheVariance
JOIN Products ON Products.[ID] = PeriodCacheVariance.ProductID
LEFT JOIN(
	SELECT PeriodCacheVariance.EDISID, ProductID, MAX(WeekCommencing) AS RecentStockDate
	FROM PeriodCacheVariance
	WHERE WeekCommencing BETWEEN @StockMonday AND @To
	AND StockDate IS NOT NULL
	GROUP BY PeriodCacheVariance.EDISID, ProductID
) AS StockDates ON PeriodCacheVariance.EDISID = StockDates.EDISID AND PeriodCacheVariance.ProductID = StockDates.ProductID
LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = PeriodCacheVariance.EDISID AND Products.[ID] = SiteProductTies.ProductID
LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = PeriodCacheVariance.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
WHERE PeriodCacheVariance.EDISID = @EDISID
AND WeekCommencing BETWEEN @StockMonday AND @To
AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1

INSERT INTO #PeriodStockAdjustedVariance
SELECT	VarianceA.ProductID,
		VarianceA.WeekCommencing, 
		VarianceA.Dispensed, 
		VarianceA.Delivered, 
		VarianceA.Variance,
		SUM(VarianceB.Variance) AS CumulativeVariance, 
		VarianceA.Stock, 
		VarianceA.StockVariance AS StockVariance, 
		SUM(VarianceB.StockVariance) AS CumulativeStockVariance
FROM #PeriodAdjustedVariance AS VarianceA
CROSS JOIN #PeriodAdjustedVariance AS VarianceB
WHERE (VarianceA.ProductID = VarianceB.ProductID OR VarianceA.ProductID IS NULL) 
AND (VarianceB.WeekCommencing <= VarianceA.WeekCommencing)
GROUP BY VarianceA.ProductID, VarianceA.WeekCommencing, VarianceA.Dispensed, VarianceA.Delivered, VarianceA.Variance, VarianceA.Stock, VarianceA.StockVariance
ORDER BY VarianceA.ProductID, VarianceA.WeekCommencing

SELECT	PeriodCacheVariance.WeekCommencing AS TradingDate, 
		Products.Description AS Product, 
		Products.IsCask, 
		CASE WHEN Products.IsCask = 0 AND Products.IsMetric = 0 AND Products.IsWater = 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS [IsKeg], 
		Products.IsMetric,
		COALESCE(StockVariance.Dispensed, PeriodCacheVariance.Dispensed) AS Dispensed,
		COALESCE(StockVariance.Delivered, PeriodCacheVariance.Delivered) AS Delivered,
		COALESCE(StockVariance.Variance, PeriodCacheVariance.Variance) AS Variance,
		PeriodCacheVariance.IsTied,
		CumulativeStockVariance
FROM PeriodCacheVariance
JOIN Products ON Products.ID = PeriodCacheVariance.ProductID
LEFT JOIN #PeriodStockAdjustedVariance AS StockVariance ON StockVariance.ProductID = PeriodCacheVariance.ProductID AND StockVariance.WeekCommencing = PeriodCacheVariance.WeekCommencing
WHERE PeriodCacheVariance.EDISID = @EDISID
  AND (Products.IsCask = 0 OR @IncludeCasks = 1) 
  AND (Products.IsCask = 1 OR @IncludeKegs = 1) 
  AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
  AND PeriodCacheVariance.WeekCommencing BETWEEN @From AND @To
  AND PeriodCacheVariance.IsTied = 1
ORDER BY PeriodCacheVariance.WeekCommencing, Products.Description

DROP TABLE #PeriodStockAdjustedVariance
DROP TABLE #PeriodAdjustedVariance


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteDeliveryVarianceWeekly] TO PUBLIC
    AS [dbo];

