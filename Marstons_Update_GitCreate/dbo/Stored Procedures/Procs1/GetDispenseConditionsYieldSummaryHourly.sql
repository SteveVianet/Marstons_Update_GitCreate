CREATE PROCEDURE [dbo].[GetDispenseConditionsYieldSummaryHourly]
(
	@From				DATETIME,
	@To				DATETIME,
	@EDISID			INT,
	@IncludeCasks			BIT,
	@IncludeKegs			BIT,
	@IncludeMetric			BIT,
	@ProductCategoryID		INT = NULL
)

AS

SET NOCOUNT ON

CREATE TABLE #TradingDispensed (DateAndTime DATETIME NOT NULL, TradingDateAndTime DATETIME NOT NULL, ProductID INT NOT NULL, LiquidType INT NOT NULL, Quantity FLOAT NOT NULL, Pump INT NOT NULL, Drinks FLOAT NOT NULL)
CREATE NONCLUSTERED INDEX IX_TRADINGDISPENSED_LIQUIDTYPE ON #TradingDispensed (LiquidType)

DECLARE @TradingSold TABLE (DateAndHour DATETIME NOT NULL, TradingDateAndHour DATETIME NOT NULL, Quantity FLOAT NOT NULL)

DECLARE @BeerSold TABLE (TradingDateAndHour DATETIME NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @BeerDispensed TABLE (TradingDateAndHour DATETIME NOT NULL, ActualQuantity FLOAT NOT NULL, RoundedQuantity FLOAT NOT NULL)
DECLARE @CleaningWaste TABLE (TradingDateAndHour DATETIME NOT NULL,Quantity FLOAT NOT NULL)
DECLARE @Cleans TABLE (TradingDateAndHour DATETIME NOT NULL, Pump INT NOT NULL)
DECLARE @NumberOfLinesCleaned TABLE (TradingDateAndHour DATETIME NOT NULL, NumberOfLinesCleaned INT NOT NULL)

DECLARE @TradingDayBeginsAt INT
SET @TradingDayBeginsAt = 5

DECLARE @Sites TABLE(EDISID INT NOT NULL)
DECLARE @SitePumpCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL PRIMARY KEY, PumpOffset INT NOT NULL)
DECLARE @SiteGroupID INT
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

-- Get dispense for period and bodge about into 'trading hours'
INSERT INTO #TradingDispensed
([DateAndTime], TradingDateAndTime, ProductID, LiquidType, Quantity, Pump, Drinks)
SELECT  StartTime,
	CAST(DATEADD(dd, 0, DATEDIFF(dd, 0, TradingDay)) + CONVERT(VARCHAR(10), StartTime, 108) AS DATETIME) AS TradingDateAndTime,
	Products.ID,
	LiquidType,
	Pints,
	Pump + PumpOffset,
	EstimatedDrinks
FROM DispenseActions
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = DispenseActions.EDISID
JOIN Products ON Products.[ID] = DispenseActions.Product
JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = DispenseActions.EDISID
WHERE TradingDay BETWEEN @From AND @To
AND DispenseActions.LiquidType IN (2,5,3)
AND (Products.IsCask = 0 OR @IncludeCasks = 1) AND (Products.IsCask = 1 OR @IncludeKegs = 1) AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
AND (Products.CategoryID = @ProductCategoryID OR @ProductCategoryID IS NULL)


-- All beer dispensed
INSERT INTO @BeerDispensed
(TradingDateAndHour, ActualQuantity, RoundedQuantity)
SELECT  DATEADD(hour, DATEPART(hour, TradingDateAndTime), CAST(CONVERT(VARCHAR(10), TradingDateAndTime, 12) AS DATETIME)),
	SUM(Quantity),
	SUM(Drinks)
	--SUM(dbo.fnGetSiteDrinkVolume(@EDISID, Quantity*100, Products.[ID]))
FROM #TradingDispensed AS TradingDispensed
JOIN Products ON Products.ID = TradingDispensed.ProductID
WHERE LiquidType = 2
GROUP BY DATEADD(hour, DATEPART(hour, TradingDateAndTime), CAST(CONVERT(VARCHAR(10), TradingDateAndTime, 12) AS DATETIME))

-- All beer dispensed during line clean
INSERT INTO @CleaningWaste
(TradingDateAndHour, Quantity)
SELECT  DATEADD(hour, DATEPART(hour, TradingDateAndTime), CAST(CONVERT(VARCHAR(10), TradingDateAndTime, 12) AS DATETIME)),
        SUM(Quantity)
FROM #TradingDispensed AS TradingDispensed
WHERE LiquidType = 5
GROUP BY DATEADD(hour, DATEPART(hour, TradingDateAndTime), CAST(CONVERT(VARCHAR(10), TradingDateAndTime, 12) AS DATETIME))

