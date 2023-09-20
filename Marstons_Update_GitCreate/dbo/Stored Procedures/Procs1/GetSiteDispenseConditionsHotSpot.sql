CREATE PROCEDURE [dbo].[GetSiteDispenseConditionsHotSpot]
(
	@EDISID			INT,
	@From				DATETIME,
	@To				DATETIME,
	@GroupingInterval		INT,
	@IncludeCasks			BIT,
	@IncludeKegs			BIT,
	@IncludeMetric			BIT,
	@MinimumQuantity		FLOAT = NULL,
	@MaximumQuantity		FLOAT = NULL,
	@MinimumDuration		FLOAT = NULL,
	@MaximumDuration		FLOAT = NULL,
	@MinimumDrinks		FLOAT = NULL,
	@MaximumDrinks		FLOAT = NULL,
	@MinimumTemperature	FLOAT = NULL,
	@MaximumTemperature	FLOAT = NULL,
	@MinimumConductivity		INT = NULL,
	@MaximumConductivity		INT = NULL,
	@ProductID			INT = NULL,
	@IncludeLiquidUnknown	BIT = 1,
	@IncludeLiquidWater		BIT = 1,
	@IncludeLiquidBeer		BIT = 1,
	@IncludeLiquidCleaner		BIT = 1,
	@IncludeLiquidInTransition	BIT = 1,
	@IncludeLiquidBeerInClean	BIT = 1
)
AS

SET NOCOUNT ON

DECLARE @TradingDispensed TABLE(EDISID INT NOT NULL,
					DateAndTime DATETIME NOT NULL,
					TradingDateAndTime DATETIME NOT NULL,
					ProductID INT NOT NULL,
					LiquidType INT NOT NULL,
					Quantity FLOAT NOT NULL,
					SitePump INT NOT NULL,
					Pump INT NOT NULL,
					Duration FLOAT NOT NULL,
					Drinks FLOAT NOT NULL,
					MinimumTemperature FLOAT,
					MaximumTemperature FLOAT,
					AverageTemperature FLOAT,
					MinimumConductivity INT,
					MaximumConductivity INT,
					AverageConductivity INT)

DECLARE @TradingDayBeginsAt INT
SET @TradingDayBeginsAt = 5

DECLARE @Sites TABLE(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
--CREATE TABLE #Sites (EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
--CREATE CLUSTERED INDEX IX_EDISID ON #Sites (EDISID)
DECLARE @SiteGroupID INT
DECLARE @SitePumpCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL, PumpOffset INT NOT NULL)

DECLARE @EDISID2 INT
DECLARE @EDISID3 INT
DECLARE @EDISID4 INT
SET @EDISID2 = -1
SET @EDISID3 = -1
SET @EDISID4 = -1

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

