CREATE PROCEDURE [dbo].[AddAutomatedTemperatureSiteRanking]
(
	@EDISID	INT,
	@From		DATETIME,
	@To		DATETIME
)
AS

DECLARE @IncludeCasks		BIT
DECLARE @IncludeKegs		BIT
DECLARE @IncludeMetric		BIT
DECLARE @TemperatureAmberValue	FLOAT
DECLARE @UnderSpecIsInSpec	BIT

SET @IncludeCasks = 1
SET @IncludeKegs = 1
SET @IncludeMetric = 0
SET @TemperatureAmberValue = 2
SET @UnderSpecIsInSpec = 1

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
DECLARE @PumpTemperatures TABLE(EDISID INT NOT NULL, Pump INT NOT NULL, TemperatureSpecification FLOAT NOT NULL, TemperatureTolerance FLOAT NOT NULL, InSpec FLOAT NULL, InTolerance FLOAT NULL, OutOfSpec FLOAT NULL)
DECLARE @SiteOnline DATETIME
DECLARE @TotalInSpec FLOAT
DECLARE @TotalInTolerance FLOAT
DECLARE @TotalOutOfSpec FLOAT
DECLARE @TotalDispense FLOAT
DECLARE @Ranking INT
DECLARE @EndOfWeek DATETIME

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
AND Products.IsMetric = 0
AND InUse = 1

-- Get dispense for period and bodge about into 'trading hours'
-- DateAndTime is the actual date and time
-- TradingDateAndTime is the actual time, but the date is the 'trading date'
-- Note that we grab an extra day (because we need the first few hours from it)
INSERT INTO @TradingDispensed
(EDISID,
DateAndTime,
TradingDateAndTime,
ProductID,
LocationID,
Quantity,
SitePump,
Pump,
Duration,
MinimumTemperature,
MaximumTemperature,
AverageTemperature,
TemperatureSpecification,
TemperatureTolerance,
FlowRateSpecification,
FlowRateTolerance)
SELECT  DispenseActions.EDISID,
	StartTime,
	CAST(DATEADD(dd, 0, DATEDIFF(dd, 0, TradingDay)) + CONVERT(VARCHAR(10), StartTime, 108) AS DATETIME) AS TradingDateAndTime,
	DispenseActions.Product,
	LocationID,
	Pints,
	DispenseActions.Pump,
	DispenseActions.Pump + PumpOffset,
	Duration,
	MinimumTemperature,
	MaximumTemperature,
	AverageTemperature,
	ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification),
	ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance),
	ISNULL(SiteProductSpecifications.FlowSpec, Products.FlowRateSpecification),
	ISNULL(SiteProductSpecifications.FlowTolerance, Products.FlowRateTolerance)
FROM DispenseActions
JOIN Products ON Products.[ID] = DispenseActions.Product
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = DispenseActions.EDISID
JOIN @AllSitePumps AS AllSitePumps ON AllSitePumps.PumpID = DispenseActions.Pump + PumpOffset
				     AND AllSitePumps.ProductID = DispenseActions.Product
LEFT JOIN SiteProductSpecifications ON Products.ID = SiteProductSpecifications.ProductID AND DispenseActions.EDISID = SiteProductSpecifications.EDISID
WHERE DispenseActions.EDISID IN (SELECT EDISID FROM @Sites)
AND TradingDay BETWEEN @From AND @To
AND (Products.IsCask = 0 OR @IncludeCasks = 1)
AND (Products.IsCask = 1 OR @IncludeKegs = 1)
AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
AND (LiquidType = 2)
AND (Pints >= 0.3)
AND TradingDay >= @SiteOnline
AND (TradingDay >= AllSitePumps.ValidFrom AND TradingDay <= AllSitePumps.ValidTo)


-- Delete the first few hours from the 'last+1' day, as that is the next 'trading day'
DELETE
FROM @TradingDispensed
WHERE DateAndTime >= DATEADD(hh,@TradingDayBeginsAt,DATEADD(dd,1,@To))

INSERT INTO @PumpTemperatures
(EDISID, Pump, TemperatureSpecification, TemperatureTolerance, InSpec, InTolerance, OutOfSpec)
SELECT AllSitePumps.EDISID,
       AllSitePumps.PumpID,
       AllSitePumps.TemperatureSpecification,
       AllSitePumps.TemperatureTolerance,
      SUM(CASE WHEN (MinimumTemperature >= AllSitePumps.TemperatureSpecification - AllSitePumps.TemperatureTolerance OR @UnderSpecIsInSpec = 1)
		  AND MinimumTemperature <= AllSitePumps.TemperatureSpecification + AllSitePumps.TemperatureTolerance THEN Quantity ELSE 0 END) AS QuantityInSpec,
	SUM(CASE WHEN (MinimumTemperature < AllSitePumps.TemperatureSpecification - AllSitePumps.TemperatureTolerance
		  AND MinimumTemperature >= AllSitePumps.TemperatureSpecification - AllSitePumps.TemperatureTolerance - @TemperatureAmberValue
		  AND @UnderSpecIsInSpec = 0)
		  OR (MinimumTemperature > AllSitePumps.TemperatureSpecification + AllSitePumps.TemperatureTolerance
		  AND MinimumTemperature <= AllSitePumps.TemperatureSpecification + AllSitePumps.TemperatureTolerance + @TemperatureAmberValue)
		 THEN Quantity ELSE 0 END) AS QuantityInAmber,
	SUM(CASE WHEN (MinimumTemperature < AllSitePumps.TemperatureSpecification - AllSitePumps.TemperatureTolerance - @TemperatureAmberValue
		  AND @UnderSpecIsInSpec = 0)
		  OR MinimumTemperature > AllSitePumps.TemperatureSpecification + AllSitePumps.TemperatureTolerance + @TemperatureAmberValue THEN Quantity ELSE 0 END) AS QuantityOutOfSpec
FROM @AllSitePumps AS AllSitePumps
JOIN @TradingDispensed AS TradingDispensed ON (AllSitePumps.PumpID = TradingDispensed.Pump AND
						    AllSitePumps.LocationID = TradingDispensed.LocationID AND
					    	    AllSitePumps.ProductID = TradingDispensed.ProductID)
GROUP BY AllSitePumps.EDISID, AllSitePumps.PumpID, AllSitePumps.TemperatureSpecification, AllSitePumps.TemperatureTolerance

SELECT @TotalInSpec = SUM(InSpec),
	 @TotalInTolerance = SUM(InTolerance),
	 @TotalOutOfSpec = SUM(OutOfSpec),
	 @TotalDispense = SUM(InSpec + InTolerance + OutOfSpec)
FROM @PumpTemperatures


IF @TotalDispense = 0 OR @TotalDispense IS NULL
BEGIN
	SET @Ranking = 6

END
ELSE
BEGIN
	SELECT @Ranking = (CASE WHEN (@TotalOutOfSpec/@TotalDispense)*100 > 2 THEN 1
			       	       WHEN (@TotalInTolerance/@TotalDispense)*100 > 5 OR  (@TotalOutOfSpec/@TotalDispense)*100 BETWEEN 1 AND 2 THEN 2
     	    		      	       ELSE 3
       		         	          END)
	FROM Sites
	WHERE EDISID = @EDISID
END

SET @EndOfWeek = DATEADD(day, -1, DATEADD(week, DATEDIFF(week, 0, GETDATE()) + 1, 0))

EXEC dbo.AssignSiteRanking @EDISID, @Ranking, '', @EndOfWeek, 5
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddAutomatedTemperatureSiteRanking] TO PUBLIC
    AS [dbo];

