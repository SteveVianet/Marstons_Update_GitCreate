CREATE PROCEDURE [dbo].[GetWebSiteInitialStockVariance]
(
	@EDISID		INT,
	@ReportFrom DATETIME,
	@ReportTo	DATETIME,
	@ProductID	INT = NULL
)
AS

SET NOCOUNT ON
SET DATEFIRST 1

DECLARE @AccurateDeliveryProvided AS BIT
SELECT @AccurateDeliveryProvided = CASE WHEN Configuration.PropertyValue = 'False' THEN 0 ELSE 1 END
FROM Configuration
WHERE PropertyName = 'Accurate Stock'





SELECT	PeriodCacheVariance.ProductID, 
		Products.Description AS Product, 
		Products.IsCask, 
		CASE WHEN Products.IsCask = 0 AND Products.IsMetric = 0 AND Products.IsWater = 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS [IsKeg],
		StockAdjustedVariance/8 AS InitialStockVariance,
		MAX(WeekCommencing) AS StockDateMonday
FROM PeriodCacheVariance
JOIN(
	SELECT	EDISID, ProductID, MAX(WeekCommencing) AS StockDateMonday
	FROM PeriodCacheVariance
	WHERE EDISID = @EDISID
	AND WeekCommencing BETWEEN @ReportFrom AND @ReportTo
	AND (ProductID = @ProductID OR @ProductID IS NULL)
	AND PeriodCacheVariance.Stock IS NOT NULL 
	GROUP BY EDISID, ProductID
	
) AS MostRecentStock ON MostRecentStock.EDISID = PeriodCacheVariance.EDISID AND MostRecentStock.ProductID = PeriodCacheVariance.ProductID AND MostRecentStock.StockDateMonday = PeriodCacheVariance.WeekCommencing
JOIN Products ON Products.ID = PeriodCacheVariance.ProductID
--WHERE @AccurateDeliveryProvided = 1
GROUP BY PeriodCacheVariance.ProductID, 
		Products.Description, 
		Products.IsCask, 
		CASE WHEN Products.IsCask = 0 AND Products.IsMetric = 0 AND Products.IsWater = 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END,
		StockAdjustedVariance/8
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteInitialStockVariance] TO PUBLIC
    AS [dbo];

