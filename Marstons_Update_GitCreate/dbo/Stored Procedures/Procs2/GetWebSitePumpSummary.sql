CREATE PROCEDURE [dbo].[GetWebSitePumpSummary]
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

CREATE TABLE #TradingDispensed (EDISID INT,
				[DateAndTime] DATETIME,
				TradingDateAndTime DATETIME,
				ProductID INT,
				LocationID INT,
				Quantity FLOAT,
				Drinks FLOAT,
				Temperature FLOAT,
				SitePump INT,
				Pump INT)

DECLARE @Sites TABLE(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
DECLARE @SiteGroupID INT
DECLARE @SitePumpCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL, PumpOffset INT NOT NULL)
DECLARE @AllSitePumps TABLE(PumpID INT NOT NULL, LocationID INT NOT NULL, ProductID INT NOT NULL,
				      TemperatureSpecification FLOAT NOT NULL, TemperatureTolerance FLOAT NOT NULL,
				      ValidFrom DATETIME NOT NULL, ValidTo DATETIME NOT NULL)
DECLARE @SiteOnline DATETIME

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

--SELECT * FROM @Sites

-- Get pumps for secondary sites (note that 1st EDISID IN @Sites is primary site)
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
SELECT MainCounts.EDISID, COALESCE(QuaternaryCounts.MaxPump+TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, 
SecondaryCounts.MaxPump, 0)
FROM @SitePumpCounts AS MainCounts
LEFT JOIN @SitePumpCounts AS SecondaryCounts ON SecondaryCounts.Counter+1 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS TertiaryCounts ON TertiaryCounts.Counter+2 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS QuaternaryCounts ON QuaternaryCounts.Counter+3 = MainCounts.Counter

--SELECT * FROM @SitePumpOffsets

INSERT INTO @AllSitePumps (PumpID, LocationID, ProductID,TemperatureSpecification, TemperatureTolerance, ValidFrom, ValidTo)
SELECT Pump+PumpOffset, LocationID, PumpSetup.ProductID,
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
AND (Products.IsCask = 0 OR @IncludeCasks = 1)
AND (Products.IsCask = 1 OR @IncludeKegs = 1)
AND (Products.IsMetric = 0 OR @IncludeMetric = 1)

--SELECT * FROM @AllSitePumps

-- Get dispense for period and bodge about into 'trading hours'
-- DateAndTime is the actual date and time
-- TradingDateAndTime is the actual time, but the date is the 'trading date'
-- Note that we grab an extra day (because we need the first few hours from it)
INSERT INTO #TradingDispensed
(EDISID,
DateAndTime,
TradingDateAndTime,
ProductID,
LocationID,
Quantity,
Drinks,
Temperature,
SitePump,
Pump)
SELECT  DispenseActions.EDISID,
	StartTime,
	CAST(DATEADD(dd, 0, DATEDIFF(dd, 0, TradingDay)) + CONVERT(VARCHAR(10), StartTime, 108) AS DATETIME) AS TradingDateAndTime,
	DispenseActions.Product,
	LocationID,
	Pints,
	EstimatedDrinks,
	AverageTemperature,
	DispenseActions.Pump,
	DispenseActions.Pump + PumpOffset
FROM DispenseActions
JOIN Products ON Products.[ID] = DispenseActions.Product
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = DispenseActions.EDISID
JOIN @AllSitePumps AS AllSitePumps ON AllSitePumps.PumpID = DispenseActions.Pump + PumpOffset
				     AND AllSitePumps.ProductID = DispenseActions.Product
WHERE DispenseActions.EDISID IN (SELECT EDISID FROM @Sites)
AND TradingDay BETWEEN @From AND @To
AND TradingDay >= @SiteOnline
AND (Products.IsCask = 0 OR @IncludeCasks = 1)
AND (Products.IsCask = 1 OR @IncludeKegs = 1)
AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
AND (LiquidType = 2)
AND (Pints >= 0.3)
AND (TradingDay >= AllSitePumps.ValidFrom AND TradingDay <= AllSitePumps.ValidTo)



--SELECT * FROM @TradingDispensed WHERE Pump = 4 ORDER BY DateAndTime

-- Now produce the report we actually want!
SELECT TOP 5 ISNULL(TradingDispensed.Pump, AllSitePumps.PumpID) AS Pump,
	Products.Description AS Product,
	Locations.Description AS Location,
	ISNULL(SUM(Quantity),0) AS Quantity,
	ISNULL(SUM(Drinks),0) AS Drinks,
	AVG(CASE WHEN (Temperature < AllSitePumps.TemperatureSpecification - AllSitePumps.TemperatureTolerance - @TemperatureAmberValue
		  AND @UnderSpecIsInSpec = 0)
		  OR Temperature > AllSitePumps.TemperatureSpecification + AllSitePumps.TemperatureTolerance + @TemperatureAmberValue THEN Temperature ELSE NULL END) AS Temperature,
	SUM(CASE WHEN (Temperature < AllSitePumps.TemperatureSpecification - AllSitePumps.TemperatureTolerance - @TemperatureAmberValue
		  AND @UnderSpecIsInSpec = 0)
		  OR Temperature > AllSitePumps.TemperatureSpecification + AllSitePumps.TemperatureTolerance + @TemperatureAmberValue THEN Quantity ELSE 0 END) AS QuantityOutOfSpec,
	SUM(CASE WHEN (Temperature < AllSitePumps.TemperatureSpecification - AllSitePumps.TemperatureTolerance - @TemperatureAmberValue
		  AND @UnderSpecIsInSpec = 0)
		  OR Temperature > AllSitePumps.TemperatureSpecification + AllSitePumps.TemperatureTolerance + @TemperatureAmberValue THEN Drinks ELSE 0 END) AS DrinksOutOfSpec
FROM #TradingDispensed AS TradingDispensed
RIGHT JOIN @AllSitePumps AS AllSitePumps ON (AllSitePumps.PumpID = TradingDispensed.Pump AND
						AllSitePumps.LocationID = TradingDispensed.LocationID AND
					    	AllSitePumps.ProductID = TradingDispensed.ProductID)
JOIN Locations ON (Locations.ID = TradingDispensed.LocationID OR Locations.ID = AllSitePumps.LocationID)
JOIN Products ON (Products.ID = TradingDispensed.ProductID OR Products.ID = AllSitePumps.ProductID)
GROUP BY ISNULL(TradingDispensed.Pump, AllSitePumps.PumpID), Products.Description, Locations.Description
HAVING SUM(CASE WHEN (Temperature < AllSitePumps.TemperatureSpecification - AllSitePumps.TemperatureTolerance - @TemperatureAmberValue
	          AND @UnderSpecIsInSpec = 0)
	          OR Temperature > AllSitePumps.TemperatureSpecification + AllSitePumps.TemperatureTolerance + @TemperatureAmberValue THEN Drinks ELSE 0 END) > 1
ORDER BY QuantityOutOfSpec DESC

DROP TABLE #TradingDispensed
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSitePumpSummary] TO PUBLIC
    AS [dbo];