-- Get pumps for secondary sites (note that 1st EDISID IN #Sites is primary site)
INSERT INTO @SitePumpCounts (EDISID, MaxPump)
SELECT PumpSetup.EDISID, MAX(Pump)
FROM PumpSetup
JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
WHERE (ValidFrom <= @To)
AND (ISNULL(ValidTo, @To) >= @From)
GROUP BY PumpSetup.EDISID, Sites.CellarID
ORDER BY CellarID

INSERT INTO @SitePumpOffsets (EDISID, PumpOffset)
SELECT MainCounts.EDISID, COALESCE(QuaternaryCounts.MaxPump+TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, SecondaryCounts.MaxPump, 0)
FROM @SitePumpCounts AS MainCounts
LEFT JOIN @SitePumpCounts AS SecondaryCounts ON SecondaryCounts.Counter+1 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS TertiaryCounts ON TertiaryCounts.Counter+2 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS QuaternaryCounts ON QuaternaryCounts.Counter+3 = MainCounts.Counter

--This and the 4 near identical INSERTS are highly retarded but is the only way I could get the query to run in <5-20 seconds
SELECT @EDISID2 = CASE CellarID WHEN 2 THEN EDISID ELSE -1 END,
	@EDISID3 = CASE CellarID WHEN 3 THEN EDISID ELSE -1 END,
	@EDISID4 = CASE CellarID WHEN 4 THEN EDISID ELSE -1 END
FROM @Sites

INSERT INTO @TradingDispensed
(EDISID, [DateAndTime], TradingDateAndTime, ProductID, LiquidType, Quantity, SitePump, Pump, Duration, Drinks, MinimumTemperature, MaximumTemperature, AverageTemperature, MinimumConductivity, MaximumConductivity, AverageConductivity)
SELECT  DA.EDISID,
	StartTime,
	CAST(DATEADD(dd, 0, DATEDIFF(dd, 0, TradingDay)) + CONVERT(VARCHAR(10), StartTime, 108) AS DATETIME) AS TradingDateAndTime,
	Product,
	LiquidType,
	Pints,
	Pump,
	Pump + PumpOffset,
	Duration,
	EstimatedDrinks,
	MinimumTemperature,
	MaximumTemperature,
	AverageTemperature,
	MinimumConductivity,
	MaximumConductivity,
	AverageConductivity
FROM (SELECT * FROM DispenseActions 
				WHERE EDISID = @EDISID
				AND TradingDay BETWEEN @From AND @To 
				AND (Pints >= @MinimumQuantity OR @MinimumQuantity IS NULL)
				AND (Pints <= @MaximumQuantity OR @MaximumQuantity IS NULL)
				AND (Duration >= @MinimumDuration OR @MinimumDuration IS NULL)
				AND (Duration <= @MaximumDuration OR @MaximumDuration IS NULL)
				AND (EstimatedDrinks  >= @MinimumDrinks OR @MinimumDrinks IS NULL)
				AND (EstimatedDrinks  <= @MaximumDrinks OR @MaximumDrinks IS NULL)
				AND (MinimumTemperature >= @MinimumTemperature OR @MinimumTemperature IS NULL)
				AND (MinimumTemperature <= @MaximumTemperature OR @MaximumTemperature IS NULL)
				AND (MinimumConductivity >= @MinimumConductivity OR @MinimumConductivity IS NULL OR MinimumConductivity IS NULL)
				AND (MaximumConductivity <= @MaximumConductivity OR @MaximumConductivity IS NULL OR MaximumConductivity IS NULL)
				AND (Product = @ProductID OR @ProductID IS NULL)
				AND ( (LiquidType = 0 AND @IncludeLiquidUnknown = 1)
					OR (LiquidType = 1 AND @IncludeLiquidWater = 1)
					OR (LiquidType = 2 AND @IncludeLiquidBeer = 1)
					OR (LiquidType = 3 AND @IncludeLiquidCleaner = 1)
					OR (LiquidType = 4 AND @IncludeLiquidInTransition = 1)
					OR (LiquidType = 5 AND @IncludeLiquidBeerInClean = 1) )
) AS DA
JOIN Products ON Products.[ID] = DA.Product
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = DA.EDISID
WHERE (Products.IsCask = 0 OR @IncludeCasks = 1)
AND (Products.IsCask = 1 OR @IncludeKegs = 1)
AND (Products.IsMetric = 0 OR @IncludeMetric = 1)


INSERT INTO @TradingDispensed
(EDISID, [DateAndTime], TradingDateAndTime, ProductID, LiquidType, Quantity, SitePump, Pump, Duration, Drinks, MinimumTemperature, MaximumTemperature, AverageTemperature, MinimumConductivity, MaximumConductivity, AverageConductivity)
SELECT  DA.EDISID,
	StartTime,
	CAST(DATEADD(dd, 0, DATEDIFF(dd, 0, TradingDay)) + CONVERT(VARCHAR(10), StartTime, 108) AS DATETIME) AS TradingDateAndTime,
	Product,
	LiquidType,
	Pints,
	Pump,
	Pump + PumpOffset,
	Duration,
	EstimatedDrinks,
	MinimumTemperature,
	MaximumTemperature,
	AverageTemperature,
	MinimumConductivity,
	MaximumConductivity,
	AverageConductivity
FROM (SELECT * FROM DispenseActions 
				WHERE EDISID = @EDISID2
				AND TradingDay BETWEEN @From AND @To 
				AND (Pints >= @MinimumQuantity OR @MinimumQuantity IS NULL)
				AND (Pints <= @MaximumQuantity OR @MaximumQuantity IS NULL)
				AND (Duration >= @MinimumDuration OR @MinimumDuration IS NULL)
				AND (Duration <= @MaximumDuration OR @MaximumDuration IS NULL)
				AND (EstimatedDrinks  >= @MinimumDrinks OR @MinimumDrinks IS NULL)
				AND (EstimatedDrinks  <= @MaximumDrinks OR @MaximumDrinks IS NULL)
				AND (MinimumTemperature >= @MinimumTemperature OR @MinimumTemperature IS NULL)
				AND (MinimumTemperature <= @MaximumTemperature OR @MaximumTemperature IS NULL)
				AND (MinimumConductivity >= @MinimumConductivity OR @MinimumConductivity IS NULL OR MinimumConductivity IS NULL)
				AND (MaximumConductivity <= @MaximumConductivity OR @MaximumConductivity IS NULL OR MaximumConductivity IS NULL)
				AND (Product = @ProductID OR @ProductID IS NULL)
				AND ( (LiquidType = 0 AND @IncludeLiquidUnknown = 1)
					OR (LiquidType = 1 AND @IncludeLiquidWater = 1)
					OR (LiquidType = 2 AND @IncludeLiquidBeer = 1)
					OR (LiquidType = 3 AND @IncludeLiquidCleaner = 1)
					OR (LiquidType = 4 AND @IncludeLiquidInTransition = 1)
					OR (LiquidType = 5 AND @IncludeLiquidBeerInClean = 1) )
) AS DA
JOIN Products ON Products.[ID] = DA.Product
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = DA.EDISID
WHERE (Products.IsCask = 0 OR @IncludeCasks = 1)
AND (Products.IsCask = 1 OR @IncludeKegs = 1)
AND (Products.IsMetric = 0 OR @IncludeMetric = 1)

INSERT INTO @TradingDispensed
(EDISID, [DateAndTime], TradingDateAndTime, ProductID, LiquidType, Quantity, SitePump, Pump, Duration, Drinks, MinimumTemperature, MaximumTemperature, AverageTemperature, MinimumConductivity, MaximumConductivity, AverageConductivity)
SELECT  DA.EDISID,
	StartTime,
	CAST(DATEADD(dd, 0, DATEDIFF(dd, 0, TradingDay)) + CONVERT(VARCHAR(10), StartTime, 108) AS DATETIME) AS TradingDateAndTime,
	Product,
	LiquidType,
	Pints,
	Pump,
	Pump + PumpOffset,
	Duration,
	EstimatedDrinks,
	MinimumTemperature,
	MaximumTemperature,
	AverageTemperature,
	MinimumConductivity,
	MaximumConductivity,
	AverageConductivity
FROM (SELECT * FROM DispenseActions 
				WHERE EDISID = @EDISID3
				AND TradingDay BETWEEN @From AND @To 
				AND (Pints >= @MinimumQuantity OR @MinimumQuantity IS NULL)
				AND (Pints <= @MaximumQuantity OR @MaximumQuantity IS NULL)
				AND (Duration >= @MinimumDuration OR @MinimumDuration IS NULL)
				AND (Duration <= @MaximumDuration OR @MaximumDuration IS NULL)
				AND (EstimatedDrinks  >= @MinimumDrinks OR @MinimumDrinks IS NULL)
				AND (EstimatedDrinks  <= @MaximumDrinks OR @MaximumDrinks IS NULL)
				AND (MinimumTemperature >= @MinimumTemperature OR @MinimumTemperature IS NULL)
				AND (MinimumTemperature <= @MaximumTemperature OR @MaximumTemperature IS NULL)
				AND (MinimumConductivity >= @MinimumConductivity OR @MinimumConductivity IS NULL OR MinimumConductivity IS NULL)
				AND (MaximumConductivity <= @MaximumConductivity OR @MaximumConductivity IS NULL OR MaximumConductivity IS NULL)
				AND (Product = @ProductID OR @ProductID IS NULL)
				AND ( (LiquidType = 0 AND @IncludeLiquidUnknown = 1)
					OR (LiquidType = 1 AND @IncludeLiquidWater = 1)
					OR (LiquidType = 2 AND @IncludeLiquidBeer = 1)
					OR (LiquidType = 3 AND @IncludeLiquidCleaner = 1)
					OR (LiquidType = 4 AND @IncludeLiquidInTransition = 1)
					OR (LiquidType = 5 AND @IncludeLiquidBeerInClean = 1) )
) AS DA
JOIN Products ON Products.[ID] = DA.Product
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = DA.EDISID
WHERE (Products.IsCask = 0 OR @IncludeCasks = 1)
AND (Products.IsCask = 1 OR @IncludeKegs = 1)
AND (Products.IsMetric = 0 OR @IncludeMetric = 1)

INSERT INTO @TradingDispensed
(EDISID, [DateAndTime], TradingDateAndTime, ProductID, LiquidType, Quantity, SitePump, Pump, Duration, Drinks, MinimumTemperature, MaximumTemperature, AverageTemperature, MinimumConductivity, MaximumConductivity, AverageConductivity)
SELECT  DA.EDISID,
	StartTime,
	CAST(DATEADD(dd, 0, DATEDIFF(dd, 0, TradingDay)) + CONVERT(VARCHAR(10), StartTime, 108) AS DATETIME) AS TradingDateAndTime,
	Product,
	LiquidType,
	Pints,
	Pump,
	Pump + PumpOffset,
	Duration,
	EstimatedDrinks,
	MinimumTemperature,
	MaximumTemperature,
	AverageTemperature,
	MinimumConductivity,
	MaximumConductivity,
	AverageConductivity
FROM (SELECT * FROM DispenseActions 
				WHERE EDISID = @EDISID4
				AND TradingDay BETWEEN @From AND @To 
				AND (Pints >= @MinimumQuantity OR @MinimumQuantity IS NULL)
				AND (Pints <= @MaximumQuantity OR @MaximumQuantity IS NULL)
				AND (Duration >= @MinimumDuration OR @MinimumDuration IS NULL)
				AND (Duration <= @MaximumDuration OR @MaximumDuration IS NULL)
				AND (EstimatedDrinks  >= @MinimumDrinks OR @MinimumDrinks IS NULL)
				AND (EstimatedDrinks  <= @MaximumDrinks OR @MaximumDrinks IS NULL)
				AND (MinimumTemperature >= @MinimumTemperature OR @MinimumTemperature IS NULL)
				AND (MinimumTemperature <= @MaximumTemperature OR @MaximumTemperature IS NULL)
				AND (MinimumConductivity >= @MinimumConductivity OR @MinimumConductivity IS NULL OR MinimumConductivity IS NULL)
				AND (MaximumConductivity <= @MaximumConductivity OR @MaximumConductivity IS NULL OR MaximumConductivity IS NULL)
				AND (Product = @ProductID OR @ProductID IS NULL)
				AND ( (LiquidType = 0 AND @IncludeLiquidUnknown = 1)
					OR (LiquidType = 1 AND @IncludeLiquidWater = 1)
					OR (LiquidType = 2 AND @IncludeLiquidBeer = 1)
					OR (LiquidType = 3 AND @IncludeLiquidCleaner = 1)
					OR (LiquidType = 4 AND @IncludeLiquidInTransition = 1)
					OR (LiquidType = 5 AND @IncludeLiquidBeerInClean = 1) )
) AS DA
JOIN Products ON Products.[ID] = DA.Product
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = DA.EDISID
WHERE (Products.IsCask = 0 OR @IncludeCasks = 1)
AND (Products.IsCask = 1 OR @IncludeKegs = 1)
AND (Products.IsMetric = 0 OR @IncludeMetric = 1)



SELECT   CAST(STR(DATEPART(year,DateAndTime),4) + '-' + STR(DATEPART(month,DateAndTime),LEN(DATEPART(month,DateAndTime))) + '-' + STR(DATEPART(day,DateAndTime),LEN(DATEPART(day,DateAndTime))) + ' ' + STR(DATEPART(hour,DateAndTime),LEN(DATEPART(hour,DateAndTime))) + ':' + STR((DATEPART(minute, DateAndTime)/@GroupingInterval)*@GroupingInterval,LEN(DATEPART(minute,DateAndTime))) + ':00' AS DATETIME) AS DateAndTime,
   	 CAST(STR(DATEPART(year,TradingDateAndTime),4) + '-' + STR(DATEPART(month,TradingDateAndTime),LEN(DATEPART(month,TradingDateAndTime))) + '-' + STR(DATEPART(day,TradingDateAndTime),LEN(DATEPART(day,TradingDateAndTime))) + ' ' + STR(DATEPART(hour,TradingDateAndTime),LEN(DATEPART(hour,TradingDateAndTime))) + ':' + STR((DATEPART(minute, TradingDateAndTime)/@GroupingInterval)*@GroupingInterval,LEN(DATEPART(minute,TradingDateAndTime))) + ':00' AS DATETIME) AS TradingDateAndTime,
	 ProductID, 
	SUM(CASE WHEN LiquidType = 0 THEN Quantity ELSE 0 END) AS QuantityUnknown,
	SUM(CASE WHEN LiquidType = 1 THEN Quantity ELSE 0 END) AS QuantityWater,
	SUM(CASE WHEN LiquidType = 2 THEN Quantity ELSE 0 END) AS QuantityBeer,
	SUM(CASE WHEN LiquidType = 3 THEN Quantity ELSE 0 END) AS QuantityCleaner,
	SUM(CASE WHEN LiquidType = 4 THEN Quantity ELSE 0 END) AS QuantityInTransition,
	SUM(CASE WHEN LiquidType = 5 THEN Quantity ELSE 0 END) AS QuantityBeerInClean,
	0 AS LiquidType,
	 Pump,
	 SUM(Duration) AS Duration,
	 SUM(Drinks) AS Drinks,
	 MIN(MinimumTemperature) AS MinimumTemperature,
	 MAX(MaximumTemperature) AS MaximumTemperature,
	 AVG(AverageTemperature) AS AverageTemperature,
	 MIN(MinimumConductivity) AS MinimumConductivity,
	 MAX(MaximumConductivity) AS MaximumConductivity,
	 AVG(AverageConductivity) AS AverageConductivity
FROM @TradingDispensed AS TradingDispensed
GROUP BY CAST(STR(DATEPART(year,DateAndTime),4) + '-' + STR(DATEPART(month,DateAndTime),LEN(DATEPART(month,DateAndTime))) + '-' + STR(DATEPART(day,DateAndTime),LEN(DATEPART(day,DateAndTime))) + ' ' + STR(DATEPART(hour,DateAndTime),LEN(DATEPART(hour,DateAndTime))) + ':' + STR((DATEPART(minute, DateAndTime)/@GroupingInterval)*@GroupingInterval,LEN(DATEPART(minute,DateAndTime))) + ':00' AS DATETIME),
	 CAST(STR(DATEPART(year,TradingDateAndTime),4) + '-' + STR(DATEPART(month,TradingDateAndTime),LEN(DATEPART(month,TradingDateAndTime))) + '-' + STR(DATEPART(day,TradingDateAndTime),LEN(DATEPART(day,TradingDateAndTime))) + ' ' + STR(DATEPART(hour,TradingDateAndTime),LEN(DATEPART(hour,TradingDateAndTime))) + ':' + STR((DATEPART(minute, TradingDateAndTime)/@GroupingInterval)*@GroupingInterval,LEN(DATEPART(minute,TradingDateAndTime))) + ':00' AS DATETIME),
	 ProductID,
	 Pump

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteDispenseConditionsHotSpot] TO PUBLIC
    AS [dbo];

