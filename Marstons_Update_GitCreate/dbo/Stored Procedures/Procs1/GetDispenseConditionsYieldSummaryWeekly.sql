CREATE PROCEDURE [dbo].[GetDispenseConditionsYieldSummaryWeekly]
(
	@From			DATETIME,
	@To			DATETIME,
	@EDISID		INT,
	@IncludeCasks		BIT,
	@IncludeKegs		BIT = 1,
	@IncludeMetric		BIT = 1
)

AS

SET NOCOUNT ON
SET DATEFIRST 1

CREATE TABLE #TradingDispensed (DateAndTime DATETIME, TradingDateAndTime DATETIME, ProductID INT, LiquidType INT, Quantity FLOAT, Pump INT, Drinks FLOAT)
DECLARE @TradingSold TABLE(TradingDateAndHour DATETIME, Quantity FLOAT)
DECLARE @BeerSold TABLE(TradingDate DATETIME, Quantity FLOAT)
DECLARE @BeerDispensed TABLE(TradingDateAndHour DATETIME, ActualQuantity FLOAT, RoundedQuantity FLOAT)
DECLARE @CleaningWaste TABLE(TradingDateAndHour DATETIME, Quantity FLOAT)
DECLARE @NumberOfLinesCleaned TABLE(TradingDateAndHour DATETIME, NumberOfLinesCleaned INT)
DECLARE @HourlyYield TABLE (TradingDateAndHour DATETIME, BeerMeasured FLOAT, BeerDispensed FLOAT, DrinksDispensed FLOAT, BeerInLineCleaning FLOAT, Sold FLOAT, OperationalYield FLOAT, RetailYield FLOAT, OverallYield FLOAT, NumberOfLinesCleaned INT)

DECLARE @TradingDayBeginsAt INT
SET @TradingDayBeginsAt = 5

DECLARE @Sites TABLE(EDISID INT NOT NULL)
DECLARE @SitePumpCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL PRIMARY KEY, PumpOffset INT NOT NULL)

DECLARE @SiteOnline  DATETIME
DECLARE @SiteGroupID INT

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


-- All beer dispensed
INSERT INTO @BeerDispensed
(TradingDateAndHour, ActualQuantity, RoundedQuantity)
SELECT  DATEADD(dw, -DATEPART(dw, CAST(CONVERT(VARCHAR(10), [TradingDateAndTime], 12) AS DATETIME)) + 1, CAST(CONVERT(VARCHAR(10), [TradingDateAndTime], 12) AS DATETIME)),
	SUM(Quantity),
	SUM(Drinks)
	--SUM(dbo.fnGetSiteDrinkVolume(@EDISID, Quantity*100, Products.[ID]))
FROM #TradingDispensed AS TradingDispensed
JOIN Products ON Products.ID = TradingDispensed.ProductID
WHERE LiquidType = 2
GROUP BY DATEADD(dw, -DATEPART(dw, CAST(CONVERT(VARCHAR(10), [TradingDateAndTime], 12) AS DATETIME)) + 1, CAST(CONVERT(VARCHAR(10), [TradingDateAndTime], 12)  AS DATETIME))

-- All beer dispensed during line clean
INSERT INTO @CleaningWaste
(TradingDateAndHour, Quantity)
SELECT  DATEADD(dw, -DATEPART(dw, CAST(CONVERT(VARCHAR(10), [TradingDateAndTime], 12) AS DATETIME)) + 1, CAST(CONVERT(VARCHAR(10), [TradingDateAndTime], 12) AS DATETIME)),
        SUM(Quantity)
FROM #TradingDispensed AS TradingDispensed
WHERE LiquidType = 5
GROUP BY DATEADD(dw, -DATEPART(dw, CAST(CONVERT(VARCHAR(10), [TradingDateAndTime], 12) AS DATETIME)) + 1, CAST(CONVERT(VARCHAR(10), [TradingDateAndTime], 12) AS DATETIME))
-- Get line cleaning instances

INSERT INTO @NumberOfLinesCleaned
(TradingDateAndHour,  NumberOfLinesCleaned)
SELECT  DATEADD(dw, -DATEPART(dw, CAST(CONVERT(VARCHAR(10), [TradingDateAndTime], 12) AS DATETIME)) + 1, CAST(CONVERT(VARCHAR(10), [TradingDateAndTime], 12) AS DATETIME)),
	COUNT(DISTINCT Pump)
FROM #TradingDispensed AS TradingDispensed
WHERE LiquidType = 3
GROUP BY DATEADD(dw, -DATEPART(dw, CAST(CONVERT(VARCHAR(10), [TradingDateAndTime], 12) AS DATETIME)) + 1, CAST(CONVERT(VARCHAR(10), [TradingDateAndTime], 12) AS DATETIME))

