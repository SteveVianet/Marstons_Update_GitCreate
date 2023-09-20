CREATE PROCEDURE [dbo].[GetSiteRawDispenseConditions]
(
	@EDISID			INT,
	@From				DATETIME,
	@To				DATETIME,
	@GroupingInterval		INT,
	@IncludeCasks			BIT,
	@IncludeKegs			BIT,
	@IncludeMetric			BIT,
	@LiquidType			INT = NULL,
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
	@Pump			INT = NULL,
	@ProductID			INT = NULL,
	@Hour				INT = NULL,
	@IncludeLiquidUnknown	BIT = 1,
	@IncludeLiquidWater		BIT = 1,
	@IncludeLiquidBeer		BIT = 1,
	@IncludeLiquidCleaner		BIT = 1,
	@IncludeLiquidInTransition	BIT = 1,
	@IncludeLiquidBeerInClean	BIT = 1,
	@IncludeProductGroup        BIT = 0
)
AS

SET NOCOUNT ON

DECLARE @Sites TABLE(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
DECLARE @SiteGroupID INT
DECLARE @SitePumpCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL, PumpOffset INT NOT NULL)

DECLARE @PrimaryProducts TABLE(ProductID INT NOT NULL, PrimaryProductID INT NOT NULL)

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


IF @GroupingInterval = 0
BEGIN
	SELECT  DispenseActions.EDISID,
		DispenseActions.StartTime AS [DateAndTime],
		--CAST(DATEADD(dd, 0, DATEDIFF(dd, 0, TradingDay)) + CONVERT(VARCHAR(10), StartTime, 108) AS DATETIME) AS TradingDateAndTime,
		CAST(CAST(TradingDay AS DATE) AS DATETIME) + CAST(StartTime AS TIME) AS TradingDateAndTime, -- TFS: 7944 - Trading and Non-Trading times would go out of sync by up to1 second
		DispenseActions.Product AS ProductID,
		Products.Description AS Product,
		LiquidType,
		COALESCE(OriginalLiquidType, LiquidType) AS OriginalLiquidType,
		COALESCE(IFMLiquidType, OriginalLiquidType, LiquidType) AS IFMLiquidType,
		CAST(PintsBackup AS INT) AS SuggestedLiquidType,
		Pints AS Quantity,
		DispenseActions.Pump AS SitePump,
		Pump + PumpOffset AS Pump,
		Duration,
		EstimatedDrinks AS Drinks,
		MinimumTemperature,
		MaximumTemperature,
		AverageTemperature,
		MinimumConductivity,
		MaximumConductivity,
		AverageConductivity
	FROM DispenseActions
	JOIN Products ON Products.[ID] = DispenseActions.Product
	JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = DispenseActions.EDISID
	LEFT OUTER JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = DispenseActions.Product
	WHERE TradingDay BETWEEN @From AND @To
	AND DispenseActions.EDISID IN (SELECT EDISID FROM @Sites)
	AND (Products.IsCask = 0 OR @IncludeCasks = 1)
	AND (Products.IsCask = 1 OR @IncludeKegs = 1)
	AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
	AND (LiquidType = @LiquidType OR @LiquidType IS NULL)
	AND (Pints >= @MinimumQuantity OR @MinimumQuantity IS NULL)
	AND (Pints <= @MaximumQuantity OR @MaximumQuantity IS NULL)
	AND (Duration >= @MinimumDuration OR @MinimumDuration IS NULL)
	AND (Duration <= @MaximumDuration OR @MaximumDuration IS NULL)
	AND (EstimatedDrinks  >= @MinimumDrinks OR @MinimumDrinks IS NULL)
	AND (EstimatedDrinks <= @MaximumDrinks OR @MaximumDrinks IS NULL)
	AND (MinimumTemperature >= @MinimumTemperature OR @MinimumTemperature IS NULL)
	AND (MinimumTemperature <= @MaximumTemperature OR @MaximumTemperature IS NULL)
	AND (MinimumConductivity >= @MinimumConductivity OR @MinimumConductivity IS NULL OR MinimumConductivity IS NULL)
	AND (MaximumConductivity <= @MaximumConductivity OR @MaximumConductivity IS NULL OR MaximumConductivity IS NULL)
	AND (Pump + PumpOffset = @Pump OR @Pump IS NULL)
	AND ((@IncludeProductGroup = 1 AND PrimaryProducts.PrimaryProductID = @ProductID)
	     OR Product = @ProductID OR @ProductID IS NULL)
	AND (DATEPART(Hour, StartTime) = @Hour OR @Hour IS NULL)
	AND ( (LiquidType = 0 AND @IncludeLiquidUnknown = 1)
		OR (LiquidType = 1 AND @IncludeLiquidWater = 1)
		OR (LiquidType = 2 AND @IncludeLiquidBeer = 1)
		OR (LiquidType = 3 AND @IncludeLiquidCleaner = 1)
		OR (LiquidType = 4 AND @IncludeLiquidInTransition = 1)
		OR (LiquidType = 5 AND @IncludeLiquidBeerInClean = 1) )
	ORDER BY DispenseActions.StartTime
