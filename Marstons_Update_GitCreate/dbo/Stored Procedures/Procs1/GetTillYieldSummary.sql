CREATE PROCEDURE [dbo].[GetTillYieldSummary]
(
	@EDISID				INT = NULL,
	@LocalTimeNow		DATETIME,
	@RefreshEstateTLs	BIT = NULL,
	@SiteID				VARCHAR(100) = NULL
)
AS

-- Note that @RefreshEstateTLs is no longer used

SET NOCOUNT ON
SET DATEFIRST 1

CREATE TABLE #Sites(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY, POSYieldCashValue FLOAT, CleaningCashValue FLOAT, PouringYieldCashValue FLOAT, PrimaryEDISID INT) 
CREATE TABLE #PrimaryProducts(ProductID INT NOT NULL, PrimaryProductID INT NOT NULL) 
CREATE TABLE #WebSiteTLTillYield(EDISID INT, Product VARCHAR(100), [Percent] FLOAT, IsCask BIT, Sold FLOAT, CashValue FLOAT, RetailDispensed FLOAT)

DECLARE @From DATETIME
DECLARE @To DATETIME
DECLARE @SiteGroupID INT 				      
DECLARE @SiteOnline DATETIME
DECLARE @Today DATETIME

DECLARE @IgnoreLocalTime BIT = 0
DECLARE @PrimaryEDISID INT

CREATE TABLE #SiteYield(EDISID INT, ProductID INT, Product VARCHAR(100), QuantityDispensed FLOAT, DrinksDispensed FLOAT, OperationalYield FLOAT, Sold FLOAT, RetailYield FLOAT, IsCask BIT, MinPouringYield FLOAT, MaxPouringYield FLOAT, LowPouringYieldErrThreshold FLOAT, HighPouringYieldErrThreshold FLOAT, POSYieldCashValue FLOAT, CleaningCashValue FLOAT, PouringYieldCashValue FLOAT, BeerInLineCleaning FLOAT)
CREATE TABLE #SiteDispenseActions(EDISID INT, Pump INT, TradingDay DATETIME, LiquidType INT, ProductID INT, Pints FLOAT, EstimatedDrinks FLOAT, Location INT, AverageTemperature FLOAT)

IF YEAR(@LocalTimeNow) <= 1900
BEGIN
	SET @LocalTimeNow = GETDATE()
	SET @IgnoreLocalTime = 1
END

IF @SiteID IS NOT NULL
BEGIN
	SELECT @EDISID = EDISID
	FROM Sites
	WHERE SiteID = @SiteID
	
END

SELECT @SiteOnline = SiteOnline
FROM dbo.Sites
WHERE EDISID = @EDISID

SET @Today = CAST(CONVERT(VARCHAR(10), @LocalTimeNow, 12) AS DATETIME)
SET @To = DATEADD(DAY, -1, @Today)
SET @From = @To

-- Find out which EDISIDs are relevant (plough through SiteGroups) 
INSERT INTO #Sites (EDISID, POSYieldCashValue, CleaningCashValue, PouringYieldCashValue)
SELECT EDISID, POSYieldCashValue, CleaningCashValue, PouringYieldCashValue
FROM Sites
JOIN Owners ON Owners.ID = Sites.OwnerID
WHERE EDISID = @EDISID

SELECT @SiteGroupID = SiteGroupID
FROM SiteGroupSites
JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID WHERE TypeID = 1 AND EDISID = @EDISID

INSERT INTO #Sites (EDISID, POSYieldCashValue, CleaningCashValue, PouringYieldCashValue)
SELECT SiteGroupSites.EDISID, POSYieldCashValue, CleaningCashValue, PouringYieldCashValue
FROM SiteGroupSites
JOIN Sites ON Sites.EDISID = SiteGroupSites.EDISID
JOIN Owners ON Owners.ID = Sites.OwnerID
WHERE SiteGroupSites.SiteGroupID = @SiteGroupID 
AND SiteGroupSites.EDISID <> @EDISID

IF @SiteGroupID > 0
BEGIN
	SELECT @PrimaryEDISID = EDISID
	FROM SiteGroupSites
	WHERE SiteGroupID = @SiteGroupID
	AND IsPrimary = 1

	UPDATE #Sites SET PrimaryEDISID = @PrimaryEDISID

END
ELSE
BEGIN
    SET @PrimaryEDISID = @EDISID

END

INSERT INTO #PrimaryProducts(ProductID, PrimaryProductID) 
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

