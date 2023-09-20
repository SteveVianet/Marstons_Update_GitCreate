/*


sp_recompile GetSiteDispenseQuality
set statistics time on
exec dbo.GetSiteDispenseQuality_Coeo 1061,'2015-11-09 00:00:00','2015-11-15 00:00:00',1,1,1,2,1

*/


CREATE PROCEDURE [dbo].[GetSiteDispenseQuality_Coeo]
(
	@EDISID			INT,
	@From				DATETIME,
	@To				DATETIME,
	@IncludeCasks			BIT,
	@IncludeKegs			BIT,
	@IncludeMetric			BIT,
	@TemperatureAmberValue	FLOAT,
	@UnderSpecIsInSpec		BIT = 1
)
AS

SET NOCOUNT ON

DECLARE @TradingDispensed TABLE(EDISID INT,
					[DateAndTime] DATETIME,
					TradingDateAndTime DATETIME,
					ProductID INT,
					LocationID INT,
					Quantity FLOAT,
					SitePump INT,
					Pump INT,
					Duration FLOAT,
					MinimumTemperature FLOAT,
					MaximumTemperature FLOAT,
					AverageTemperature FLOAT,
					TemperatureSpecification FLOAT,
					TemperatureTolerance FLOAT,
					FlowRateSpecification FLOAT,
					FlowRateTolerance FLOAT)
DECLARE @TradingDayBeginsAt INT
SET @TradingDayBeginsAt = 5

DECLARE @Sites TABLE(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
DECLARE @SiteGroupID INT
DECLARE @SitePumpCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL, PumpOffset INT NOT NULL)
DECLARE @AllSitePumps TABLE(EDISID INT NOT NULL, PumpID INT NOT NULL, SitePump INT NOT NULL, LocationID INT NOT NULL, ProductID INT NOT NULL,
				  FlowRateSpecification FLOAT NOT NULL, FlowRateTolerance FLOAT NOT NULL,
				  TemperatureSpecification FLOAT NOT NULL, TemperatureTolerance FLOAT NOT NULL,
				  ValidFrom DATETIME NOT NULL, ValidTo DATETIME NOT NULL)
DECLARE @SiteOnline DATETIME

DECLARE @EDISID2 INT
DECLARE @EDISID3 INT
DECLARE @EDISID4 INT

SET @EDISID2 = -1
SET @EDISID3 = -1
SET @EDISID4 = -1

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

--SELECT * FROM #Sites

-- Get pumps for secondary sites (note that 1st EDISID IN #Sites is primary site)
INSERT INTO @SitePumpCounts (EDISID, MaxPump)
SELECT PumpSetup.EDISID, MAX(Pump)
FROM PumpSetup
JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
WHERE (ValidFrom <= @To)
AND (ISNULL(ValidTo, @To) >= @From)
AND (ISNULL(ValidTo, @To) >= @SiteOnline)
GROUP BY PumpSetup.EDISID, Sites.CellarID
ORDER BY CellarID

--SELECT * FROM @SitePumpCounts

INSERT INTO @SitePumpOffsets (EDISID, PumpOffset)
SELECT MainCounts.EDISID, COALESCE(QuaternaryCounts.MaxPump+TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, SecondaryCounts.MaxPump, 0)
FROM @SitePumpCounts AS MainCounts
LEFT JOIN @SitePumpCounts AS SecondaryCounts ON SecondaryCounts.Counter+1 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS TertiaryCounts ON TertiaryCounts.Counter+2 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS QuaternaryCounts ON QuaternaryCounts.Counter+3 = MainCounts.Counter

--SELECT * FROM @SitePumpOffsets

INSERT INTO @AllSitePumps (EDISID, PumpID, SitePump, LocationID, ProductID, FlowRateSpecification, FlowRateTolerance, TemperatureSpecification, TemperatureTolerance, ValidFrom, ValidTo)
SELECT Sites.EDISID, Pump+PumpOffset, Pump, LocationID, PumpSetup.ProductID,
	ISNULL(SiteProductSpecifications.FlowSpec, Products.FlowRateSpecification),
	ISNULL(SiteProductSpecifications.FlowTolerance, Products.FlowRateTolerance),
	ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification),
	ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance),
	ValidFrom,
	ISNULL(ValidTo, @To)
FROM PumpSetup
JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = PumpSetup.EDISID
JOIN Products ON Products.[ID] = PumpSetup.ProductID
LEFT JOIN SiteProductSpecifications ON Products.ID = SiteProductSpecifications.ProductID AND PumpSetup.EDISID = SiteProductSpecifications.EDISID
WHERE (ValidFrom <= @To)
AND (ISNULL(ValidTo, @To) >= @From)
AND (ISNULL(ValidTo, @To) >= @SiteOnline)
AND Products.IsWater = 0
AND InUse = 1

