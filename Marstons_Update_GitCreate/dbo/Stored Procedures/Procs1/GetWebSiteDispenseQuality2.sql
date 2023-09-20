
CREATE PROCEDURE [dbo].[GetWebSiteDispenseQuality2]
(
	@EDISID					INT,
	@From					DATETIME,
	@To						DATETIME,
	@IncludeCasks			BIT,
	@IncludeKegs			BIT,
	@IncludeMetric			BIT,
	@TemperatureAmberValue	FLOAT,
	@UnderSpecIsInSpec		BIT = 1,
	@ExcludeServiceIssues	BIT = 0
)
AS

SET NOCOUNT ON

DECLARE	@InternalEDISID					INT
DECLARE	@InternalFrom					DATETIME
DECLARE	@InternalTo						DATETIME
DECLARE	@InternalIncludeCasks			BIT
DECLARE	@InternalIncludeKegs			BIT
DECLARE	@InternalIncludeMetric			BIT
DECLARE	@InternalTemperatureAmberValue	FLOAT
DECLARE	@InternalUnderSpecIsInSpec		BIT
DECLARE @IgnoreQualityCache				BIT

SET @InternalEDISID = @EDISID
SET @InternalFrom = @From
SET @InternalTo = @To
SET @InternalIncludeCasks = @IncludeCasks
SET @InternalIncludeKegs = @IncludeKegs
SET @InternalIncludeMetric = @IncludeMetric
SET @InternalTemperatureAmberValue = @TemperatureAmberValue
SET @InternalUnderSpecIsInSpec = @UnderSpecIsInSpec

DECLARE @SiteGroupID INT
DECLARE @SiteOnline DATETIME
DECLARE @Today DATETIME

CREATE TABLE #Sites (EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
CREATE TABLE #SitePumpCounts (Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
CREATE TABLE #SitePumpOffsets (EDISID INT NOT NULL, PumpOffset INT NOT NULL)
CREATE TABLE #AllSitePumps (PumpID INT NOT NULL, LocationID INT NOT NULL, ProductID INT NOT NULL,
				      FlowRateSpecification FLOAT NOT NULL, FlowRateTolerance FLOAT NOT NULL,
				      TemperatureSpecification FLOAT NOT NULL, TemperatureTolerance FLOAT NOT NULL,
				      ValidFrom DATETIME NOT NULL, ValidTo DATETIME NOT NULL, EDISID INT NOT NULL, OriginalPumpID INT NOT NULL)

SELECT @IgnoreQualityCache = CAST(PropertyValue AS BIT)
FROM Configuration
WHERE PropertyName = 'Ignore Quality Cache'

SET @IgnoreQualityCache = 1

SELECT @SiteOnline = SiteOnline
FROM dbo.Sites
WHERE EDISID = @InternalEDISID

-- Find out which EDISIDs are relevant (plough through SiteGroups)
INSERT INTO #Sites
(EDISID)
SELECT @InternalEDISID AS EDISID

SELECT @SiteGroupID = SiteGroupID
FROM SiteGroupSites
JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
WHERE TypeID = 1 AND EDISID = @InternalEDISID

INSERT INTO #Sites
(EDISID)
SELECT EDISID
FROM SiteGroupSites
WHERE SiteGroupID = @SiteGroupID AND EDISID <> @InternalEDISID

--SELECT * FROM @Sites

-- Get pumps for secondary sites (note that 1st EDISID IN @Sites is primary site)
INSERT INTO #SitePumpCounts (EDISID, MaxPump)
SELECT PumpSetup.EDISID, MAX(Pump)
FROM PumpSetup
JOIN #Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
WHERE (ValidFrom <= @InternalTo)
AND (ISNULL(ValidTo, @InternalTo) >= @InternalFrom)
AND (ISNULL(ValidTo, @InternalTo) >= @SiteOnline)
GROUP BY PumpSetup.EDISID, Sites.CellarID
ORDER BY CellarID

--SELECT * FROM @SitePumpCounts

INSERT INTO #SitePumpOffsets (EDISID, PumpOffset)
SELECT MainCounts.EDISID, COALESCE(QuaternaryCounts.MaxPump+TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, 
SecondaryCounts.MaxPump, 0)
FROM #SitePumpCounts AS MainCounts
LEFT JOIN #SitePumpCounts AS SecondaryCounts ON SecondaryCounts.Counter+1 = MainCounts.Counter
LEFT JOIN #SitePumpCounts AS TertiaryCounts ON TertiaryCounts.Counter+2 = MainCounts.Counter
LEFT JOIN #SitePumpCounts AS QuaternaryCounts ON QuaternaryCounts.Counter+3 = MainCounts.Counter

