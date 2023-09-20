CREATE PROCEDURE [dbo].[ExportScheduleYield]
	@ScheduleID		INT,
	@From			DATE = NULL,
	@To				DATE = NULL

AS

DECLARE	@IncludeCasks	BIT = 1
DECLARE	@IncludeKegs	BIT = 1
DECLARE	@IncludeMetric	BIT = 0

SET NOCOUNT ON

IF @From IS NULL AND @To IS NULL
BEGIN
	SELECT @From = DATEADD(DAY, -5, GETDATE()), @To = GETDATE()
END

CREATE TABLE #TradingDispensed (EDISID INT NOT NULL, TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, LiquidType INT NOT NULL, Quantity FLOAT NOT NULL, Drinks FLOAT NOT NULL)
CREATE CLUSTERED INDEX IX_TRADINGDISPENSED_LIQUIDTYPE_PRODUCTID ON #TradingDispensed (LiquidType, ProductID)

DECLARE @BeerSold TABLE (EDISID INT NOT NULL, TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @BeerDispensed TABLE (EDISID INT NOT NULL, TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, ActualQuantity FLOAT NOT NULL, RoundedQuantity FLOAT NOT NULL)
DECLARE @CleaningWaste TABLE (EDISID INT NOT NULL, TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @Cleans TABLE (EDISID INT NOT NULL, TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, Pump INT NOT NULL)
DECLARE @AliasMap TABLE (ProductID INT NOT NULL, ProductAlias VARCHAR(255) NOT NULL)

DECLARE @Sites TABLE(EDISID INT NOT NULL, SiteOnline DATETIME NOT NULL)
DECLARE @PrimaryProducts TABLE(ProductID INT NOT NULL, PrimaryProductID INT NOT NULL)

-- Find out which EDISIDs are relevant (plough through SiteGroups)
INSERT INTO @Sites
(EDISID, SiteOnline)
SELECT Sites.EDISID, Sites.SiteOnline
FROM ScheduleSites
JOIN Sites ON Sites.EDISID = ScheduleSites.EDISID
WHERE 
	ScheduleSites.ScheduleID = @ScheduleID
AND	Sites.Hidden = 0

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
(EDISID, TradingDate, ProductID, LiquidType, Quantity, Drinks)
SELECT	
	DispenseActions.EDISID,
	DATEADD(Hour, DATEPART(Hour, [StartTime]), TradingDay) AS [TradingDate],
	ISNULL(PrimaryProducts.PrimaryProductID, DispenseActions.Product) AS ProductID,
	LiquidType,
	Pints,
	EstimatedDrinks
FROM DispenseActions WITH (NOLOCK)
LEFT OUTER JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = DispenseActions.Product
JOIN @Sites AS RelevantSites 
	ON RelevantSites.EDISID = DispenseActions.EDISID 
WHERE TradingDay BETWEEN @From AND @To
AND TradingDay >= RelevantSites.SiteOnline
AND DispenseActions.LiquidType IN (2,5,3)


-- All beer dispensed
INSERT INTO @BeerDispensed
(EDISID, TradingDate, ProductID, ActualQuantity, RoundedQuantity)
SELECT  
	EDISID,
	TradingDate,
	ProductID,
	SUM(Quantity),
	SUM(Drinks)
FROM #TradingDispensed AS TradingDispensed
JOIN Products ON Products.ID = TradingDispensed.ProductID
WHERE LiquidType = 2
GROUP BY EDISID, TradingDate, ProductID

-- All beer dispensed during line clean
INSERT INTO @CleaningWaste
(EDISID, TradingDate, ProductID, Quantity)
SELECT
	EDISID,
	TradingDate,
	ProductID, 
    SUM(Quantity)
FROM #TradingDispensed AS TradingDispensed
WHERE LiquidType = 5
GROUP BY EDISID, TradingDate, ProductID

-- Get sales for period and bodge about into 'trading hours'
INSERT INTO @BeerSold
(EDISID, TradingDate, ProductID, Quantity)
SELECT  
	Sales.EDISID,
	DATEADD(HOUR, DATEPART(HOUR, Sales.SaleTime), Sales.TradingDate),
	Sales.ProductID,
	SUM(Sales.Quantity)
FROM Sales
JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = Sales.EDISID
WHERE TradingDate BETWEEN @From AND @To
GROUP BY 
	Sales.EDISID,
	DATEADD(HOUR, DATEPART(HOUR, Sales.SaleTime), Sales.TradingDate), 
	Sales.ProductID

-- Make nasty mapping for Zonal codes...
INSERT INTO @AliasMap
(ProductID, ProductAlias)
SELECT ProductID, MIN(Alias)
FROM ProductAlias
WHERE Alias LIKE '100000%'
GROUP BY ProductID

-- Calculate daily yield
SELECT 
	Sites.SiteID,
	COALESCE(BeerDispensed.[TradingDate], BeerSold.[TradingDate], CleaningWaste.[TradingDate]) AS [TradingDateAndTime],
	Products.[Description] AS Product,
	ISNULL(AliasMap.ProductAlias,'NO-CODE') AS ProductCode,
	ISNULL(BeerDispensed.ActualQuantity, 0) AS [BeerDispensed],
	ISNULL(BeerDispensed.RoundedQuantity, 0) AS [DrinksDispensed],
	ISNULL(BeerDispensed.RoundedQuantity, 0) - ISNULL(BeerDispensed.ActualQuantity, 0) AS [PouringYield],
	ISNULL(BeerSold.Quantity, 0) AS [Sold],
	ISNULL(BeerSold.Quantity, 0) - ISNULL(BeerDispensed.RoundedQuantity, 0) AS [TillYield]
FROM @BeerDispensed AS BeerDispensed
FULL OUTER JOIN @BeerSold AS BeerSold 
	ON (BeerDispensed.[TradingDate] = BeerSold.[TradingDate] AND BeerDispensed.ProductID = BeerSold.ProductID)
	AND BeerSold.EDISID = BeerDispensed.EDISID
FULL OUTER JOIN @CleaningWaste AS CleaningWaste 
	ON ((BeerDispensed.[TradingDate] = CleaningWaste.[TradingDate] AND BeerDispensed.ProductID = CleaningWaste.ProductID)
		OR (BeerSold.[TradingDate] = CleaningWaste.[TradingDate] AND BeerSold.ProductID = CleaningWaste.ProductID))
	AND CleaningWaste.EDISID = BeerDispensed.EDISID
JOIN Products ON Products.[ID] = COALESCE(BeerDispensed.ProductID, BeerSold.ProductID, CleaningWaste.ProductID)
LEFT JOIN ProductCategories ON Products.CategoryID = ProductCategories.ID
JOIN Sites ON Sites.EDISID = COALESCE(BeerDispensed.[EDISID], BeerSold.[EDISID], CleaningWaste.[EDISID])
LEFT JOIN @AliasMap AS AliasMap ON AliasMap.ProductID = COALESCE(BeerDispensed.ProductID, BeerSold.ProductID, CleaningWaste.ProductID)
WHERE (Products.IsCask = 0 OR @IncludeCasks = 1) AND (Products.IsCask = 1 OR @IncludeKegs = 1) AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
ORDER BY Sites.SiteID, COALESCE(BeerDispensed.[TradingDate], BeerSold.[TradingDate], CleaningWaste.[TradingDate]), Products.[Description]

DROP TABLE #TradingDispensed

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ExportScheduleYield] TO PUBLIC
    AS [dbo];