-- Get sales for period and bodge about into 'trading hours'
INSERT INTO @TradingSold
(TradingDateAndHour, Quantity)
SELECT	DATEADD(hour, DATEPART(Hour, Sales.[SaleTime]), CAST(CONVERT(VARCHAR(10), DATEADD(hh,@TradingDayBeginsAt*-1,CONVERT(VARCHAR(19), DATEADD(ss, DATEPART(ss, Sales.[SaleTime]), DATEADD(mi, DATEPART(mi, Sales.[SaleTime]), DATEADD(hh, DATEPART(hh, Sales.[SaleTime]), MasterDates.[Date]))), 20)), 12) AS DATETIME)),
	SUM(Sales.Quantity)
FROM Sales
JOIN MasterDates ON MasterDates.[ID] = Sales.MasterDateID
JOIN Products ON Products.[ID] = Sales.ProductID
JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = MasterDates.EDISID
WHERE MasterDates.[Date] BETWEEN @From AND DATEADD(dd,1,@To)
AND (Products.IsCask = 0 OR @IncludeCasks = 1) AND (Products.IsCask = 1 OR @IncludeKegs = 1) AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
GROUP BY DATEADD(hour, DATEPART(Hour, Sales.[SaleTime]), CAST(CONVERT(VARCHAR(10), DATEADD(hh,@TradingDayBeginsAt*-1,CONVERT(VARCHAR(19), DATEADD(ss, DATEPART(ss, Sales.[SaleTime]), DATEADD(mi, DATEPART(mi, Sales.[SaleTime]), DATEADD(hh, DATEPART(hh, Sales.[SaleTime]), MasterDates.[Date]))), 20)), 12) AS DATETIME)),
	DATEPART(Hour, Sales.[SaleTime])

DELETE
FROM @TradingSold
WHERE [TradingDateAndHour] < DATEADD(hh,@TradingDayBeginsAt,@From)

DELETE
FROM @TradingSold
WHERE [TradingDateAndHour] >= DATEADD(hh,@TradingDayBeginsAt,DATEADD(dd,1,@To))

INSERT INTO @BeerSold
(TradingDate, Quantity)
SELECT DATEADD(dw, -DATEPART(dw, CAST(CONVERT(VARCHAR(10), [TradingDateAndHour], 12) AS DATETIME)) + 1, CAST(CONVERT(VARCHAR(10), [TradingDateAndHour], 12) AS DATETIME)),
       SUM(Quantity)
FROM @TradingSold
GROUP BY DATEADD(dw, -DATEPART(dw, CAST(CONVERT(VARCHAR(10), [TradingDateAndHour], 12) AS DATETIME)) + 1, CAST(CONVERT(VARCHAR(10), [TradingDateAndHour], 12) AS DATETIME))

-- Calculate yield
SELECT COALESCE(BeerDispensed.[TradingDateAndHour], BeerSold.[TradingDate], CleaningWaste.[TradingDateAndHour], NumberOfLinesCleaned.[TradingDateAndHour]) AS [TradingDate],
	ISNULL(BeerDispensed.ActualQuantity, 0) + ISNULL(CleaningWaste.Quantity, 0) AS BeerMeasured,
	ISNULL(BeerDispensed.ActualQuantity, 0) AS BeerDispensed,
	ISNULL(BeerDispensed.RoundedQuantity, 0) AS DrinksDispensed,
	ISNULL(CleaningWaste.Quantity, 0) AS BeerInLineCleaning,
	ISNULL(BeerSold.Quantity, 0) AS Sold,
	ISNULL(BeerDispensed.RoundedQuantity, 0) - ISNULL(BeerDispensed.ActualQuantity, 0) AS OperationalYield,
	ISNULL(BeerSold.Quantity, 0) - ISNULL(BeerDispensed.RoundedQuantity, 0) AS RetailYield,
	ISNULL(BeerSold.Quantity, 0) - ISNULL(BeerDispensed.ActualQuantity, 0) - ISNULL(CleaningWaste.Quantity, 0) AS OverallYield,
	ISNULL(NumberOfLinesCleaned, 0) AS NumberOfLinesCleaned
FROM @BeerDispensed AS BeerDispensed
FULL OUTER JOIN @BeerSold AS BeerSold ON (BeerDispensed.[TradingDateAndHour] = BeerSold.[TradingDate])
FULL OUTER JOIN @CleaningWaste AS CleaningWaste ON (BeerDispensed.[TradingDateAndHour] = CleaningWaste.[TradingDateAndHour]
							OR BeerSold.[TradingDate] = CleaningWaste.[TradingDateAndHour])
FULL OUTER JOIN @NumberOfLinesCleaned AS NumberOfLinesCleaned ON (BeerDispensed.[TradingDateAndHour] = NumberOfLinesCleaned.[TradingDateAndHour]
								OR BeerSold.[TradingDate] = NumberOfLinesCleaned.[TradingDateAndHour]
								OR CleaningWaste.[TradingDateAndHour] = NumberOfLinesCleaned.[TradingDateAndHour])
ORDER BY COALESCE(BeerDispensed.[TradingDateAndHour], BeerSold.[TradingDate], CleaningWaste.[TradingDateAndHour], NumberOfLinesCleaned.[TradingDateAndHour])

DROP TABLE #TradingDispensed

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDispenseConditionsYieldSummaryWeekly] TO PUBLIC
    AS [dbo];

