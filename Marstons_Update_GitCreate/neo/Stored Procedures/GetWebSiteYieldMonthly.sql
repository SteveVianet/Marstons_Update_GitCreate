﻿CREATE PROCEDURE [neo].[GetWebSiteYieldMonthly]
(
	@EDISID                 	INT,
	@From                   	DATETIME,
	@To                     	DATETIME,
	@ProductIDs					neo.IDTable READONLY 
	--@IncludeCasks           	BIT,
	--@IncludeKegs            	BIT,
	--@IncludeMetric          	BIT,
	--@ExcludeServiceIssues		BIT = 0
)

AS
BEGIN
--DECLARE      @EDISID                 INT = 899
--DECLARE      @From                   DATETIME = '2010-05-01'
--DECLARE      @To                     DATETIME = '2010-05-30'
--DECLARE      @IncludeCasks                 BIT = 1
--DECLARE      @IncludeKegs                  BIT = 1
--DECLARE      @IncludeMetric                BIT = 0

SET NOCOUNT ON
SET DATEFIRST 1

CREATE TABLE #TradingDispensed (TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, LiquidType INT NOT NULL, Quantity FLOAT NOT NULL, Pump INT NOT NULL, Drinks FLOAT NOT NULL, EDISID INT NOT NULL)
CREATE CLUSTERED INDEX IX_TRADINGDISPENSED_LIQUIDTYPE_PRODUCTID ON #TradingDispensed (LiquidType, ProductID)

CREATE TABLE #BeerSold (TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, Quantity FLOAT NOT NULL)
CREATE TABLE #BeerDispensed (TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, ActualQuantity FLOAT NOT NULL, RoundedQuantity FLOAT NOT NULL)
DECLARE @CleaningWaste TABLE (TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @Cleans TABLE (TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, Pump INT NOT NULL)
DECLARE @NumberOfLinesCleaned TABLE (TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, NumberOfLinesCleaned INT NOT NULL)

DECLARE @Sites TABLE(EDISID INT NOT NULL)
DECLARE @SitePumpCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL PRIMARY KEY, PumpOffset INT NOT NULL)
DECLARE @SiteGroupID INT
DECLARE @PrimaryProducts TABLE(ProductID INT NOT NULL, PrimaryProductID INT NOT NULL)
DECLARE @SiteOnline DATETIME

DECLARE @ProductIDsCount INT 
	SELECT @ProductIDsCount = COUNT(*) 
	FROM @ProductIDs

SELECT @SiteOnline = SiteOnline
FROM dbo.Sites
WHERE EDISID = @EDISID

-- Find out which EDISIDs are relevant (plough through SiteGroups)
INSERT INTO @Sites
(EDISID)
SELECT @EDISID AS EDISID

SELECT @SiteGroupID = SiteGroupID
FROM SiteGroupSites
JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
WHERE TypeID = 1 AND EDISID = @EDISID

INSERT INTO @Sites
(EDISID)
SELECT EDISID
FROM SiteGroupSites
WHERE SiteGroupID = @SiteGroupID AND EDISID <> @EDISID

INSERT INTO @SitePumpCounts (EDISID, MaxPump)
SELECT PumpSetup.EDISID, MAX(Pump)
FROM PumpSetup
JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
WHERE (ValidFrom <= @To)
AND (ISNULL(ValidTo, @To) >= @From)
AND (ISNULL(ValidTo, @To) >= @SiteOnline)
GROUP BY PumpSetup.EDISID

INSERT INTO @SitePumpOffsets (EDISID, PumpOffset)
SELECT MainCounts.EDISID, COALESCE(QuaternaryCounts.MaxPump+TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, SecondaryCounts.MaxPump, 0)
FROM @SitePumpCounts AS MainCounts
LEFT JOIN @SitePumpCounts AS SecondaryCounts ON SecondaryCounts.Counter+1 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS TertiaryCounts ON TertiaryCounts.Counter+2 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS QuaternaryCounts ON QuaternaryCounts.Counter+3 = MainCounts.Counter

-- Unroll ProductGroups so we can work out how to transform ProductIDs to their primaries
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

