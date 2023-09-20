
CREATE PROCEDURE [dbo].[GetWebSiteDispensePerPour2]
(
	@EDISID						INT,
	@From						DATETIME,
	@To							DATETIME,
	@IncludeCasks				BIT,
	@IncludeKegs				BIT,
	@IncludeMetric				BIT,
	@Pump						INT,
	@TemperatureAmberValue		FLOAT = 2,
	@UnderSpecIsInSpec			BIT = 1,
	@IncludeUnknownLiquidTypes	BIT = 0,
	@ExcludeServiceIssues		BIT = 0
)
AS

SET NOCOUNT ON

DECLARE @Sites TABLE(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
DECLARE @SiteGroupID INT
DECLARE @SitePumpCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL, PumpOffset INT NOT NULL)
DECLARE @SiteOnline DATETIME
DECLARE @AllSitePumps TABLE(PumpID INT NOT NULL, LocationID INT NOT NULL, ProductID INT NOT NULL,
				      FlowRateSpecification FLOAT NOT NULL, FlowRateTolerance FLOAT NOT NULL,
				      TemperatureSpecification FLOAT NOT NULL, TemperatureTolerance FLOAT NOT NULL,
				      ValidFrom DATETIME NOT NULL, ValidTo DATETIME NOT NULL)

DECLARE @PrimaryProducts TABLE(ProductID INT NOT NULL, PrimaryProductID INT NOT NULL)

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
GROUP BY PumpSetup.EDISID, Sites.CellarID
ORDER BY CellarID

INSERT INTO @SitePumpOffsets (EDISID, PumpOffset)
SELECT MainCounts.EDISID, COALESCE(QuaternaryCounts.MaxPump+TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, SecondaryCounts.MaxPump, 0)
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

SELECT  DispenseActions.EDISID,
	StartTime AS DateAndTime,
	CAST(DATEADD(dd, 0, DATEDIFF(dd, 0, TradingDay)) + CONVERT(VARCHAR(10), StartTime, 108) AS DATETIME) AS TradingDateAndTime,
	Products.Description AS Product,
	Products.[ID] AS ProductID,
	PrimaryProducts2.Description AS PrimaryProduct,
	PrimaryProducts2.[ID] AS PrimaryProductID,
	Locations.Description AS Location,
	LiquidTypes.[ID] AS LiquidTypeID,
	LiquidTypes.[Description] AS LiquidType,
	Pints AS Quantity,
	Pump + PumpOffset AS Pump,
	Duration,
	EstimatedDrinks AS Drinks,
	AverageTemperature,
	CASE 
		WHEN AverageTemperature <= (AllSitePumps.TemperatureSpecification + AllSitePumps.TemperatureTolerance) AND @UnderSpecIsInSpec = 1
			--Temperature is below the GREEN limit and they don't care about heart-stoppingly low temperatures
			THEN 1
		WHEN AverageTemperature <= (AllSitePumps.TemperatureSpecification + AllSitePumps.TemperatureTolerance) AND AverageTemperature >= (AllSitePumps.TemperatureSpecification - AllSitePumps.TemperatureTolerance)
			--Temperature is within the GREEN limit, not too high and not too low
			THEN 1
		WHEN AverageTemperature BETWEEN (AllSitePumps.TemperatureSpecification + AllSitePumps.TemperatureTolerance) AND (AllSitePumps.TemperatureSpecification + AllSitePumps.TemperatureTolerance + @TemperatureAmberValue)
			--Temperature is within the AMBER limit
			THEN 2
		WHEN AverageTemperature > (AllSitePumps.TemperatureSpecification + AllSitePumps.TemperatureTolerance + @TemperatureAmberValue)
			--Temperature is outside any pre-defined limits, RED
			THEN 3
	END AS TemperatureStatus,	
	DispenseActions.MinimumTemperature AS MinTemp,
	DispenseActions.MaximumTemperature AS MaxTemp,
	DispenseActions.MinimumConductivity AS MinCond,
	DispenseActions.MaximumConductivity AS MaxCond,
	DispenseActions.AverageConductivity AS AvgCond,
	ISNULL(OriginalLiquidTypes.[Description], LiquidTypes.[Description]) AS OriginalLiquidType,
	Products.IsMetric,
	ISNULL(IFMLiquidTypes.[Description], LiquidTypes.[Description]) AS IFMLiquidTypeDescription,
	Products.IsCask,
	Pump AS RealPumpID
FROM DispenseActions
JOIN Products ON Products.[ID] = DispenseActions.Product
JOIN Locations ON Locations.[ID] = DispenseActions.Location
JOIN LiquidTypes ON LiquidTypes.ID = DispenseActions.LiquidType
LEFT OUTER JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = DispenseActions.Product
LEFT OUTER JOIN Products AS PrimaryProducts2 ON PrimaryProducts2.[ID] = ISNULL(PrimaryProducts.PrimaryProductID, DispenseActions.Product)
LEFT OUTER JOIN LiquidTypes AS OriginalLiquidTypes ON OriginalLiquidTypes.[ID] = DispenseActions.OriginalLiquidType
LEFT OUTER JOIN LiquidTypes AS IFMLiquidTypes ON IFMLiquidTypes.[ID] = ISNULL(DispenseActions.IFMLiquidType, DispenseActions.OriginalLiquidType)
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = DispenseActions.EDISID
JOIN @AllSitePumps AS AllSitePumps ON (AllSitePumps.PumpID = DispenseActions.Pump + PumpOffset AND
			    			AllSitePumps.ProductID = DispenseActions.Product)
WHERE TradingDay BETWEEN @From AND @To
AND NOT EXISTS
(
	SELECT ID
	FROM ServiceIssuesQuality AS siq
	WHERE siq.DateFrom <= TradingDay
		AND (siq.DateTo IS NULL OR siq.DateTo >= TradingDay)
		AND siq.RealEDISID = DispenseActions.EDISID
		AND siq.ProductID = DispenseActions.Product
		AND @ExcludeServiceIssues = 1
)
AND TradingDay >= @SiteOnline
AND (Products.IsCask = 0 OR @IncludeCasks = 1)
AND (Products.IsCask = 1 OR @IncludeKegs = 1)
AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
AND (Pump + PumpOffset = @Pump OR @Pump IS NULL)
AND (@IncludeUnknownLiquidTypes = 1 OR LiquidType <> 0)
ORDER BY StartTime, Pump+PumpOffset

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteDispensePerPour2] TO PUBLIC
    AS [dbo];

