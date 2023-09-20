CREATE PROCEDURE [dbo].[GetDispenseConditionsYieldDaily]
(
	@From				DATETIME,
	@To				DATETIME,
	@EDISID			INT,
	@ProductID			INT,
	@IncludeCasks			BIT,
	@IncludeKegs			BIT,
	@IncludeMetric			BIT
)

AS

SET NOCOUNT ON

CREATE TABLE #TradingDispensed (TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, LiquidType INT NOT NULL, Quantity FLOAT NOT NULL, Pump INT NOT NULL, Drinks FLOAT NOT NULL)
CREATE NONCLUSTERED INDEX IX_TRADINGDISPENSED_LIQUIDTYPE ON #TradingDispensed (LiquidType)

DECLARE @BeerSold TABLE (TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @BeerDispensed TABLE (TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, ActualQuantity FLOAT NOT NULL, RoundedQuantity FLOAT NOT NULL)
DECLARE @CleaningWaste TABLE (TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @Cleans TABLE (TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, Pump INT NOT NULL)
DECLARE @NumberOfLinesCleaned TABLE (TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, NumberOfLinesCleaned INT NOT NULL)

DECLARE @Sites TABLE(EDISID INT NOT NULL)
DECLARE @SitePumpCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL PRIMARY KEY, PumpOffset INT NOT NULL)
DECLARE @SiteGroupID INT
DECLARE @ProductGroupID INT
DECLARE @Products TABLE(ProductID INT NOT NULL)
DECLARE @PrimaryProductID INT
DECLARE @SiteOnline  DATETIME

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

-- Find out which ProductIDs are relevant (plough through ProductGroups)
INSERT INTO @Products
(ProductID)
SELECT @ProductID AS ProductID WHERE @ProductID <> 0

SELECT @ProductGroupID = ProductGroupID
FROM ProductGroupProducts
JOIN ProductGroups ON ProductGroups.ID = ProductGroupProducts.ProductGroupID
WHERE TypeID = 1 AND ProductID = @ProductID

INSERT INTO @Products
(ProductID)
SELECT ProductID
FROM ProductGroupProducts
WHERE ProductGroupID = @ProductGroupID AND ProductID <> @ProductID

SELECT @PrimaryProductID = @ProductID

SELECT @PrimaryProductID = ProductID
FROM ProductGroupProducts
JOIN ProductGroups ON ProductGroups.ID = ProductGroupProducts.ProductGroupID
WHERE TypeID = 1 AND ProductGroupID = @ProductGroupID AND IsPrimary = 1


INSERT INTO #TradingDispensed
(TradingDate, ProductID, LiquidType, Quantity, Pump, Drinks)
SELECT	TradingDay,
	@PrimaryProductID,
	LiquidType,
	Pints,
	Pump + PumpOffset,
	EstimatedDrinks
FROM DispenseActions
JOIN Products ON Products.[ID] = DispenseActions.Product
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = DispenseActions.EDISID
JOIN @Products AS RelevantProducts ON RelevantProducts.ProductID = DispenseActions.Product
JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = DispenseActions.EDISID
WHERE TradingDay BETWEEN @From AND @To
AND DispenseActions.LiquidType IN (2,5,3)


-- All beer dispensed
INSERT INTO @BeerDispensed
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
INSERT INTO @BeerSold
(TradingDate, ProductID, Quantity)
SELECT  TradingDate,
	@PrimaryProductID,
	SUM(Sales.Quantity)
FROM Sales
JOIN MasterDates ON MasterDates.[ID] = Sales.MasterDateID
JOIN @Products AS RelevantProducts ON RelevantProducts.ProductID = Sales.ProductID
JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = MasterDates.EDISID
WHERE MasterDates.Date BETWEEN @From AND DATEADD(day, 1, @To)
GROUP BY TradingDate--, Sales.ProductID

DELETE
FROM @BeerSold
WHERE NOT (TradingDate BETWEEN @From AND @To)

-- Calculate daily yield
SELECT COALESCE(BeerDispensed.[TradingDate], BeerSold.[TradingDate], CleaningWaste.[TradingDate], NumberOfLinesCleaned.[TradingDate]) AS [TradingDate],
	COALESCE(BeerDispensed.ProductID, BeerSold.ProductID, CleaningWaste.ProductID, NumberOfLinesCleaned.ProductID) AS [ProductID],
	Products.IsCask AS [IsCask],
	ISNULL(BeerDispensed.ActualQuantity, 0) + ISNULL(CleaningWaste.Quantity, 0) AS [BeerMeasured],
	ISNULL(BeerDispensed.ActualQuantity, 0) AS [BeerDispensed],
	ISNULL(BeerDispensed.RoundedQuantity, 0) AS [DrinksDispensed],
	ISNULL(CleaningWaste.Quantity, 0) AS [BeerInLineCleaning],
	ISNULL(BeerSold.Quantity, 0) AS [Sold],
	ISNULL(BeerDispensed.RoundedQuantity, 0) - ISNULL(BeerDispensed.ActualQuantity, 0) AS [OperationalYield],
	ISNULL(BeerSold.Quantity, 0) - ISNULL(BeerDispensed.RoundedQuantity, 0) AS [RetailYield],
	ISNULL(BeerSold.Quantity, 0) - ISNULL(BeerDispensed.ActualQuantity, 0) - ISNULL(CleaningWaste.Quantity, 0) AS [OverallYield],
	ISNULL(NumberOfLinesCleaned, 0) AS [NumberOfLinesCleaned]
FROM @BeerDispensed AS BeerDispensed
FULL OUTER JOIN @BeerSold AS BeerSold ON (BeerDispensed.[TradingDate] = BeerSold.[TradingDate] AND BeerDispensed.ProductID = BeerSold.ProductID)
FULL OUTER JOIN @CleaningWaste AS CleaningWaste ON ((BeerDispensed.[TradingDate] = CleaningWaste.[TradingDate] AND BeerDispensed.ProductID = CleaningWaste.ProductID)
							OR (BeerSold.[TradingDate] = CleaningWaste.[TradingDate] AND BeerSold.ProductID = CleaningWaste.ProductID))
FULL OUTER JOIN @NumberOfLinesCleaned AS NumberOfLinesCleaned ON ((BeerDispensed.[TradingDate] = NumberOfLinesCleaned.[TradingDate] AND BeerDispensed.ProductID = NumberOfLinesCleaned.ProductID)
								OR (BeerSold.[TradingDate] = NumberOfLinesCleaned.[TradingDate] AND BeerSold.ProductID = NumberOfLinesCleaned.ProductID)
								OR (CleaningWaste.[TradingDate] = NumberOfLinesCleaned.[TradingDate] AND CleaningWaste.ProductID = NumberOfLinesCleaned.ProductID))
JOIN Products ON Products.[ID] = COALESCE(BeerDispensed.ProductID, BeerSold.ProductID, NumberOfLinesCleaned.ProductID,  CleaningWaste.ProductID)
WHERE (Products.IsCask = 0 OR @IncludeCasks = 1) AND (Products.IsCask = 1 OR @IncludeKegs = 1) AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
ORDER BY COALESCE(BeerDispensed.[TradingDate], BeerSold.[TradingDate], CleaningWaste.[TradingDate], NumberOfLinesCleaned.[TradingDate]),
	 COALESCE(BeerDispensed.ProductID, BeerSold.ProductID, CleaningWaste.ProductID, NumberOfLinesCleaned.ProductID)

DROP TABLE #TradingDispensed

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDispenseConditionsYieldDaily] TO PUBLIC
    AS [dbo];