-- Get dispense for period and bodge about into 'trading hours'
INSERT INTO #TradingDispensed
(TradingDate, ProductID, LiquidType, Quantity, Pump, Drinks, EDISID)
SELECT DATEADD(Month, (DATEDIFF(Month, 0, TradingDay)), 0) AS [TradingDate],
      ISNULL(PrimaryProducts.PrimaryProductID, DispenseActions.Product) AS ProductID,
      LiquidType,
      Pints,
      Pump + PumpOffset,
      EstimatedDrinks,
      DispenseActions.EDISID
FROM DispenseActions
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = DispenseActions.EDISID
LEFT OUTER JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = DispenseActions.Product
JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = DispenseActions.EDISID
WHERE TradingDay BETWEEN @From AND @To
-- ## Not needed at present - keeping for future
--AND NOT EXISTS
--(
--	SELECT ID
--	FROM ServiceIssuesYield AS siy
--	WHERE siy.DateFrom <= TradingDay
--		AND (siy.DateTo IS NULL OR siy.DateTo >= TradingDay)
--		AND siy.RealEDISID = DispenseActions.EDISID
--		AND siy.ProductID = DispenseActions.Product
--		AND @ExcludeServiceIssues = 1
--)
AND DispenseActions.StartTime >= @SiteOnline
AND DispenseActions.LiquidType IN (2,5,3)

--DELETE
--FROM #TradingDispensed
--WHERE NOT (TradingDate BETWEEN @From AND @To)

-- All beer dispensed
INSERT INTO #BeerDispensed
(TradingDate, ProductID, ActualQuantity, RoundedQuantity)
SELECT  TradingDate,
      ProductID,
      SUM(Quantity),
      SUM(Drinks)
FROM #TradingDispensed AS TradingDispensed
JOIN Products ON Products.ID = TradingDispensed.ProductID
WHERE LiquidType = 2
GROUP BY TradingDate, ProductID

-- All beer dispensed during line clean
INSERT INTO @CleaningWaste
(TradingDate, ProductID, Quantity)
SELECT  TradingDate,
      ProductID, 
        SUM(Quantity)
FROM #TradingDispensed AS TradingDispensed
WHERE LiquidType = 5
-- ## Not needed at present - keeping for future
--AND NOT EXISTS
--(
--	SELECT ID
--	FROM ServiceIssuesYield AS siy
--	WHERE siy.DateFrom <= TradingDate
--		AND (siy.DateTo IS NULL OR siy.DateTo >= TradingDate)
--		AND siy.RealEDISID = TradingDispensed.EDISID
--		AND siy.ProductID = TradingDispensed.ProductID
--		AND @ExcludeServiceIssues = 1
--)
GROUP BY TradingDate, ProductID

-- Get line cleaning instances for each product/pump
INSERT INTO @Cleans
(TradingDate, ProductID, Pump)
SELECT  TradingDate,
      ProductID,
      Pump
FROM #TradingDispensed AS TradingDispensed
WHERE LiquidType = 3
GROUP BY TradingDate, ProductID, Pump

-- Get line cleaning instances for each product
INSERT INTO @NumberOfLinesCleaned
(TradingDate, ProductID, NumberOfLinesCleaned)
SELECT  TradingDate,
      ProductID,
      COUNT(DISTINCT Pump)
FROM @Cleans
GROUP BY TradingDate, ProductID

-- Get sales for period and bodge about into 'trading hours'
INSERT INTO #BeerSold
(TradingDate, ProductID, Quantity)
SELECT  
	  DATEADD(Month, (DATEDIFF(Month, 0, TradingDate)), 0) AS [TradingDate],
      ISNULL(PrimaryProducts.PrimaryProductID, Sales.ProductID) AS ProductID,
      SUM(Sales.Quantity)
FROM Sales
JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = Sales.EDISID
LEFT OUTER JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = Sales.ProductID
WHERE Sales.TradingDate BETWEEN @From AND @To
-- ## Not needed at present - keeping for future
--AND NOT EXISTS
--(
--	SELECT ID
--	FROM ServiceIssuesYield AS siy
--	WHERE siy.DateFrom <= Sales.TradingDate
--		AND (siy.DateTo IS NULL OR siy.DateTo >= Sales.TradingDate)
--		AND siy.RealEDISID = Sales.EDISID
--		AND siy.ProductID = Sales.ProductID
--		AND @ExcludeServiceIssues = 1
--)
GROUP BY DATEADD(Month, (DATEDIFF(Month, 0, TradingDate)), 0), ISNULL(PrimaryProducts.PrimaryProductID, Sales.ProductID)

