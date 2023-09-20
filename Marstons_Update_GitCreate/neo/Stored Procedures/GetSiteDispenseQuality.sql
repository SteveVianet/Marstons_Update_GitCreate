/* If [GetSiteDispenseQuality] and [GetWebSiteDispenseQuality] had a baby, this procedure is that baby. */
CREATE PROCEDURE [neo].[GetSiteDispenseQuality]
(
    @EDISID INT,
    @From   DATE,
    @To     DATE,
    @IncludeCasks   BIT = 1,
    @IncludeKegs    BIT = 1,
    @IncludeMetric  BIT = 0,
    @TemperatureAmberValue  FLOAT = 2,
    @UnderSpecIsInSpec      BIT = 1,
    @ExcludeServiceIssues   BIT = 0
)
AS

/* For Testing */
--DECLARE @EDISID INT = 625 -- test value
--DECLARE @From   DATE = '2016-11-14'
--DECLARE @To     DATE = '2016-11-20'
--DECLARE @IncludeCasks   BIT = 1
--DECLARE @IncludeKegs    BIT = 1
--DECLARE @IncludeMetric  BIT = 0
--DECLARE @TemperatureAmberValue  FLOAT = 2
--DECLARE @UnderSpecIsInSpec      BIT = 1
--DECLARE @ExcludeServiceIssues   BIT = 0

SET NOCOUNT ON

DECLARE @InternalEDISID                 INT
DECLARE @InternalFrom                   DATETIME
DECLARE @InternalTo                     DATETIME
DECLARE @InternalIncludeCasks           BIT
DECLARE @InternalIncludeKegs            BIT
DECLARE @InternalIncludeMetric          BIT
DECLARE @InternalTemperatureAmberValue  FLOAT
DECLARE @InternalUnderSpecIsInSpec      BIT
DECLARE @IgnoreQualityCache             BIT

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
DECLARE @LowTemperatureSaneThreshold FLOAT
DECLARE @HighTemperatureSaneThreshold FLOAT

