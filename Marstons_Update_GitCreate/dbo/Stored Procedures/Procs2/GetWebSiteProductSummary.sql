CREATE PROCEDURE [dbo].[GetWebSiteProductSummary] 
(
	@EDISID			INT,
	@From				DATETIME,
	@To				DATETIME,
	@IncludeCasks			BIT,
	@IncludeKegs			BIT,
	@IncludeMetric			BIT
)
AS

SET NOCOUNT ON

DECLARE @Sites TABLE(EDISID INT NOT NULL, POSYieldCashValue MONEY, CleaningCashValue MONEY, PouringYieldCashValue MONEY, CellarID INT NOT NULL IDENTITY) DECLARE @SiteGroupID INT DECLARE @PrimaryProducts TABLE(ProductID INT NOT NULL, PrimaryProductID INT NOT NULL) DECLARE @SiteOnline DATETIME

SELECT @SiteOnline = SiteOnline
FROM dbo.Sites
WHERE EDISID = @EDISID

-- Find out which EDISIDs are relevant (plough through SiteGroups) 
INSERT INTO @Sites (EDISID, POSYieldCashValue, CleaningCashValue, PouringYieldCashValue)
SELECT EDISID, POSYieldCashValue, CleaningCashValue, PouringYieldCashValue
FROM Sites
JOIN Owners ON Owners.ID = Sites.OwnerID
WHERE EDISID = @EDISID

SELECT @SiteGroupID = SiteGroupID
FROM SiteGroupSites
JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID WHERE TypeID = 1 AND EDISID = @EDISID

INSERT INTO @Sites (EDISID, POSYieldCashValue, CleaningCashValue)
SELECT SiteGroupSites.EDISID, POSYieldCashValue, CleaningCashValue
FROM SiteGroupSites
JOIN Sites ON Sites.EDISID = SiteGroupSites.EDISID
JOIN Owners ON Owners.ID = Sites.OwnerID
WHERE SiteGroupSites.SiteGroupID = @SiteGroupID AND SiteGroupSites.EDISID <> @EDISID

--SELECT * FROM @Sites

-- Unroll ProductGroups so we can work out how to transform ProductIDs to their primaries 
INSERT INTO @PrimaryProducts 
	(ProductID, PrimaryProductID) 
SELECT ProductID, ProductGroupPrimaries.PrimaryProductID
FROM ProductGroupProducts
JOIN ProductGroups 
  ON ProductGroups.ID = ProductGroupProducts.ProductGroupID
JOIN (
	SELECT ProductGroupID, ProductID AS PrimaryProductID
	FROM ProductGroupProducts
	JOIN ProductGroups ON ProductGroups.ID = ProductGroupProducts.ProductGroupID
	WHERE TypeID = 1 AND IsPrimary = 1
	) AS ProductGroupPrimaries 
  ON ProductGroupPrimaries.ProductGroupID = ProductGroups.ID 
WHERE TypeID = 1 
  AND IsPrimary = 0

--SELECT * FROM @PrimaryProducts
	
SELECT  Products.[ID] AS ProductID,
		Products.[Description] AS Product,
	ISNULL(SUM(DispenseActions.Pints),0) AS QuantityDispensed,
	ISNULL(SUM(DispenseActions.EstimatedDrinks),0) AS DrinksDispensed,
	ISNULL(SUM(DispenseActions.EstimatedDrinks),0) - ISNULL(SUM(DispenseActions.Pints),0) AS OperationalYield,
	ISNULL(SUM(Sales.Quantity), 0) AS [Sold],
	ISNULL(SUM(Sales.Quantity),0)-ISNULL(SUM(DispenseActions.EstimatedDrinks),0) AS RetailYield,
	Products.IsCask AS IsCask,
	ISNULL(SiteProductCategorySpecs.MinimumPouringYield, ProductCategories.MinimumPouringYield) AS MinPouringYield,
	ISNULL(SiteProductCategorySpecs.MaximumPouringYield, ProductCategories.MaximumPouringYield) AS MaxPouringYield,
	ISNULL(SiteProductCategorySpecs.LowPouringYieldErrThreshold, ProductCategories.LowPouringYieldErrThreshold) AS LowPouringYieldErrThreshold,
	ISNULL(SiteProductCategorySpecs.HighPouringYieldErrThreshold, ProductCategories.HighPouringYieldErrThreshold) AS HighPouringYieldErrThreshold,
	POSYieldCashValue,
	CleaningCashValue,
	PouringYieldCashValue,
	ISNULL(SUM(DispenseActions.BeerInLineCleaning),0) AS BeerInLineCleaning,
	ISNULL(SUM(DispenseActions.Duration), 0) AS Duration,
	ISNULL(SUM(CASE WHEN DispenseActions.Pints >= 0.3 THEN DispenseActions.Pints ELSE 0 END), 0) AS QuantityDispensedNoSmallPours,
	ISNULL(SUM(CASE WHEN DispenseActions.Pints >= 0.3 THEN DispenseActions.BeerDuration ELSE 0 END), 0) AS DurationNoSmallPours
