CREATE PROCEDURE [dbo].[AddAutomatedYieldSiteRanking]
(
	@EDISID		INT,
	@From			DATETIME,
	@To			DATETIME,
	@AddPouringRanking	BIT,
	@AddTillRanking	BIT
)
AS

SET NOCOUNT ON
SET DATEFIRST 1

CREATE TABLE #TradingDispensed (DateAndTime DATETIME, TradingDateAndTime DATETIME, ProductID INT, LiquidType INT, Quantity FLOAT, Pump INT)
DECLARE @TradingSold TABLE(TradingDateAndHour DATETIME, Quantity FLOAT)
DECLARE @BeerSold TABLE(TradingDate DATETIME, Quantity FLOAT)
DECLARE @BeerDispensed TABLE(TradingDateAndHour DATETIME, ActualQuantity FLOAT, RoundedQuantity FLOAT)

DECLARE @TradingDayBeginsAt INT
SET @TradingDayBeginsAt = 5

DECLARE @Sites TABLE(EDISID INT NOT NULL)
DECLARE @SitePumpCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL PRIMARY KEY, PumpOffset INT NOT NULL)

DECLARE @SiteOnline  DATETIME
DECLARE @SiteGroupID INT
DECLARE @Sold FLOAT
DECLARE @PouringYieldPercentage FLOAT
DECLARE @TillYieldPercentage FLOAT
DECLARE @PouringYieldRanking INT
DECLARE @TillYieldRanking INT
DECLARE @IncludeCasks BIT
DECLARE @IncludeKegs BIT
DECLARE @IncludeMetric BIT
DECLARE @EndOfWeek DATETIME

SET @IncludeCasks = 1
SET @IncludeKegs = 1
SET @IncludeMetric = 1

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
([DateAndTime], TradingDateAndTime, ProductID, LiquidType, Quantity, Pump)
SELECT  StartTime,
	CAST(DATEADD(dd, 0, DATEDIFF(dd, 0, TradingDay)) + CONVERT(VARCHAR(10), StartTime, 108) AS DATETIME) AS TradingDateAndTime,
	Products.ID,
	LiquidType,
	Pints,
	Pump + PumpOffset
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
	SUM(dbo.fnGetSiteDrinkVolume(@EDISID, Quantity*100, Products.[ID]))
FROM #TradingDispensed AS TradingDispensed
JOIN Products ON Products.ID = TradingDispensed.ProductID
WHERE LiquidType = 2
GROUP BY DATEADD(dw, -DATEPART(dw, CAST(CONVERT(VARCHAR(10), [TradingDateAndTime], 12) AS DATETIME)) + 1, CAST(CONVERT(VARCHAR(10), [TradingDateAndTime], 12)  AS DATETIME))

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
SELECT 	@Sold = ISNULL(BeerSold.Quantity, 0),
	@PouringYieldPercentage = (ISNULL(BeerDispensed.RoundedQuantity, 0) / ISNULL(BeerDispensed.ActualQuantity, 0)) * 100,
	@TillYieldPercentage = (ISNULL(BeerSold.Quantity, 0) / ISNULL(BeerDispensed.RoundedQuantity, 0)) * 100
FROM @BeerDispensed AS BeerDispensed
FULL OUTER JOIN @BeerSold AS BeerSold ON (BeerDispensed.[TradingDateAndHour] = BeerSold.[TradingDate])
ORDER BY COALESCE(BeerDispensed.[TradingDateAndHour], BeerSold.[TradingDate])

DROP TABLE #TradingDispensed

IF @Sold > 0
BEGIN
	SET @TillYieldRanking = (CASE WHEN @TillYieldPercentage < 98 THEN 1
	     WHEN (@TillYieldPercentage BETWEEN 98 AND 100) OR @TillYieldPercentage > 102 THEN 2
	     WHEN @TillYieldPercentage BETWEEN 100 AND 102 THEN 3
	END)
END
ELSE
BEGIN
	SET @TillYieldRanking = 6
END

SET @PouringYieldRanking = (CASE WHEN @PouringYieldPercentage <= 98 THEN 1
     WHEN ((@PouringYieldPercentage > 98 AND @PouringYieldPercentage <= 101) OR @PouringYieldPercentage > 106) THEN 2
     WHEN (@PouringYieldPercentage >= 101 AND @PouringYieldPercentage <=106) THEN 3
END)

IF @PouringYieldRanking IS NULL
BEGIN
	SET @PouringYieldRanking = 6
END

SET @EndOfWeek = DATEADD(day, -1, DATEADD(week, DATEDIFF(week, 0, GETDATE()) + 1, 0))

IF @AddPouringRanking = 1
BEGIN
	EXEC dbo.AssignSiteRanking @EDISID, @PouringYieldRanking, '', @EndOfWeek, 9
END

IF @AddTillRanking =  1
BEGIN
	EXEC dbo.AssignSiteRanking @EDISID, @TillYieldRanking, '', @EndOfWeek, 10
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddAutomatedYieldSiteRanking] TO PUBLIC
    AS [dbo];