DECLARE @Sites TABLE (EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
DECLARE @SitePumpCounts TABLE ([Counter] INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE (EDISID INT NOT NULL, PumpOffset INT NOT NULL)
DECLARE @AllSitePumps TABLE (
    PumpID INT NOT NULL, LocationID INT NOT NULL, ProductID INT NOT NULL,
    FlowRateSpecification FLOAT NOT NULL, FlowRateTolerance FLOAT NOT NULL,
    TemperatureSpecification FLOAT NOT NULL, TemperatureTolerance FLOAT NOT NULL,
    ValidFrom DATETIME NOT NULL, ValidTo DATETIME NOT NULL, EDISID INT NOT NULL, OriginalPumpID INT NOT NULL)

DECLARE @AllProducts TABLE (
    Pump INT, ProductID INT, ChildProductID INT,
    [Location] VARCHAR(50), Quantity FLOAT,
    QuantityInSpec FLOAT, QuantityInAmber FLOAT, QuantityOutOfSpec FLOAT, AverageFlowRate FLOAT, 
	FlowRateSpecification INT, FlowRateTolerance INT, TemperatureSpecification INT, TemperatureTolerance INT, AverageTemperature FLOAT)

DECLARE @PrimaryProducts TABLE(ProductID INT NOT NULL, PrimaryProductID INT NOT NULL)

SELECT @LowTemperatureSaneThreshold = CAST(PropertyValue AS FLOAT)
FROM [Configuration]
WHERE PropertyName = 'Low Sane Product Temperature'

SELECT @HighTemperatureSaneThreshold = CAST(PropertyValue AS FLOAT)
FROM [Configuration]
WHERE PropertyName = 'High Sane Product Temperature'

SELECT @SiteOnline = SiteOnline
FROM dbo.Sites
WHERE EDISID = @InternalEDISID

-- Find out which EDISIDs are relevant (plough through SiteGroups)
INSERT INTO @Sites
(EDISID)
SELECT @InternalEDISID AS EDISID

SELECT @SiteGroupID = SiteGroupID
FROM SiteGroupSites
JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
WHERE TypeID = 1 AND EDISID = @InternalEDISID

INSERT INTO @Sites
(EDISID)
SELECT EDISID
FROM SiteGroupSites
WHERE SiteGroupID = @SiteGroupID AND EDISID <> @InternalEDISID

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

-- Get pumps for secondary sites (note that 1st EDISID IN @Sites is primary site)
INSERT INTO @SitePumpCounts (EDISID, MaxPump)
SELECT PumpSetup.EDISID, MAX(Pump)
FROM PumpSetup
JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
WHERE (ValidFrom <= @InternalTo)
AND (ISNULL(ValidTo, @InternalTo) >= @InternalFrom)
AND (ISNULL(ValidTo, @InternalTo) >= @SiteOnline)
GROUP BY PumpSetup.EDISID, Sites.CellarID
ORDER BY CellarID

INSERT INTO @SitePumpOffsets (EDISID, PumpOffset)
SELECT MainCounts.EDISID, COALESCE(QuaternaryCounts.MaxPump+TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, 
SecondaryCounts.MaxPump, 0)
FROM @SitePumpCounts AS MainCounts
LEFT JOIN @SitePumpCounts AS SecondaryCounts ON SecondaryCounts.Counter+1 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS TertiaryCounts ON TertiaryCounts.Counter+2 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS QuaternaryCounts ON QuaternaryCounts.Counter+3 = MainCounts.Counter

INSERT INTO @AllSitePumps (PumpID, LocationID, ProductID, FlowRateSpecification, FlowRateTolerance, TemperatureSpecification, TemperatureTolerance, ValidFrom, ValidTo, EDISID, OriginalPumpID)
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
JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = PumpSetup.EDISID
JOIN Products ON Products.[ID] = PumpSetup.ProductID
LEFT JOIN SiteProductSpecifications ON Products.ID = SiteProductSpecifications.ProductID AND PumpSetup.EDISID = SiteProductSpecifications.EDISID
WHERE (ValidFrom <= @InternalTo)
AND (ISNULL(ValidTo, @InternalTo) >= @InternalFrom)
AND (ISNULL(ValidTo, @InternalTo) >= @SiteOnline)
AND Products.IsWater = 0
AND (Products.IsCask = 0 OR @InternalIncludeCasks = 1)
AND (Products.IsCask = 1 OR @InternalIncludeKegs = 1)
AND (Products.IsMetric = 0 OR @InternalIncludeMetric = 1)
AND	PumpSetup.InUse = 1

-- The above was mostly taken from GetWebSiteDispenseQuality
-- The below is from GetWebSiteDispenseQuality but altered to function more like GetSiteDispenseQuality (affects the AVG values)
INSERT INTO @AllProducts
SELECT
    AllSitePumps.PumpID AS [Pump],
	COALESCE(pp.PrimaryProductID,Products.[ID])  AS [ProductID],
	Products.[ID] AS [ChildProdID],
    --Products.[Description] AS [Product],
    --Products.[Description] + ' ' + CAST(AllSitePumps.PumpID AS VARCHAR(10)) AS [PumpAndProduct],
    Locations.[Description] AS [Location],
    ISNULL(SUM(DispenseActions.Pints),0) AS [Quantity],
    ISNULL(SUM(
        CASE WHEN 
                (AverageTemperature >= AllSitePumps.TemperatureSpecification - AllSitePumps.TemperatureTolerance 
                 OR @InternalUnderSpecIsInSpec = 1)
             AND 
                (AverageTemperature <= AllSitePumps.TemperatureSpecification + AllSitePumps.TemperatureTolerance)
        THEN Pints
        ELSE 0 
        END),0) AS QuantityInSpec,

    ISNULL(SUM(
        CASE WHEN 
                (AverageTemperature < AllSitePumps.TemperatureSpecification - AllSitePumps.TemperatureTolerance
                 AND AverageTemperature >= AllSitePumps.TemperatureSpecification - AllSitePumps.TemperatureTolerance - @InternalTemperatureAmberValue
                 AND @InternalUnderSpecIsInSpec = 0)
             OR
                (AverageTemperature > AllSitePumps.TemperatureSpecification + AllSitePumps.TemperatureTolerance
                 AND AverageTemperature <= AllSitePumps.TemperatureSpecification + AllSitePumps.TemperatureTolerance + @InternalTemperatureAmberValue)
        THEN Pints 
        ELSE 0 
        END),0) AS QuantityInAmber,

    ISNULL(SUM(
        CASE WHEN 
                (AverageTemperature < AllSitePumps.TemperatureSpecification - AllSitePumps.TemperatureTolerance - @InternalTemperatureAmberValue 
                 AND @InternalUnderSpecIsInSpec = 0)
             OR
                (AverageTemperature > AllSitePumps.TemperatureSpecification + AllSitePumps.TemperatureTolerance + @InternalTemperatureAmberValue)
        THEN Pints 
        ELSE 0 
        END),0) AS QuantityOutOfSpec,

    ISNULL(AVG(DispenseActions.Duration/dbo.fnConvertSiteDispenseVolume(DispenseActions.EDISID, DispenseActions.Pints)),0) AS [AverageFlowRate],
    AllSitePumps.FlowRateSpecification AS [FlowRateSpecification],
    AllSitePumps.FlowRateTolerance AS [FlowRateTolerance],
	
----------
    AllSitePumps.TemperatureSpecification AS [TemperatureSpecification],
    AllSitePumps.TemperatureTolerance AS [TemperatureTolerance],
    ISNULL(AVG(DispenseActions.AverageTemperature),0) AS [AverageTemperature]
----------

FROM @AllSitePumps AS AllSitePumps 
JOIN Locations 
    ON AllSitePumps.LocationID = Locations.ID
JOIN Products 
    ON AllSitePumps.ProductID = Products.ID
LEFT JOIN @PrimaryProducts AS pp ON pp.ProductID = [Products].[ID]
LEFT JOIN DispenseActions 
    ON  AllSitePumps.EDISID = DispenseActions.EDISID
    AND AllSitePumps.OriginalPumpID = DispenseActions.Pump
    AND AllSitePumps.LocationID = DispenseActions.[Location]
    AND AllSitePumps.ProductID = DispenseActions.Product
    AND DispenseActions.TradingDay BETWEEN @InternalFrom AND @InternalTo
    AND DispenseActions.TradingDay >= @SiteOnline
    AND DispenseActions.LiquidType = 2
    AND DispenseActions.Pints >= 0.3
WHERE
    (Products.IsCask = 0 OR @IncludeCasks = 1)
AND (Products.IsCask = 1 OR @IncludeKegs = 1)
AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
AND NOT EXISTS (
    SELECT ID
    FROM ServiceIssuesQuality AS siq
    WHERE siq.DateFrom <= TradingDay
    AND (siq.DateTo IS NULL OR siq.DateTo >= TradingDay)
    AND siq.RealEDISID = DispenseActions.EDISID
    AND siq.ProductID = DispenseActions.Product
    AND siq.PumpID = DispenseActions.Pump
    AND @ExcludeServiceIssues = 1
    ) 
GROUP BY 
    AllSitePumps.PumpID,
	Products.[ID],
	pp.PrimaryProductID,
    --Products.[Description],
    --Products.[Description] + ' ' + CAST(AllSitePumps.PumpID AS VARCHAR(10)),
    Locations.[Description],
    AllSitePumps.FlowRateSpecification,
    AllSitePumps.FlowRateTolerance,
    AllSitePumps.TemperatureSpecification,
    AllSitePumps.TemperatureTolerance

SELECT 
	Pump,
	ChildProductID,
	ProductID,
	Products.Description AS [Products],
	--Products,
	--PumpAndProduct,
	[Location],
	Quantity,
	QuantityInSpec,
	QuantityInAmber,
	QuantityOutOfSpec,

	CASE 
		WHEN (QuantityInSpec > 0 AND QuantityInAmber = 0 AND QuantityOutOfSpec = 0)
			THEN 0
		WHEN (QuantityInAmber > 0 AND QuantityOutOfSpec = 0)
			THEN 1
		WHEN (QuantityInAmber = 0 AND QuantityOutOfSpec > 0)
			THEN 2
		WHEN (QuantityInAmber > 0 AND QuantityOutOfSpec > 0)
			THEN 2
		ELSE
		0
	END AS TemperatureStatus,

	AverageFlowRate,
	AP.FlowRateSpecification,
	AP.FlowRateTolerance,
	AP.TemperatureSpecification,
	AP.TemperatureTolerance,
	AverageTemperature
FROM @AllProducts AS AP
LEFT JOIN Products ON Products.ID = AP.ProductID

GO
GRANT EXECUTE
    ON OBJECT::[neo].[GetSiteDispenseQuality] TO PUBLIC
    AS [dbo];

