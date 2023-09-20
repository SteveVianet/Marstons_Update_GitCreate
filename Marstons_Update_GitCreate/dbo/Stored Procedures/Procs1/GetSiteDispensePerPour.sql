CREATE PROCEDURE [dbo].[GetSiteDispensePerPour]
(
    @EDISID						INT,
    @From						DATETIME,
    @To							DATETIME,
    @IncludeCasks				BIT = 1,
    @IncludeKegs				BIT = 1,
    @IncludeMetric				BIT = 0,
    @IncludeUnknownLiquidTypes	BIT = 0
)
AS

SET NOCOUNT ON

/* Based on [dbo].[GetWebSiteDispensePerPour]
*/

DECLARE @Sites TABLE(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
DECLARE @SiteGroupID INT
DECLARE @SitePumpCounts TABLE([Counter] INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL, PumpOffset INT NOT NULL)
DECLARE @SiteOnline DATETIME
DECLARE @AllSitePumps TABLE
    (PumpID INT NOT NULL, LocationID INT NOT NULL, ProductID INT NOT NULL,
     FlowRateSpecification FLOAT NOT NULL, FlowRateTolerance FLOAT NOT NULL,
     TemperatureSpecification FLOAT NOT NULL, TemperatureTolerance FLOAT NOT NULL,
     ValidFrom DATETIME NOT NULL, ValidTo DATETIME NOT NULL)

DECLARE @PrimaryProducts TABLE(ProductID INT NOT NULL, PrimaryProductID INT NOT NULL)

SELECT @SiteOnline = SiteOnline
FROM dbo.Sites
WHERE EDISID = @EDISID

-- Find out which EDISIDs are relevant (plough through SiteGroups)
INSERT INTO @Sites (EDISID)
SELECT @EDISID AS EDISID

SELECT @SiteGroupID = SiteGroupID
FROM SiteGroupSites
JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
WHERE TypeID = 1 AND EDISID = @EDISID

INSERT INTO @Sites (EDISID)
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

-- This is awful...
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
	CAST(DATEADD(dd, 0, DATEDIFF(dd, 0, TradingDay)) + CONVERT(VARCHAR(10), StartTime, 108) AS DATETIME) AS TradingDateAndTime,
    Pump + PumpOffset AS Pump,
	PrimaryProducts2.[Description] AS Product,
	Locations.[Description] AS Location,
	LiquidTypes.[Description] AS LiquidType,
	Pints AS Quantity,
	EstimatedDrinks AS Drinks
FROM DispenseActions
JOIN Locations ON Locations.[ID] = DispenseActions.Location
JOIN LiquidTypes ON LiquidTypes.ID = DispenseActions.LiquidType
LEFT OUTER JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = DispenseActions.Product
LEFT OUTER JOIN Products AS PrimaryProducts2 ON PrimaryProducts2.[ID] = ISNULL(PrimaryProducts.PrimaryProductID, DispenseActions.Product)
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = DispenseActions.EDISID
JOIN @AllSitePumps AS AllSitePumps ON (
    AllSitePumps.PumpID = DispenseActions.Pump + PumpOffset 
    AND
	AllSitePumps.ProductID = DispenseActions.Product)
WHERE TradingDay BETWEEN @From AND @To
AND TradingDay >= @SiteOnline
AND (PrimaryProducts2.IsCask = 0 OR @IncludeCasks = 1)
AND (PrimaryProducts2.IsCask = 1 OR @IncludeKegs = 1)
AND (PrimaryProducts2.IsMetric = 0 OR @IncludeMetric = 1)
AND (@IncludeUnknownLiquidTypes = 1 OR LiquidType <> 0)
ORDER BY StartTime, Pump+PumpOffset

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteDispensePerPour] TO [fusion]
    AS [dbo];