--SELECT * FROM @AllSitePumps

--This and the 4 near identical INSERTS are highly retarded but is the only way I could get the query to run in <5-20 seconds
SELECT @EDISID2 = CASE CellarID WHEN 2 THEN EDISID ELSE -1 END,
	@EDISID3 = CASE CellarID WHEN 2 THEN EDISID ELSE -1 END,
	@EDISID4 = CASE CellarID WHEN 2 THEN EDISID ELSE -1 END
FROM @Sites

--COEO CHANGE HERE TO MOVE DERIVED TABLE OUT OF THE MAIN INSERT STATEMENT AND INTO A TEMP TABLE
SELECT * INTO #Actions
FROM DispenseActions 
WHERE EDISID = @EDISID 
AND (TradingDay BETWEEN @From AND @To) 
AND (LiquidType = 2) 
AND (Pints >= 0.3)

INSERT INTO @TradingDispensed
(EDISID, DateAndTime, TradingDateAndTime, ProductID, LocationID, Quantity, SitePump, Pump, Duration, MinimumTemperature, MaximumTemperature, AverageTemperature, TemperatureSpecification, TemperatureTolerance, FlowRateSpecification, FlowRateTolerance)
SELECT  Actions.EDISID,
	StartTime,
	CAST(DATEADD(dd, 0, DATEDIFF(dd, 0, TradingDay)) + CONVERT(VARCHAR(10), StartTime, 108) AS DATETIME) AS TradingDateAndTime,
	Actions.Product,
	LocationID,
	Pints,
	Actions.Pump,
	Actions.Pump + PumpOffset,
	Duration,
	MinimumTemperature,
	MaximumTemperature,
	AverageTemperature,
	ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification),
	ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance),
	ISNULL(SiteProductSpecifications.FlowSpec, Products.FlowRateSpecification),
	ISNULL(SiteProductSpecifications.FlowTolerance, Products.FlowRateTolerance)
FROM #Actions as Actions
JOIN Products ON Products.[ID] = Actions.Product
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = Actions.EDISID
JOIN @AllSitePumps AS AllSitePumps ON AllSitePumps.PumpID = Actions.Pump + PumpOffset
				     AND AllSitePumps.ProductID = Actions.Product
LEFT JOIN SiteProductSpecifications ON Products.ID = SiteProductSpecifications.ProductID AND Actions.EDISID = SiteProductSpecifications.EDISID
WHERE (Products.IsCask = 0 OR @IncludeCasks = 1)
AND (Products.IsCask = 1 OR @IncludeKegs = 1)
AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
AND DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) >= @SiteOnline
AND (DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) >= AllSitePumps.ValidFrom AND DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) <= DATEADD(day, 1, AllSitePumps.ValidTo))


--COEO CHANGE HERE TO MOVE DERIVED TABLE OUT OF THE MAIN INSERT STATEMENT AND INTO A TEMP TABLE
SELECT * INTO #Actions2
FROM DispenseActions 
WHERE EDISID = @EDISID2 
AND (TradingDay BETWEEN @From AND @To) 
AND (LiquidType = 2) 
AND (Pints >= 0.3)

INSERT INTO @TradingDispensed
(EDISID, DateAndTime, TradingDateAndTime, ProductID, LocationID, Quantity, SitePump, Pump, Duration, MinimumTemperature, MaximumTemperature, AverageTemperature, TemperatureSpecification, TemperatureTolerance, FlowRateSpecification, FlowRateTolerance)
SELECT  Actions.EDISID,
	StartTime,
	CAST(DATEADD(dd, 0, DATEDIFF(dd, 0, TradingDay)) + CONVERT(VARCHAR(10), StartTime, 108) AS DATETIME) AS TradingDateAndTime,
	Actions.Product,
	LocationID,
	Pints,
	Actions.Pump,
	Actions.Pump + PumpOffset,
	Duration,
	MinimumTemperature,
	MaximumTemperature,
	AverageTemperature,
	ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification),
	ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance),
	ISNULL(SiteProductSpecifications.FlowSpec, Products.FlowRateSpecification),
	ISNULL(SiteProductSpecifications.FlowTolerance, Products.FlowRateTolerance)
FROM #Actions2 as Actions
JOIN Products ON Products.[ID] = Actions.Product
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = Actions.EDISID
JOIN @AllSitePumps AS AllSitePumps ON AllSitePumps.PumpID = Actions.Pump + PumpOffset
				     AND AllSitePumps.ProductID = Actions.Product
