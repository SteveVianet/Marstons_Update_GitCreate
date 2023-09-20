





CREATE PROCEDURE [dbo].[GetWebSiteHourlyPumpDispenseQuality]
(
	@EDISID					INT,
	@From					DATETIME,
	@To						DATETIME,
	@Pump					INT,
	@TemperatureAmberValue	FLOAT = 2,
	@UnderSpecIsInSpec		BIT = 1,
	@ExcludeServiceIssues	BIT = 0
)
AS

SET NOCOUNT ON

CREATE TABLE #TradingDispensed (EDISID INT,
					DateAndHour DATETIME,
					TradingDateAndHour DATETIME,
					ProductID INT,
					LocationID INT,
					Quantity FLOAT,
					SitePump INT,
					Pump INT,
					Duration FLOAT,
					--MinimumTemperature FLOAT,
					--MaximumTemperature FLOAT,
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
DECLARE @AllSitePumps TABLE(PumpID INT NOT NULL, LocationID INT NOT NULL, ProductID INT NOT NULL,
				      FlowRateSpecification FLOAT NOT NULL, FlowRateTolerance FLOAT NOT NULL,
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

INSERT INTO @SitePumpOffsets (EDISID, PumpOffset)
SELECT MainCounts.EDISID, COALESCE(QuaternaryCounts.MaxPump+TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, 
SecondaryCounts.MaxPump, 0)
FROM @SitePumpCounts AS MainCounts
LEFT JOIN @SitePumpCounts AS SecondaryCounts ON SecondaryCounts.Counter+1 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS TertiaryCounts ON TertiaryCounts.Counter+2 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS QuaternaryCounts ON QuaternaryCounts.Counter+3 = MainCounts.Counter

INSERT INTO @AllSitePumps (PumpID, LocationID, ProductID, FlowRateSpecification, FlowRateTolerance, TemperatureSpecification, TemperatureTolerance, ValidFrom, ValidTo)
SELECT Pump+PumpOffset, LocationID, PumpSetup.ProductID,
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

-- Get dispense for period
INSERT INTO #TradingDispensed
(EDISID,
DateAndHour,
TradingDateAndHour,
ProductID,
LocationID,
Quantity,
SitePump,
Pump,
Duration,
--MinimumTemperature,
--MaximumTemperature,
AverageTemperature,
TemperatureSpecification,
TemperatureTolerance,
FlowRateSpecification,
FlowRateTolerance)
SELECT  DispenseActions.EDISID,
	DATEADD(Hour, DATEPART(Hour, DispenseActions.[StartTime]), DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime))) AS DateAndHour,
	DATEADD(Hour, DATEPART(Hour, DispenseActions.[StartTime]), TradingDay) AS [TradingDateAndHour],
	DispenseActions.Product,
	LocationID,
	Pints,
	DispenseActions.Pump,
	DispenseActions.Pump + PumpOffset,
	Duration,
	--MinimumTemperature,
	--MaximumTemperature,
	AverageTemperature,
	ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification),
	ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance),
	ISNULL(SiteProductSpecifications.FlowSpec, Products.FlowRateSpecification),
	ISNULL(SiteProductSpecifications.FlowTolerance, Products.FlowRateTolerance)
FROM DispenseActions
JOIN Products ON Products.[ID] = DispenseActions.Product
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = DispenseActions.EDISID
JOIN @AllSitePumps AS AllSitePumps ON AllSitePumps.PumpID = DispenseActions.Pump + PumpOffset
LEFT JOIN SiteProductSpecifications ON Products.ID = SiteProductSpecifications.ProductID AND DispenseActions.EDISID = SiteProductSpecifications.EDISID
WHERE DispenseActions.EDISID IN (SELECT EDISID FROM @Sites)
AND (TradingDay BETWEEN @From AND @To)
AND NOT EXISTS (SELECT ID
	FROM ServiceIssuesQuality AS siq
	WHERE siq.DateFrom <= TradingDay
	AND (siq.DateTo IS NULL OR siq.DateTo >= TradingDay)
	AND siq.RealEDISID = DispenseActions.EDISID
	AND siq.ProductID = DispenseActions.Product
	AND siq.PumpID = DispenseActions.Pump
	AND @ExcludeServiceIssues = 1
)
AND TradingDay >= @SiteOnline 
AND (LiquidType = 2)
AND (Pints >= 0.3)
AND ((DispenseActions.Pump + PumpOffset = @Pump) OR (@Pump = 0))
AND (TradingDay >= AllSitePumps.ValidFrom AND TradingDay <= AllSitePumps.ValidTo)

-- Now produce the report we actually want!
SELECT  TradingDispensed.[DateAndHour],
	TradingDispensed.[TradingDateAndHour],
	Products.Description AS Product,
	Locations.Description AS Location,
	ISNULL(SUM(Quantity),0) AS Quantity,
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
	AVG(TradingDispensed.AverageTemperature) AS AverageTemperature,
	AVG(AllSitePumps.TemperatureSpecification) AS TemperatureSpecification,
	AVG(AllSitePumps.TemperatureTolerance) AS TemperatureTolerance
FROM #TradingDispensed AS TradingDispensed
JOIN @AllSitePumps AS AllSitePumps ON (AllSitePumps.PumpID = TradingDispensed.Pump AND
						AllSitePumps.LocationID = TradingDispensed.LocationID AND
					    	AllSitePumps.ProductID = TradingDispensed.ProductID)
JOIN Locations ON (Locations.ID = TradingDispensed.LocationID OR Locations.ID = AllSitePumps.LocationID)
JOIN Products ON (Products.ID = TradingDispensed.ProductID OR Products.ID = AllSitePumps.ProductID)
GROUP BY TradingDispensed.[DateAndHour], TradingDispensed.[TradingDateAndHour], Pump, Products.Description, Locations.Description
ORDER BY TradingDispensed.[DateAndHour]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteHourlyPumpDispenseQuality] TO PUBLIC
    AS [dbo];

