CREATE PROCEDURE [dbo].[GetLiquidTypeChanges]
(
	@From			DATETIME,
	@To				DATETIME,
	@IncludeCasks			BIT,
	@IncludeKegs			BIT,
	@IncludeMetric			BIT
)
AS

SET NOCOUNT ON

SELECT  DispenseActions.EDISID,
		Sites.SiteID, 
		Sites.Name,
		TradingDay,
		Pump,
		DispenseActions.Product AS ProductID,
		Products.Description AS ProductName,
		COUNT(*) AS NumberOfChanges,
		SUM(CASE WHEN LiquidType = 3 THEN Pints ELSE 0 END) AS CleanerVolume
FROM DispenseActions
JOIN Sites ON Sites.EDISID = DispenseActions.EDISID
JOIN Products ON Products.ID = DispenseActions.Product
WHERE (TradingDay BETWEEN @From AND @To)
AND (LiquidType <> 5)
AND (OriginalLiquidType IS NOT NULL)
AND (Products.IsWater = 0)
AND (Products.IsCask = 0 OR @IncludeCasks = 1)
AND (Products.IsCask = 1 OR @IncludeKegs = 1)
AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
GROUP BY DispenseActions.EDISID,
		 Sites.SiteID, 
		 Sites.Name,
		 TradingDay,
		 Pump,
		 DispenseActions.Product,
		 Products.Description

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetLiquidTypeChanges] TO PUBLIC
    AS [dbo];