LEFT JOIN SiteProductSpecifications ON Products.ID = SiteProductSpecifications.ProductID AND Actions.EDISID = SiteProductSpecifications.EDISID
WHERE (Products.IsCask = 0 OR @IncludeCasks = 1)
AND (Products.IsCask = 1 OR @IncludeKegs = 1)
AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
AND DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) >= @SiteOnline
AND (DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) >= AllSitePumps.ValidFrom AND DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) <= DATEADD(day, 1, AllSitePumps.ValidTo))

--COEO CHANGE HERE TO MOVE DERIVED TABLE OUT OF THE MAIN INSERT STATEMENT AND INTO A TEMP TABLE
SELECT * INTO #Actions3
FROM DispenseActions 
WHERE EDISID = @EDISID3
AND (TradingDay BETWEEN @From AND @To) 
AND (LiquidType = 2) 
AND (Pints >= 0.3)

INSERT INTO @TradingDispensed
(EDISID, DateAndTime, TradingDateAndTime, ProductID, LocationID, Quantity, SitePump, Pump, Duration, MinimumTemperature, MaximumTemperature, AverageTemperature, TemperatureSpecification, TemperatureTolerance, FlowRateSpecification, FlowRateTolerance)
SELECT  Actions.EDISID,
	StartTime,
	CAST(DATEADD(dd, 0, DATEDIFF(dd, 0, TradingDay)) + CONVERT(VARCHAR(10), StartTime, 108) AS DATETIME) AS TradingDateAndTime,
	Actions.Product,
	LocationID,
	Pints,
	Actions.Pump,
	Actions.Pump + PumpOffset,
	Duration,
	MinimumTemperature,
	MaximumTemperature,
	AverageTemperature,
	ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification),
	ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance),
	ISNULL(SiteProductSpecifications.FlowSpec, Products.FlowRateSpecification),
	ISNULL(SiteProductSpecifications.FlowTolerance, Products.FlowRateTolerance)
FROM #Actions3 as Actions
JOIN Products ON Products.[ID] = Actions.Product
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = Actions.EDISID
JOIN @AllSitePumps AS AllSitePumps ON AllSitePumps.PumpID = Actions.Pump + PumpOffset
				     AND AllSitePumps.ProductID = Actions.Product
LEFT JOIN SiteProductSpecifications ON Products.ID = SiteProductSpecifications.ProductID AND Actions.EDISID = SiteProductSpecifications.EDISID
WHERE (Products.IsCask = 0 OR @IncludeCasks = 1)
AND (Products.IsCask = 1 OR @IncludeKegs = 1)
AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
AND DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) >= @SiteOnline
AND (DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) >= AllSitePumps.ValidFrom AND DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) <= DATEADD(day, 1, AllSitePumps.ValidTo))

--COEO CHANGE HERE TO MOVE DERIVED TABLE OUT OF THE MAIN INSERT STATEMENT AND INTO A TEMP TABLE
SELECT * INTO #Actions4
FROM DispenseActions 
WHERE EDISID = @EDISID4
AND (TradingDay BETWEEN @From AND @To) 
AND (LiquidType = 2) 
AND (Pints >= 0.3)

INSERT INTO @TradingDispensed
(EDISID, DateAndTime, TradingDateAndTime, ProductID, LocationID, Quantity, SitePump, Pump, Duration, MinimumTemperature, MaximumTemperature, AverageTemperature, TemperatureSpecification, TemperatureTolerance, FlowRateSpecification, FlowRateTolerance)
SELECT  Actions.EDISID,
	StartTime,
	CAST(DATEADD(dd, 0, DATEDIFF(dd, 0, TradingDay)) + CONVERT(VARCHAR(10), StartTime, 108) AS DATETIME) AS TradingDateAndTime,
	Actions.Product,
	LocationID,
	Pints,
	Actions.Pump,
	Actions.Pump + PumpOffset,
	Duration,
	MinimumTemperature,
	MaximumTemperature,
	AverageTemperature,
	ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification),
	ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance),
	ISNULL(SiteProductSpecifications.FlowSpec, Products.FlowRateSpecification),
	ISNULL(SiteProductSpecifications.FlowTolerance, Products.FlowRateTolerance)
FROM #Actions4 as Actions
JOIN Products ON Products.[ID] = Actions.Product
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = Actions.EDISID
JOIN @AllSitePumps AS AllSitePumps ON AllSitePumps.PumpID = Actions.Pump + PumpOffset
				     AND AllSitePumps.ProductID = Actions.Product