-- Get line cleaning instances for each product/pump
INSERT INTO @Cleans
(TradingDateAndHour, Pump)
SELECT  DATEADD(hour, DATEPART(hour, TradingDateAndTime), CAST(CONVERT(VARCHAR(10), TradingDateAndTime, 12) AS DATETIME)),
	Pump
FROM #TradingDispensed AS TradingDispensed
WHERE LiquidType = 3
GROUP BY DATEADD(hour, DATEPART(hour, TradingDateAndTime), CAST(CONVERT(VARCHAR(10), TradingDateAndTime, 12) AS DATETIME)),
	 Pump

-- Get line cleaning instances for each product
INSERT INTO @NumberOfLinesCleaned
(TradingDateAndHour, NumberOfLinesCleaned)
SELECT  TradingDateAndHour,
	COUNT(DISTINCT Pump)
FROM @Cleans
GROUP BY TradingDateAndHour

-- Get sales for period and bodge about into 'trading hours'
INSERT INTO @TradingSold
(DateAndHour, TradingDateAndHour, Quantity)
SELECT  DATEADD(hh, DATEPART(hh, Sales.[SaleTime]), MasterDates.[Date]),
	CASE WHEN DATEPART(hour, Sales.[SaleTime]) <= @TradingDayBeginsAt THEN DATEADD(Day, -1, DATEADD(hh, DATEPART(hh, Sales.[SaleTime]), MasterDates.[Date])) ELSE DATEADD(hh, DATEPART(hh, Sales.[SaleTime]), MasterDates.[Date]) END,
	SUM(Sales.Quantity)
FROM Sales
JOIN MasterDates ON MasterDates.[ID] = Sales.MasterDateID
JOIN Products ON Products.ID = Sales.ProductID
JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = MasterDates.EDISID
WHERE MasterDates.[Date] BETWEEN @From AND DATEADD(dd,1,@To)
AND (Products.IsCask = 0 OR @IncludeCasks = 1) AND (Products.IsCask = 1 OR @IncludeKegs = 1) AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
AND (Products.CategoryID = @ProductCategoryID OR @ProductCategoryID IS NULL)
GROUP BY DATEADD(hh, DATEPART(hh, Sales.[SaleTime]), MasterDates.[Date]),
	 CASE WHEN DATEPART(hour, Sales.[SaleTime]) <= @TradingDayBeginsAt THEN DATEADD(Day, -1, DATEADD(hh, DATEPART(hh, Sales.[SaleTime]), MasterDates.[Date])) ELSE DATEADD(hh, DATEPART(hh, Sales.[SaleTime]), MasterDates.[Date]) END

DELETE
FROM @TradingSold
WHERE [DateAndHour] < DATEADD(hh,@TradingDayBeginsAt,@From)

DELETE
FROM @TradingSold
WHERE [DateAndHour] >= DATEADD(hh,@TradingDayBeginsAt,DATEADD(dd,1,@To))

-- Get summary of sales
INSERT INTO @BeerSold
(TradingDateAndHour, Quantity)
SELECT TradingDateAndHour,
	SUM(Quantity)
FROM @TradingSold
GROUP BY TradingDateAndHour

-- Calculate daily yield
SELECT COALESCE(BeerDispensed.[TradingDateAndHour], BeerSold.[TradingDateAndHour], CleaningWaste.[TradingDateAndHour], NumberOfLinesCleaned.[TradingDateAndHour]) AS [TradingDate],
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
FULL OUTER JOIN @BeerSold AS BeerSold ON BeerDispensed.[TradingDateAndHour] = BeerSold.[TradingDateAndHour]
FULL OUTER JOIN @CleaningWaste AS CleaningWaste ON BeerDispensed.[TradingDateAndHour] = CleaningWaste.[TradingDateAndHour] OR BeerSold.[TradingDateAndHour] = CleaningWaste.[TradingDateAndHour]
FULL OUTER JOIN @NumberOfLinesCleaned AS NumberOfLinesCleaned ON BeerDispensed.[TradingDateAndHour] = NumberOfLinesCleaned.[TradingDateAndHour] OR BeerSold.[TradingDateAndHour] = NumberOfLinesCleaned.[TradingDateAndHour] OR CleaningWaste.[TradingDateAndHour] = NumberOfLinesCleaned.[TradingDateAndHour]
ORDER BY COALESCE(BeerDispensed.[TradingDateAndHour], BeerSold.[TradingDateAndHour], CleaningWaste.[TradingDateAndHour], NumberOfLinesCleaned.[TradingDateAndHour])

DROP TABLE #TradingDispensed

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDispenseConditionsYieldSummaryHourly] TO PUBLIC
    AS [dbo];