FROM Products 
FULL OUTER JOIN (
	SELECT	ISNULL(PrimaryProducts.PrimaryProductID, DispenseActions.Product) AS ProductID, 
			SUM(CASE WHEN LiquidType = 2 THEN DispenseActions.Pints ELSE 0 END) AS Pints,
			SUM(CASE WHEN LiquidType = 2 THEN DispenseActions.EstimatedDrinks ELSE 0 END) AS EstimatedDrinks,
			AVG(POSYieldCashValue) AS POSYieldCashValue,
			AVG(CleaningCashValue) AS CleaningCashValue,
			AVG(PouringYieldCashValue) AS PouringYieldCashValue,
			SUM(CASE WHEN LiquidType = 5 THEN DispenseActions.Pints ELSE 0 END) AS BeerInLineCleaning,
			SUM(Duration) AS Duration,
			SUM(CASE WHEN LiquidType = 2 THEN Duration ELSE 0 END) AS BeerDuration
	FROM DispenseActions
	JOIN @Sites AS RelevantSites
      ON RelevantSites.EDISID = DispenseActions.EDISID
    FULL OUTER JOIN @PrimaryProducts AS PrimaryProducts
      ON PrimaryProducts.ProductID = DispenseActions.Product
	WHERE DispenseActions.TradingDay BETWEEN @From AND @To
	  AND DispenseActions.TradingDay >= @SiteOnline
	  AND LiquidType IN (2, 5)
	GROUP BY ISNULL(PrimaryProducts.PrimaryProductID, DispenseActions.Product)
	) AS DispenseActions
  ON Products.ID = DispenseActions.ProductID 
FULL OUTER JOIN (
	SELECT	ISNULL(PrimaryProducts.PrimaryProductID, Sales.ProductID) AS ProductID,
			SUM(Sales.Quantity) AS Quantity
	FROM Sales
	JOIN @Sites AS RelevantSites
	  ON RelevantSites.EDISID = Sales.EDISID
    FULL OUTER JOIN @PrimaryProducts AS PrimaryProducts
      ON PrimaryProducts.ProductID = Sales.ProductID
	WHERE Sales.TradingDate BETWEEN @From AND @To
	  AND Sales.TradingDate >= @SiteOnline
	GROUP BY ISNULL(PrimaryProducts.PrimaryProductID, Sales.ProductID)
	) AS Sales
  ON Products.ID = Sales.ProductID
JOIN ProductCategories
  ON ProductCategories.ID = Products.CategoryID 
FULL OUTER JOIN (
	SELECT ProductCategoryID, MinimumPouringYield, MaximumPouringYield, HighPouringYieldErrThreshold, LowPouringYieldErrThreshold
	FROM SiteProductCategorySpecifications
	JOIN @Sites AS RelevantSites
	  ON RelevantSites.EDISID = SiteProductCategorySpecifications.EDISID
	) AS SiteProductCategorySpecs
  ON SiteProductCategorySpecs.ProductCategoryID = ProductCategories.ID
WHERE Products.IsWater = 0
  AND (Products.IsCask = 0 OR @IncludeCasks = 1)
  AND (Products.IsCask = 1 OR @IncludeKegs = 1)
  AND (Products.IsMetric = 0 OR @IncludeMetric = 1) 
GROUP BY Products.[ID], Products.[Description], Products.IsCask, ISNULL(SiteProductCategorySpecs.MinimumPouringYield, ProductCategories.MinimumPouringYield), ISNULL(SiteProductCategorySpecs.MaximumPouringYield, ProductCategories.MaximumPouringYield), 	ISNULL(SiteProductCategorySpecs.LowPouringYieldErrThreshold, ProductCategories.LowPouringYieldErrThreshold), ISNULL(SiteProductCategorySpecs.HighPouringYieldErrThreshold, ProductCategories.HighPouringYieldErrThreshold), POSYieldCashValue, CleaningCashValue, PouringYieldCashValue
HAVING (ISNULL(SUM(DispenseActions.Pints),0) > 0 OR ISNULL(SUM(Sales.Quantity), 0) > 0) 
ORDER BY Products.[Description]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteProductSummary] TO PUBLIC
    AS [dbo];