--SELECT * FROM @SitePumpOffsets

INSERT INTO #AllSitePumps (PumpID, LocationID, ProductID, FlowRateSpecification, FlowRateTolerance, TemperatureSpecification, TemperatureTolerance, ValidFrom, ValidTo, EDISID, OriginalPumpID)
SELECT Pump+PumpOffset, LocationID, PumpSetup.ProductID,
	ISNULL(SiteProductSpecifications.FlowSpec, Products.FlowRateSpecification),
	ISNULL(SiteProductSpecifications.FlowTolerance, Products.FlowRateTolerance),
	ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification),
	ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance),
	ValidFrom,
	ISNULL(ValidTo, @InternalTo),
	Sites.EDISID,
	Pump
FROM PumpSetup
JOIN #Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
JOIN #SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = PumpSetup.EDISID
JOIN Products ON Products.[ID] = PumpSetup.ProductID
LEFT JOIN SiteProductSpecifications ON Products.ID = SiteProductSpecifications.ProductID AND PumpSetup.EDISID = SiteProductSpecifications.EDISID
WHERE (ValidFrom <= @InternalTo)
AND (ISNULL(ValidTo, @InternalTo) >= @InternalFrom)
AND (ISNULL(ValidTo, @InternalTo) >= @SiteOnline)
AND Products.IsWater = 0
AND (Products.IsCask = 0 OR @InternalIncludeCasks = 1)
AND (Products.IsCask = 1 OR @InternalIncludeKegs = 1)
AND (Products.IsMetric = 0 OR @InternalIncludeMetric = 1)

--SELECT * FROM #AllSitePumps

-- Cache table only has valid data prior to today, so any 'today' queries must ALSO look in the real table
SET @Today = CAST(CONVERT(VARCHAR(10), GETDATE(), 12) AS DATETIME)

SELECT  AllSitePumps.PumpID AS Pump,
		Products.Description AS Product,
		Products.Description + '  ' + CAST(AllSitePumps.PumpID AS VARCHAR) AS PumpAndProduct,
		Locations.Description AS Location,
		ISNULL(SUM(DispenseSummary.Quantity),0) AS Quantity,
		ISNULL(SUM(DispenseSummary.QuantityInSpec),0) AS QuantityInSpec,
		ISNULL(SUM(DispenseSummary.QuantityInAmber),0) AS QuantityInAmber,
		ISNULL(SUM(DispenseSummary.QuantityOutOfSpec),0) AS QuantityOutOfSpec,
		ISNULL(AVG(DispenseSummary.AverageFlowRate),0) AS AverageFlowRate,
		MIN(AllSitePumps.FlowRateSpecification) AS FlowRateSpecification,
		MIN(AllSitePumps.FlowRateTolerance) AS FlowRateTolerance,
		MIN(AllSitePumps.TemperatureSpecification) AS TemperatureSpecification,
		MIN(AllSitePumps.TemperatureTolerance) AS TemperatureTolerance
