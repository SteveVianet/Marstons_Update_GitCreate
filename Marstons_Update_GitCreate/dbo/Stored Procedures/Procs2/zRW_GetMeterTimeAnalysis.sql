CREATE PROCEDURE [dbo].[zRW_GetMeterTimeAnalysis]
(
	@From		DATE,
	@To			DATE

)
AS

SET NOCOUNT ON

CREATE TABLE #Sites(EDISID INT NOT NULL PRIMARY KEY)

INSERT INTO #Sites
SELECT EDISID
FROM Sites
WHERE Quality = 1 AND Hidden = 0 AND LastDownload >= @To

SELECT  DB_NAME() AS Customer,
		Sites.SiteID,
		DispenseActions.Pump,
		Products.Description AS Product,
		ProductCategories.Description AS ProductCategory,
		DispenseActions.TradingDay,
		AVG(AverageTemperature) AS AvgAvgTemp,
		SUM(Pints*AverageTemperature)/SUM(Pints) AS AgvAvgTempW
FROM DispenseActions
JOIN Products ON Products.ID = DispenseActions.Product
JOIN ProductCategories ON ProductCategories.ID = Products.CategoryID
JOIN Sites ON Sites.EDISID = DispenseActions.EDISID
WHERE Sites.EDISID IN (SELECT EDISID FROM #Sites)
AND DispenseActions.TradingDay BETWEEN @From AND @To
AND LiquidType = 2
AND Duration > 10
AND Products.IsMetric = 0
--AND AverageTemperature BETWEEN -10 AND 20
GROUP BY Sites.SiteID,
		 DispenseActions.Pump,
		 Products.Description,
		 ProductCategories.Description,
		 DispenseActions.TradingDay

DROP TABLE #Sites

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRW_GetMeterTimeAnalysis] TO PUBLIC
    AS [dbo];

