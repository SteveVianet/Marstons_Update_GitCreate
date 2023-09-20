CREATE PROCEDURE [dbo].[GetAPIDispense]
(
	@SiteID		VARCHAR(15),
	@From		DATE,
	@To			DATE
)
AS

SET NOCOUNT ON

CREATE TABLE #Stock(EDISID INT, [Date] DATETIME, StockMonday DATETIME)

CREATE TABLE #PeriodAdjustedVariance (
	EDISID INT, 
	ProductID INT, 
	WeekCommencing DATETIME, 
	Dispensed FLOAT, 
	Delivered FLOAT, 
	Variance FLOAT, 
	StockDate DATETIME,
	Stock FLOAT,
	StockVariance FLOAT,
	IsAudited BIT)
	
CREATE TABLE #PeriodStockAdjustedVariance (
	EDISID INT, 
	ProductID INT, 
	WeekCommencing DATETIME, 
	Dispensed FLOAT, 
	Delivered FLOAT, 
	Variance FLOAT, 
	CumulativeVariance FLOAT,
	Stock FLOAT,
	StockVariance FLOAT,
	CumulativeStockVariance FLOAT)

DECLARE @WeekFromTwelveWeeks DATETIME = DATEADD(week, -11, @From)
DECLARE @OldestStockFrom DATETIME
DECLARE @OldestStockWeekBack INT
DECLARE @EDISID INT

SELECT @EDISID = EDISID
FROM Sites
WHERE SiteID = @SiteID

SELECT @OldestStockWeekBack = CAST(PropertyValue AS INTEGER) 
FROM Configuration
WHERE PropertyName = 'Oldest Stock Weeks Back'

SET @OldestStockFrom = DATEADD(WEEK, @OldestStockWeekBack * -1, @WeekFromTwelveWeeks)

INSERT INTO #Stock
(EDISID, [Date], StockMonday)
SELECT Sites.EDISID, MAX([Date]), MAX(DATEADD(dw, -DATEPART(dw, [Date]) + 1, [Date]))
FROM Stock
JOIN MasterDates ON MasterDates.[ID] = Stock.MasterDateID
JOIN Sites AS Sites ON Sites.EDISID = MasterDates.EDISID
WHERE Sites.EDISID = @EDISID
GROUP BY Sites.EDISID, Sites.SiteOnline
HAVING MAX([Date]) >= @OldestStockFrom 
AND MAX([Date]) >= Sites.SiteOnline

INSERT INTO #PeriodAdjustedVariance
SELECT	PeriodCacheVariance.EDISID, 
		PeriodCacheVariance.ProductID, 
		WeekCommencing, 
		Dispensed, 
		Delivered, 
		Variance, 
		RecentStockDate,
		CASE WHEN RecentStockDate <= WeekCommencing THEN Stock ELSE NULL END AS Stock,
		CASE WHEN RecentStockDate <= WeekCommencing THEN StockAdjustedVariance ELSE NULL END AS StockVariance,
		IsAudited
FROM PeriodCacheVariance
JOIN Products ON Products.[ID] = PeriodCacheVariance.ProductID
LEFT JOIN(
	SELECT PeriodCacheVariance.EDISID, ProductID, MAX(WeekCommencing) AS RecentStockDate
	FROM PeriodCacheVariance
	LEFT JOIN #Stock AS Stock ON Stock.EDISID = PeriodCacheVariance.EDISID
	WHERE PeriodCacheVariance.EDISID = @EDISID
	AND WeekCommencing BETWEEN ISNULL(StockMonday, @From) AND @To
	AND StockDate IS NOT NULL
	GROUP BY PeriodCacheVariance.EDISID, ProductID
) AS StockDates ON PeriodCacheVariance.EDISID = StockDates.EDISID AND PeriodCacheVariance.ProductID = StockDates.ProductID
LEFT JOIN #Stock AS Stock ON Stock.EDISID = PeriodCacheVariance.EDISID
LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = PeriodCacheVariance.EDISID AND Products.[ID] = SiteProductTies.ProductID
LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = PeriodCacheVariance.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
WHERE PeriodCacheVariance.EDISID = @EDISID 
AND WeekCommencing BETWEEN ISNULL(StockMonday, @From) AND @To
AND IsAudited = 1
--AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1

INSERT INTO #PeriodStockAdjustedVariance
SELECT	VarianceA.EDISID, 
		VarianceA.ProductID,
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
WHERE ((VarianceA.EDISID = VarianceB.EDISID) 
AND (VarianceA.ProductID = VarianceB.ProductID OR VarianceA.ProductID IS NULL) 
AND (VarianceB.WeekCommencing <= VarianceA.WeekCommencing))
GROUP BY VarianceA.EDISID, VarianceA.ProductID, VarianceA.WeekCommencing, VarianceA.Delivered, VarianceA.Dispensed, VarianceA.Variance, VarianceA.Stock, VarianceA.StockVariance
ORDER BY VarianceA.EDISID, VarianceA.ProductID, VarianceA.WeekCommencing

SELECT	Sites.SiteID,
		Variance.WeekCommencing,
		Products.[Description] AS Product,
		ROUND(Variance.Dispensed/8, 2) AS Dispensed,
		ROUND(Variance.Delivered/8, 2) AS Delivered,
		ROUND(ISNULL(Variance.CumulativeStockVariance/8, 0), 2) AS Stock
FROM #PeriodStockAdjustedVariance AS Variance
	JOIN Products ON Products.ID = Variance.ProductID
	JOIN Sites ON Sites.EDISID = Variance.EDISID
WHERE Sites.SiteID = @SiteID 
	AND Variance.WeekCommencing BETWEEN @From AND @To

DROP TABLE #Stock
DROP TABLE #PeriodAdjustedVariance
DROP TABLE #PeriodStockAdjustedVariance

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAPIDispense] TO PUBLIC
    AS [dbo];