END
ELSE
BEGIN
	SELECT  CAST(STR(DATEPART(YEAR,StartTime)) + '-' + STR(DATEPART(MONTH,StartTime)) + '-' + STR(DATEPART(DAY,StartTime)) + ' ' + STR(DATEPART(HOUR,StartTime)) + ':' + STR((DATEPART(MINUTE, StartTime)/@GroupingInterval)*@GroupingInterval,LEN(DATEPART(MINUTE,StartTime))) + ':00' AS DATETIME) AS [DateAndTime],
		CAST(STR(DATEPART(YEAR,TradingDay)) + '-' + STR(DATEPART(MONTH,TradingDay)) + '-' + STR(DATEPART(DAY,TradingDay)) + ' ' + STR(DATEPART(HOUR,StartTime)) + ':' + STR((DATEPART(MINUTE, StartTime)/@GroupingInterval)*@GroupingInterval,LEN(DATEPART(MINUTE,StartTime))) + ':00' AS DATETIME) AS [TradingDateAndTime],
		DispenseActions.Product AS ProductID,
		Products.Description AS Product,
		LiquidType,
		COALESCE(OriginalLiquidType, LiquidType) AS OriginalLiquidType,
		COALESCE(IFMLiquidType, OriginalLiquidType, LiquidType) AS IFMLiquidType,
		CAST(PintsBackup AS INT) AS SuggestedLiquidType,
		SUM(Pints) AS Quantity,
		Pump + PumpOffset AS Pump,
		SUM(Duration) AS Duration,
		SUM(EstimatedDrinks) AS Drinks,
		MIN(MinimumTemperature) AS MinimumTemperature,
		MAX(MaximumTemperature) AS MaximumTemperature,
		AVG(AverageTemperature) AS AverageTemperature,
		MIN(MinimumConductivity) AS MinimumConductivity,
		MAX(MaximumConductivity) AS MaximumConductivity,
		AVG(AverageConductivity) AS AverageConductivity
	FROM DispenseActions
	JOIN Products ON Products.[ID] = DispenseActions.Product
	JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = DispenseActions.EDISID
	LEFT OUTER JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = DispenseActions.Product
	WHERE TradingDay BETWEEN @From AND @To
	AND DispenseActions.EDISID IN (SELECT EDISID FROM @Sites)
	AND (Products.IsCask = 0 OR @IncludeCasks = 1)
	AND (Products.IsCask = 1 OR @IncludeKegs = 1)
	AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
	AND (LiquidType = @LiquidType OR @LiquidType IS NULL)
	AND (Pints >= @MinimumQuantity OR @MinimumQuantity IS NULL)
	AND (Pints <= @MaximumQuantity OR @MaximumQuantity IS NULL)
	AND (Duration >= @MinimumDuration OR @MinimumDuration IS NULL)
	AND (Duration <= @MaximumDuration OR @MaximumDuration IS NULL)
	AND (EstimatedDrinks  >= @MinimumDrinks OR @MinimumDrinks IS NULL)
	AND (EstimatedDrinks <= @MaximumDrinks OR @MaximumDrinks IS NULL)
	AND (MinimumTemperature >= @MinimumTemperature OR @MinimumTemperature IS NULL)
	AND (MinimumTemperature <= @MaximumTemperature OR @MaximumTemperature IS NULL)
	AND (MinimumConductivity >= @MinimumConductivity OR @MinimumConductivity IS NULL OR MinimumConductivity IS NULL)
	AND (MaximumConductivity <= @MaximumConductivity OR @MaximumConductivity IS NULL OR MaximumConductivity IS NULL)
	AND (Pump + PumpOffset = @Pump OR @Pump IS NULL)
	AND ((@IncludeProductGroup = 1 AND PrimaryProducts.PrimaryProductID = @ProductID)
	     OR Product = @ProductID OR @ProductID IS NULL)
	AND (DATEPART(Hour, StartTime) = @Hour OR @Hour IS NULL)
	AND ( (LiquidType = 0 AND @IncludeLiquidUnknown = 1)
		OR (LiquidType = 1 AND @IncludeLiquidWater = 1)
		OR (LiquidType = 2 AND @IncludeLiquidBeer = 1)
		OR (LiquidType = 3 AND @IncludeLiquidCleaner = 1)
		OR (LiquidType = 4 AND @IncludeLiquidInTransition = 1)
		OR (LiquidType = 5 AND @IncludeLiquidBeerInClean = 1) )
	GROUP BY CAST(STR(DATEPART(YEAR,StartTime)) + '-' + STR(DATEPART(MONTH,StartTime)) + '-' + STR(DATEPART(DAY,StartTime)) + ' ' + STR(DATEPART(HOUR,StartTime)) + ':' + STR((DATEPART(MINUTE, StartTime)/@GroupingInterval)*@GroupingInterval,LEN(DATEPART(MINUTE,StartTime))) + ':00' AS DATETIME),
			 CAST(STR(DATEPART(YEAR,TradingDay)) + '-' + STR(DATEPART(MONTH,TradingDay)) + '-' + STR(DATEPART(DAY,TradingDay)) + ' ' + STR(DATEPART(HOUR,StartTime)) + ':' + STR((DATEPART(MINUTE, StartTime)/@GroupingInterval)*@GroupingInterval,LEN(DATEPART(MINUTE,StartTime))) + ':00' AS DATETIME),
			 Product,
			 Products.Description,
			 LiquidType,
			 COALESCE(OriginalLiquidType, LiquidType),
			 COALESCE(IFMLiquidType, OriginalLiquidType, LiquidType),
			 PintsBackup,
			 Pump+PumpOffset

END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteRawDispenseConditions] TO PUBLIC
    AS [dbo];