--SELECT * FROM @BeerSold

-- Calculate daily yield
SELECT COALESCE(BeerDispensed.[TradingDate], BeerSold.[TradingDate], CleaningWaste.[TradingDate], NumberOfLinesCleaned.[TradingDate]) AS [TradingDate],
      Products.Description AS Product,
      Products.ID AS ProductID,
	  Products.CategoryID,
      ISNULL(BeerDispensed.ActualQuantity, 0) AS [BeerDispensed],
      ISNULL(BeerDispensed.RoundedQuantity, 0) AS [DrinksDispensed],      
      ISNULL(BeerSold.Quantity, 0) AS [Sold],
	  ISNULL(BeerDispensed.RoundedQuantity, 0) - ISNULL(BeerDispensed.ActualQuantity, 0) AS [PouringYield],
	  ISNULL(BeerSold.Quantity, 0) - ISNULL(BeerDispensed.RoundedQuantity, 0) AS [RetailYield],
	  ISNULL(BeerSold.Quantity, 0) - ISNULL(BeerDispensed.ActualQuantity, 0) 
		- CASE WHEN SiteOwner.IncludeCleaningWasteInOverallYield = 1 
		THEN ISNULL(CleaningWaste.Quantity, 0) * SiteOwner.CleaningCashValue
		ELSE 0 
		END AS [OverallYield],
	  (ISNULL(BeerDispensed.RoundedQuantity, 0) - ISNULL(BeerDispensed.ActualQuantity, 0)) * SiteOwner.PouringYieldCashValue AS [PouringCashValue],
	  (ISNULL(BeerSold.Quantity, 0) - ISNULL(BeerDispensed.RoundedQuantity, 0)) * SiteOwner.POSYieldCashValue AS [RetailCashValue],
	  	(ISNULL(BeerSold.Quantity, 0) - ISNULL(BeerDispensed.ActualQuantity, 0)) * SiteOwner.POSYieldCashValue 
		- CASE WHEN SiteOwner.IncludeCleaningWasteInOverallYield = 1
		THEN ISNULL(CleaningWaste.Quantity, 0) * SiteOwner.CleaningCashValue
		ELSE 0
		END
		AS [OverallCashValue],
		ISNULL(BeerDispensed.ActualQuantity, 0)
		+ CASE WHEN SiteOwner.IncludeCleaningWasteInOverallYield = 1 
		THEN ISNULL(CleaningWaste.Quantity, 0)
		ELSE 0 
		END AS [OverallBeerDispensed],
		CASE WHEN ISNULL(BeerDispensed.ActualQuantity, 0) > ISNULL(BeerDispensed.RoundedQuantity, 0)
		THEN ISNULL(BeerDispensed.RoundedQuantity, 0) - ISNULL(BeerDispensed.ActualQuantity, 0)
		ELSE 0 
		END AS [YieldLoss],
		CASE WHEN ISNULL(BeerDispensed.RoundedQuantity, 0) > ISNULL(BeerSold.Quantity, 0) 
		THEN ISNULL(BeerSold.Quantity, 0) - ISNULL(BeerDispensed.RoundedQuantity, 0)
		ELSE 0 
		END AS [RetailLoss],
		CASE WHEN ISNULL(BeerDispensed.ActualQuantity, 0) > ISNULL(BeerSold.Quantity, 0) 
		THEN ISNULL(BeerSold.Quantity, 0) - ISNULL(BeerDispensed.ActualQuantity, 0)
		ELSE 0 
		END AS [OverallLoss]
	  -- ## Not needed at present - keeping for future
	  --ISNULL(CleaningWaste.Quantity, 0) AS [BeerInLineCleaning],
      --ISNULL(BeerDispensed.RoundedQuantity, 0) - ISNULL(BeerDispensed.ActualQuantity, 0) AS [OperationalYield],
      --ISNULL(BeerSold.Quantity, 0) - ISNULL(BeerDispensed.RoundedQuantity, 0) AS [RetailYield],
      --ISNULL(BeerSold.Quantity, 0) - ISNULL(BeerDispensed.ActualQuantity, 0) - ISNULL(CleaningWaste.Quantity, 0) AS [OverallYield],
	  --Products.IsCask AS [IsCask],
   --   CASE WHEN Products.IsCask = 0 AND Products.IsMetric = 0 AND Products.IsWater = 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS [IsKeg],
      --ISNULL(NumberOfLinesCleaned, 0) AS [NumberOfLinesCleaned],
      --Thresholds.LowPouringYieldErrThreshold,
      --Thresholds.HighPouringYieldErrThreshold,
      --SiteOwner.POSYieldCashValue,
      --SiteOwner.CleaningCashValue,
      --SiteOwner.PouringYieldCashValue,