LEFT JOIN SiteProductSpecifications ON Products.ID = SiteProductSpecifications.ProductID AND Actions.EDISID = SiteProductSpecifications.EDISID
WHERE (Products.IsCask = 0 OR @IncludeCasks = 1)
AND (Products.IsCask = 1 OR @IncludeKegs = 1)
AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
AND DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) >= @SiteOnline
AND (DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) >= AllSitePumps.ValidFrom AND DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) <= DATEADD(day, 1, AllSitePumps.ValidTo))


--SELECT * FROM @TradingDispensed WHERE Pump = 4 ORDER BY DateAndTime

-- Now produce the report we actually want!
SELECT  ISNULL(TradingDispensed.EDISID, AllSitePumps.EDISID) AS EDISID,
	ISNULL(TradingDispensed.Pump, AllSitePumps.PumpID) AS Pump,
	ISNULL(TradingDispensed.SitePump, AllSitePumps.SitePump) AS SitePump,
	ISNULL(TradingDispensed.LocationID, AllSitePumps.LocationID) AS LocationID,
	ISNULL(TradingDispensed.ProductID, AllSitePumps.ProductID) AS ProductID,
	ISNULL(SUM(Quantity),0) AS Quantity,
	Products.Description AS Product,
	Locations.Description AS Location,
	SUM(CASE WHEN (AverageTemperature >= AllSitePumps.TemperatureSpecification - AllSitePumps.TemperatureTolerance OR @UnderSpecIsInSpec = 1)
		  AND AverageTemperature <= AllSitePumps.TemperatureSpecification + AllSitePumps.TemperatureTolerance THEN Quantity ELSE 0 END) AS QuantityInSpec,
	SUM(CASE WHEN (AverageTemperature < AllSitePumps.TemperatureSpecification - AllSitePumps.TemperatureTolerance
		  AND AverageTemperature >= AllSitePumps.TemperatureSpecification - AllSitePumps.TemperatureTolerance - @TemperatureAmberValue
		  AND @UnderSpecIsInSpec = 0)
		  OR (AverageTemperature > AllSitePumps.TemperatureSpecification + AllSitePumps.TemperatureTolerance
		  AND AverageTemperature <= AllSitePumps.TemperatureSpecification + AllSitePumps.TemperatureTolerance + @TemperatureAmberValue)
		 THEN Quantity ELSE 0 END) AS QuantityInAmber,
	SUM(CASE WHEN (AverageTemperature < AllSitePumps.TemperatureSpecification - AllSitePumps.TemperatureTolerance - @TemperatureAmberValue
		  AND @UnderSpecIsInSpec = 0)
		  OR AverageTemperature > AllSitePumps.TemperatureSpecification + AllSitePumps.TemperatureTolerance + @TemperatureAmberValue THEN Quantity ELSE 0 END) AS QuantityOutOfSpec,
	ISNULL(AVG(Duration/Quantity),0) AS AverageFlowRate,
	AVG(AllSitePumps.FlowRateSpecification) AS FlowRateSpecification,
	AVG(AllSitePumps.FlowRateTolerance) AS FlowRateTolerance,
	AVG(AllSitePumps.TemperatureSpecification) AS TemperatureSpecification,
	AVG(AllSitePumps.TemperatureTolerance) AS TemperatureTolerance
FROM @TradingDispensed AS TradingDispensed
RIGHT JOIN @AllSitePumps AS AllSitePumps ON (AllSitePumps.PumpID = TradingDispensed.Pump AND
						AllSitePumps.LocationID = TradingDispensed.LocationID AND
					    	AllSitePumps.ProductID = TradingDispensed.ProductID)
JOIN Locations ON (Locations.ID = TradingDispensed.LocationID OR Locations.ID = AllSitePumps.LocationID)
JOIN Products ON (Products.ID = TradingDispensed.ProductID OR Products.ID = AllSitePumps.ProductID)
GROUP BY ISNULL(TradingDispensed.EDISID, AllSitePumps.EDISID) , ISNULL(TradingDispensed.Pump, AllSitePumps.PumpID), ISNULL(TradingDispensed.SitePump, AllSitePumps.SitePump), ISNULL(TradingDispensed.LocationID, AllSitePumps.LocationID), ISNULL(TradingDispensed.ProductID, AllSitePumps.ProductID), Products.Description, Locations.Description
ORDER BY ISNULL(TradingDispensed.EDISID, AllSitePumps.EDISID) , ISNULL(TradingDispensed.Pump, AllSitePumps.PumpID), ISNULL(TradingDispensed.SitePump, AllSitePumps.SitePump), ISNULL(TradingDispensed.LocationID, AllSitePumps.LocationID), ISNULL(TradingDispensed.ProductID, AllSitePumps.ProductID), Products.Description, Locations.Description