INSERT INTO #SiteDispenseActions
(EDISID, Pump, TradingDay, LiquidType, ProductID, Pints, EstimatedDrinks, Location, AverageTemperature)
SELECT	DispenseActions.EDISID,
		DispenseActions.Pump,
		TradingDay,
		LiquidType,
		Product,
		Pints,
		EstimatedDrinks,
		Location,
		AverageTemperature
FROM DispenseActions WITH (INDEX ([IX_DispenseActions_ForQuality]))
WHERE DispenseActions.EDISID IN (SELECT EDISID FROM #Sites) AND
		  TradingDay BETWEEN @From AND @To AND
		  TradingDay >= @SiteOnline AND
		  LiquidType IN (2, 3, 5) AND
		  Pints >= 0 --AND
		  --Location IS NOT NULL AND
		  --AverageTemperature IS NOT NULL



INSERT INTO #SiteYield
(EDISID, ProductID, Product, QuantityDispensed, DrinksDispensed, OperationalYield, Sold, RetailYield, IsCask, MinPouringYield, MaxPouringYield, LowPouringYieldErrThreshold, HighPouringYieldErrThreshold, POSYieldCashValue, CleaningCashValue, PouringYieldCashValue, BeerInLineCleaning)
SELECT  COALESCE(DispenseActions.EDISID, Sales.EDISID) AS EDISID,
		Products.[ID] AS ProductID,
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
		COALESCE(DispenseActions.POSYieldCashValue, Sales.POSYieldCashValue) AS POSYieldCashValue,
		COALESCE(DispenseActions.CleaningCashValue, Sales.CleaningCashValue) AS CleaningCashValue,
		COALESCE(DispenseActions.PouringYieldCashValue, Sales.PouringYieldCashValue) AS PouringYieldCashValue,
		ISNULL(SUM(DispenseActions.BeerInLineCleaning),0) AS BeerInLineCleaning
FROM Products 
FULL OUTER JOIN (
	SELECT	DispenseActions.EDISID,
			ISNULL(PrimaryProducts.PrimaryProductID, DispenseActions.ProductID) AS ProductID, 
			SUM(CASE WHEN LiquidType = 2 THEN DispenseActions.Pints ELSE 0 END) AS Pints,
			SUM(CASE WHEN LiquidType = 2 THEN DispenseActions.EstimatedDrinks ELSE 0 END) AS EstimatedDrinks,
			POSYieldCashValue,
			CleaningCashValue,
			PouringYieldCashValue,
			SUM(CASE WHEN LiquidType = 5 THEN DispenseActions.Pints ELSE 0 END) AS BeerInLineCleaning
	FROM #SiteDispenseActions AS DispenseActions
	JOIN #Sites AS RelevantSites
      ON RelevantSites.EDISID = DispenseActions.EDISID
    FULL OUTER JOIN #PrimaryProducts AS PrimaryProducts
      ON PrimaryProducts.ProductID = DispenseActions.ProductID
	WHERE LiquidType IN (2, 5)
	AND NOT EXISTS
	(
		SELECT ID
		FROM ServiceIssuesYield AS siy
		WHERE siy.DateFrom <= TradingDay
			AND (siy.DateTo IS NULL OR siy.DateTo >= TradingDay)
			AND siy.RealEDISID = DispenseActions.EDISID
			AND siy.ProductID = DispenseActions.ProductID
	)
	GROUP BY DispenseActions.EDISID, ISNULL(PrimaryProducts.PrimaryProductID, DispenseActions.ProductID), POSYieldCashValue, CleaningCashValue, PouringYieldCashValue
	) AS DispenseActions ON Products.ID = DispenseActions.ProductID
FULL OUTER JOIN (
	SELECT	Sales.EDISID,
			ISNULL(PrimaryProducts.PrimaryProductID, Sales.ProductID) AS ProductID,
			SUM(Sales.Quantity) AS Quantity,
			POSYieldCashValue,
			CleaningCashValue,
			PouringYieldCashValue
	FROM Sales
	JOIN #Sites AS RelevantSites
	  ON RelevantSites.EDISID = Sales.EDISID
    FULL OUTER JOIN #PrimaryProducts AS PrimaryProducts
      ON PrimaryProducts.ProductID = Sales.ProductID
	WHERE (Sales.TradingDate BETWEEN @From AND @To)
	  AND Sales.TradingDate >= @SiteOnline
	  AND NOT EXISTS
		(
			SELECT ID
			FROM ServiceIssuesYield AS siy
			WHERE siy.DateFrom <= TradingDate
				AND (siy.DateTo IS NULL OR siy.DateTo >= TradingDate)
				AND siy.RealEDISID = Sales.EDISID
				AND siy.ProductID = Sales.ProductID
		)
	GROUP BY Sales.EDISID, ISNULL(PrimaryProducts.PrimaryProductID, Sales.ProductID), POSYieldCashValue, CleaningCashValue, PouringYieldCashValue
	) AS Sales
  ON Products.ID = Sales.ProductID AND Sales.EDISID = COALESCE(DispenseActions.EDISID, Sales.EDISID)
JOIN ProductCategories
  ON ProductCategories.ID = Products.CategoryID 
FULL OUTER JOIN (
	SELECT ProductCategoryID, MinimumPouringYield, MaximumPouringYield, HighPouringYieldErrThreshold, LowPouringYieldErrThreshold
	FROM SiteProductCategorySpecifications
	JOIN #Sites AS RelevantSites
	  ON RelevantSites.EDISID = SiteProductCategorySpecifications.EDISID
	) AS SiteProductCategorySpecs
  ON SiteProductCategorySpecs.ProductCategoryID = ProductCategories.ID
WHERE Products.IsWater = 0
AND Products.IsMetric = 0
GROUP BY COALESCE(DispenseActions.EDISID, Sales.EDISID), Products.[ID], Products.[Description], Products.IsCask, ISNULL(SiteProductCategorySpecs.MinimumPouringYield, ProductCategories.MinimumPouringYield), ISNULL(SiteProductCategorySpecs.MaximumPouringYield, ProductCategories.MaximumPouringYield), 	ISNULL(SiteProductCategorySpecs.LowPouringYieldErrThreshold, ProductCategories.LowPouringYieldErrThreshold), ISNULL(SiteProductCategorySpecs.HighPouringYieldErrThreshold, ProductCategories.HighPouringYieldErrThreshold), COALESCE(DispenseActions.POSYieldCashValue, Sales.POSYieldCashValue), COALESCE(DispenseActions.CleaningCashValue, Sales.CleaningCashValue), COALESCE(DispenseActions.PouringYieldCashValue, Sales.PouringYieldCashValue)
HAVING (ISNULL(SUM(DispenseActions.Pints),0) > 0 OR ISNULL(SUM(Sales.Quantity), 0) > 0) 
ORDER BY Products.[Description]


INSERT INTO #WebSiteTLTillYield
(EDISID, Product, [Percent], IsCask, Sold, CashValue, RetailDispensed)
SELECT @PrimaryEDISID,
       Product,
       (dbo.fnConvertSiteDispenseVolume(@PrimaryEDISID, SUM(Sold)) / CASE WHEN SUM(DrinksDispensed) = 0 THEN 1 ELSE SUM(DrinksDispensed) END) * 100,
       IsCask,
       SUM(Sold),
       POSYieldCashValue,
       SUM(DrinksDispensed)
FROM #SiteYield
WHERE IsCask = 0
GROUP BY Product, IsCask, POSYieldCashValue


INSERT INTO #WebSiteTLTillYield
(EDISID, Product, [Percent], IsCask, Sold, CashValue, RetailDispensed)
SELECT @PrimaryEDISID,
       'Consolidated Casks',
       (dbo.fnConvertSiteDispenseVolume(@PrimaryEDISID, SUM(Sold)) / CASE WHEN SUM(DrinksDispensed) = 0 THEN 1 ELSE SUM(DrinksDispensed) END) * 100,
       1,
       SUM(Sold),
       POSYieldCashValue,
       SUM(DrinksDispensed)
FROM #SiteYield
WHERE IsCask = 1
GROUP BY POSYieldCashValue



--WE NEED THIS!
--INSERT INTO WebSiteTLTillYield
--(EDISID, Product, [Percent], IsCask, Sold, CashValue, RetailDispensed)
SELECT EDISID, Product, [Percent], IsCask, Sold, CashValue, RetailDispensed
FROM #WebSiteTLTillYield


DROP TABLE #Sites
DROP TABLE #PrimaryProducts
DROP TABLE #SiteDispenseActions
DROP TABLE #SiteYield
DROP TABLE #WebSiteTLTillYield
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTillYieldSummary] TO PUBLIC
    AS [dbo];

