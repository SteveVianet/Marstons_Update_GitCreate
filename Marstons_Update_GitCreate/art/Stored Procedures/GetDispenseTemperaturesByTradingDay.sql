CREATE PROCEDURE art.GetDispenseTemperaturesByTradingDay
(
	@From			DATE,
	@To				DATE,
	@IncludeCasks	BIT = 1,
	@IncludeKegs	BIT = 1
)
AS

SELECT	Sites.SiteID,
		Sites.Name AS SiteName,
		TradingDay,
		SUM(Quantity) AS Quantity,
		SUM(QuantityInAmber) AS QuantityInAmber,
		SUM(QuantityOutOfSpec) AS QuantityOutOfSpec,
		ProductCategories.[Description] AS Category
FROM PeriodCacheQuality
JOIN Sites ON Sites.EDISID = PeriodCacheQuality.EDISID
JOIN Products ON Products.ID = PeriodCacheQuality.ProductID
JOIN ProductCategories ON ProductCategories.ID = Products.CategoryID
WHERE TradingDay BETWEEN @From AND @To
AND (Products.IsCask = 0 OR @IncludeCasks = 1)
AND (Products.IsCask = 1 OR @IncludeKegs = 1)
GROUP BY Sites.SiteID,
		Sites.Name,
		TradingDay,
		ProductCategories.[Description]

GO
GRANT EXECUTE
    ON OBJECT::[art].[GetDispenseTemperaturesByTradingDay] TO PUBLIC
    AS [dbo];