FROM #BeerDispensed AS BeerDispensed
FULL OUTER JOIN #BeerSold AS BeerSold ON (BeerDispensed.[TradingDate] = BeerSold.[TradingDate] AND BeerDispensed.ProductID = BeerSold.ProductID)
FULL OUTER JOIN @CleaningWaste AS CleaningWaste ON ((BeerDispensed.[TradingDate] = CleaningWaste.[TradingDate] AND BeerDispensed.ProductID = CleaningWaste.ProductID)
                                          OR (BeerSold.[TradingDate] = CleaningWaste.[TradingDate] AND BeerSold.ProductID = CleaningWaste.ProductID))
FULL OUTER JOIN @NumberOfLinesCleaned AS NumberOfLinesCleaned ON ((BeerDispensed.[TradingDate] = NumberOfLinesCleaned.[TradingDate] AND BeerDispensed.ProductID = 
NumberOfLinesCleaned.ProductID)
                                                OR (BeerSold.[TradingDate] = NumberOfLinesCleaned.[TradingDate] AND BeerSold.ProductID = 
NumberOfLinesCleaned.ProductID)
                                                OR (CleaningWaste.[TradingDate] = NumberOfLinesCleaned.[TradingDate] AND CleaningWaste.ProductID = 
NumberOfLinesCleaned.ProductID))
JOIN Products ON Products.[ID] = COALESCE(BeerDispensed.ProductID, BeerSold.ProductID, CleaningWaste.ProductID, NumberOfLinesCleaned.ProductID)

--Includes the error thresholds in the results to save looking them up individually in ASP. Sue me.
-- ## Not needed at present - keeping for future
--LEFT JOIN ProductCategories ON Products.CategoryID = ProductCategories.ID
--LEFT JOIN (SELECT ProductCategories.ID,
--		   ISNULL(SiteProductCategorySpecifications.LowPouringYieldErrThreshold, ProductCategories.LowPouringYieldErrThreshold) AS LowPouringYieldErrThreshold, 
--		   ISNULL(SiteProductCategorySpecifications.HighPouringYieldErrThreshold, ProductCategories.HighPouringYieldErrThreshold) AS HighPouringYieldErrThreshold
--		   FROM ProductCategories
--		   LEFT JOIN SiteProductCategorySpecifications ON ProductCategoryID = ID AND EDISID = @EDISID) 
--		   AS Thresholds ON Thresholds.ID = ProductCategories.ID
JOIN (
	SELECT EDISID, IncludeCleaningWasteInOverallYield, POSYieldCashValue, CleaningCashValue, PouringYieldCashValue
	FROM Sites
	JOIN Owners ON Owners.ID = Sites.OwnerID
	WHERE EDISID = @EDISID
) AS SiteOwner ON SiteOwner.EDISID = @EDISID
WHERE (Products.ID IN (SELECT ID FROM @ProductIDs) OR @ProductIDsCount = 0)
--WHERE (Products.IsCask = 0 OR @IncludeCasks = 1) AND (Products.IsCask = 1 OR @IncludeKegs = 1) AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
ORDER BY COALESCE(BeerDispensed.[TradingDate], BeerSold.[TradingDate], CleaningWaste.[TradingDate], NumberOfLinesCleaned.[TradingDate]),  Products.Description

DROP TABLE #TradingDispensed
DROP TABLE #BeerSold
DROP TABLE #BeerDispensed
END
GO
GRANT EXECUTE
    ON OBJECT::[neo].[GetWebSiteYieldMonthly] TO PUBLIC
    AS [dbo];