FROM #AllSitePumps AS AllSitePumps
LEFT JOIN (
	SELECT  EDISID,
			TradingDay,
			Pump,
			ProductID,
			LocationID,
			SUM(Quantity) AS Quantity,
			SUM(QuantityInSpec) AS QuantityInSpec,
			SUM(QuantityInAmber) AS QuantityInAmber,
			SUM(QuantityOutOfSpec) AS QuantityOutOfSpec,
			AVG(AverageFlowRate) AS AverageFlowRate
	FROM PeriodCacheQuality
	WHERE EDISID IN (SELECT EDISID FROM #Sites) AND
		  TradingDay BETWEEN @InternalFrom AND @InternalTo AND
		  TradingDay >= @SiteOnline AND
		  TradingDay < @Today AND
		  @IgnoreQualityCache = 0
	AND NOT EXISTS (SELECT ID
			FROM ServiceIssuesQuality AS siq
			WHERE siq.DateFrom <= TradingDay
			AND (siq.DateTo IS NULL OR siq.DateTo >= TradingDay)
			AND siq.RealEDISID = PeriodCacheQuality.EDISID
			AND siq.ProductID = PeriodCacheQuality.ProductID
			AND siq.PumpID = PeriodCacheQuality.Pump
			AND @ExcludeServiceIssues = 1
		  )
	GROUP BY EDISID,
			 TradingDay,
			 Pump,
			 ProductID,
			 LocationID
	
	UNION
	
	SELECT  DispenseActions.EDISID,
			TradingDay,
			Pump,
			Product AS ProductID,
			Location AS LocationID,
			SUM(Pints) AS Quantity,
			SUM(CASE WHEN (AverageTemperature >= ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) - ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance) OR @InternalUnderSpecIsInSpec = 1)
				  AND AverageTemperature <= ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) + ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance) THEN Pints ELSE 0 END) AS QuantityInSpec,
			SUM(CASE WHEN (AverageTemperature < ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) - ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance)
				  AND AverageTemperature >= ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) - ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance) - @InternalTemperatureAmberValue
				  AND @InternalUnderSpecIsInSpec = 0)
				  OR (AverageTemperature > ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) + ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance)
				  AND AverageTemperature <= ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) + ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance) + @InternalTemperatureAmberValue)
				 THEN Pints ELSE 0 END) AS QuantityInAmber,
			SUM(CASE WHEN (AverageTemperature < ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) - ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance) - @InternalTemperatureAmberValue
				  AND @InternalUnderSpecIsInSpec = 0)
				  OR AverageTemperature > ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) + ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance) + @InternalTemperatureAmberValue THEN Pints ELSE 0 END) AS QuantityOutOfSpec,
			ISNULL(AVG(Duration/dbo.fnConvertSiteDispenseVolume(DispenseActions.EDISID, Pints)),0) AS AverageFlowRate
	FROM DispenseActions WITH (INDEX ([IX_DispenseActions_ForQuality]))
	JOIN Products ON Products.[ID] = DispenseActions.Product
	LEFT JOIN SiteProductSpecifications ON SiteProductSpecifications.ProductID = DispenseActions.Product AND SiteProductSpecifications.EDISID = DispenseActions.EDISID
	WHERE DispenseActions.EDISID IN (SELECT EDISID FROM #Sites) AND
		  (TradingDay >= @Today OR @IgnoreQualityCache = 1) AND
		  TradingDay BETWEEN @InternalFrom AND @InternalTo AND
		  TradingDay >= @SiteOnline AND
		  LiquidType = 2 AND
		  Pints >= 0.3 AND
		  Location IS NOT NULL AND
		  AverageTemperature IS NOT NULL
		  AND NOT EXISTS (SELECT ID
			FROM ServiceIssuesQuality AS siq
			WHERE siq.DateFrom <= TradingDay
			AND (siq.DateTo IS NULL OR siq.DateTo >= TradingDay)
			AND siq.RealEDISID = DispenseActions.EDISID
			AND siq.ProductID = DispenseActions.Product
			AND siq.PumpID = DispenseActions.Pump
			AND @ExcludeServiceIssues = 1
		  )
	GROUP BY DispenseActions.EDISID,
			 TradingDay,
			 Pump,
			 Product,
			 Location

) AS DispenseSummary ON (AllSitePumps.EDISID = DispenseSummary.EDISID AND
						 AllSitePumps.OriginalPumpID = DispenseSummary.Pump AND
						 AllSitePumps.LocationID = DispenseSummary.LocationID AND
						 AllSitePumps.ProductID = DispenseSummary.ProductID AND
						 DispenseSummary.TradingDay BETWEEN AllSitePumps.ValidFrom AND AllSitePumps.ValidTo)
JOIN Locations ON (Locations.ID = AllSitePumps.LocationID)
JOIN Products ON (Products.ID = AllSitePumps.ProductID)
LEFT JOIN SiteProductSpecifications ON (Products.ID = SiteProductSpecifications.ProductID AND @InternalEDISID = SiteProductSpecifications.EDISID)
GROUP BY AllSitePumps.PumpID,
		Products.Description,
		Products.Description + '  ' + CAST(AllSitePumps.PumpID AS VARCHAR),
		Locations.Description

DROP TABLE #Sites
DROP TABLE #SitePumpCounts
DROP TABLE #SitePumpOffsets
DROP TABLE #AllSitePumps

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteDispenseQuality2] TO PUBLIC
    AS [dbo];

