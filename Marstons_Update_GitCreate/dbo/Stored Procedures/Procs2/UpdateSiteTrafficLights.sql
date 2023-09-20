CREATE PROCEDURE [dbo].[UpdateSiteTrafficLights]
(
	@EDISID				INT = NULL,
	@LocalTimeNow		DATETIME,
	@RefreshEstateTLs	BIT = NULL,
	@SiteID				VARCHAR(100) = NULL
)
AS

-- Note that @RefreshEstateTLs is no longer used

SET NOCOUNT ON
SET DATEFIRST 1

DECLARE @PintLimit INT = 1 -- Change to a config option!!

CREATE TABLE #Sites(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY, POSYieldCashValue FLOAT, CleaningCashValue FLOAT, PouringYieldCashValue FLOAT, PrimaryEDISID INT) 

CREATE TABLE #PrimaryProducts(ProductID INT NOT NULL, PrimaryProductID INT NOT NULL) 
CREATE TABLE #SitePumpCounts (Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
CREATE TABLE #SitePumpOffsets (EDISID INT NOT NULL, PumpOffset INT NOT NULL)
CREATE TABLE #SitePumpLastCleans (PumpID INT NOT NULL, LastCleaned DATETIME)

CREATE TABLE #AllSitePumps(PumpID INT NOT NULL, LocationID INT NOT NULL, ProductID INT NOT NULL,
				      DaysBeforeAmber INT NOT NULL, DaysBeforeRed INT NOT NULL,
				      ValidFrom DATETIME NOT NULL, ValidTo DATETIME NOT NULL,
				      EDISID INT NOT NULL, RealPumpID INT NOT NULL, 
				      LastClean DATETIME, Dirty BIT DEFAULT 1,
				      DispenseFrom DATETIME, IsCask BIT, FlowRateSpecification FLOAT, 
				      FlowRateTolerance FLOAT, TemperatureSpecification FLOAT, TemperatureTolerance FLOAT)

CREATE TABLE #WebSiteTLThroughput(EDISID INT, Pump INT, Product VARCHAR(100), Category VARCHAR(100), AvgVolumePerWeek FLOAT, TotalCleaningWastage FLOAT, IsCask BIT)
CREATE TABLE #WebSiteTLCleaning(EDISID INT, Product VARCHAR(100), Location VARCHAR(100), Volume FLOAT, LastClean DATETIME, IsCask BIT, DaysBeforeAmber INT, DaysBeforeRed INT, Pump INT, DirtyDispense FLOAT)
CREATE TABLE #WebSiteTLPouringYield(EDISID INT, Product VARCHAR(100), [Percent] FLOAT, IsCask BIT, IsInErrorThreshold BIT)
CREATE TABLE #WebSiteTLTillYield(EDISID INT, Product VARCHAR(100), [Percent] FLOAT, IsCask BIT, Sold FLOAT, CashValue FLOAT, RetailDispensed FLOAT)
CREATE TABLE #WebSiteTLTemperature(EDISID INT, Pump INT, Product VARCHAR(100), Specification INT, Tolerance INT, Location VARCHAR(100), AcceptableQuantity FLOAT, PoorQuantity FLOAT, IsCask BIT, TotalQuantity FLOAT) 
CREATE TABLE #WebSiteTLEquipment(EDISID INT, Name VARCHAR(100), EquipmentTypeID INT, EquipmentSubTypeID INT, [Type] VARCHAR(100), Location VARCHAR(100), Temperature FLOAT, HasRedTLReadings BIT, HasAmberTLReadings BIT, AlertNoData BIT, AlertDate DATETIME, AlertValue FLOAT)

DECLARE @From DATETIME
DECLARE @To DATETIME
DECLARE @SiteGroupID INT 				      
DECLARE @SiteOnline DATETIME
DECLARE @MaxDaysBackForClean	INT
DECLARE @CheckForCleansFrom DATETIME
DECLARE @IsUSSite BIT
DECLARE @UnderSpecIsInSpec BIT = 1
DECLARE @TemperatureAmberValue INT = 2
DECLARE @Today DATETIME
DECLARE @ThroughputFrom DATETIME
DECLARE @TargetPouringYieldPercent FLOAT
DECLARE @TargetTillYieldPercent FLOAT
DECLARE @EquipmentFrom DATETIME
DECLARE @AlarmFrom DATETIME
DECLARE @DrinksParameter INT
DECLARE @ThroughputLowValue INT
DECLARE @ThroughputAmberTaps INT
DECLARE @ThroughputRedTaps INT
DECLARE @PouringYieldAmberPercentFromTarget INT
DECLARE @PouringYieldRedPercentFromTarget INT
DECLARE @TillYieldAmberPercentFromTarget INT
DECLARE @TillYieldRedPercentFromTarget INT
DECLARE @TemperatureAmberPercentTarget INT
DECLARE @TemperatureRedPercentTarget INT
DECLARE @CleaningAmberPercentTarget INT
DECLARE @CleaningRedPercentTarget INT
DECLARE @IgnoreLocalTime BIT = 0
DECLARE @PrimaryEDISID INT

CREATE TABLE #SiteLowVolume(EDISID INT NOT NULL, TradingDate DATETIME NOT NULL, Pump INT NOT NULL, Product VARCHAR(100) NOT NULL, ProductCategory VARCHAR(100) NOT NULL, Location VARCHAR(100) NOT NULL, WeeklyVolume FLOAT NULL, WeeklyWastedVolume FLOAT NULL, IsCask BIT NOT NULL)
CREATE TABLE #SiteYield(EDISID INT, ProductID INT, Product VARCHAR(100), QuantityDispensed FLOAT, DrinksDispensed FLOAT, OperationalYield FLOAT, Sold FLOAT, RetailYield FLOAT, IsCask BIT, MinPouringYield FLOAT, MaxPouringYield FLOAT, LowPouringYieldErrThreshold FLOAT, HighPouringYieldErrThreshold FLOAT, POSYieldCashValue FLOAT, CleaningCashValue FLOAT, PouringYieldCashValue FLOAT, BeerInLineCleaning FLOAT)
CREATE TABLE #SiteDispenseActions(EDISID INT, Pump INT, TradingDay DATETIME, LiquidType INT, ProductID INT, Pints FLOAT, EstimatedDrinks FLOAT, Location INT, AverageTemperature FLOAT)

IF YEAR(@LocalTimeNow) <= 1900
BEGIN
	SET @LocalTimeNow = GETDATE()
	SET @IgnoreLocalTime = 1
END

IF @SiteID IS NOT NULL
BEGIN
	SELECT @EDISID = EDISID
	FROM Sites
	WHERE SiteID = @SiteID
	
END

SELECT	@TargetPouringYieldPercent = TargetPouringYieldPercent,
		@TargetTillYieldPercent = TargetTillYieldPercent,
		@ThroughputLowValue = ThroughputLowValue,
		@ThroughputAmberTaps = ThroughputAmberTaps,
		@ThroughputRedTaps = ThroughputRedTaps,
		@PouringYieldAmberPercentFromTarget = PouringYieldAmberPercentFromTarget,
		@PouringYieldRedPercentFromTarget = PouringYieldRedPercentFromTarget,
		@TillYieldAmberPercentFromTarget = TillYieldAmberPercentFromTarget,
		@TillYieldRedPercentFromTarget = TillYieldRedPercentFromTarget,
		@TemperatureAmberPercentTarget = TemperatureAmberPercentTarget,
		@TemperatureRedPercentTarget = TemperatureRedPercentTarget,
		@CleaningAmberPercentTarget = CleaningAmberPercentTarget,
		@CleaningRedPercentTarget = CleaningRedPercentTarget
FROM Owners
JOIN Sites ON Sites.OwnerID = Owners.ID
WHERE Sites.EDISID = @EDISID

SELECT @SiteOnline = SiteOnline
FROM dbo.Sites
WHERE EDISID = @EDISID

SELECT @DrinksParameter = CAST(SiteProperties.Value AS INTEGER)
FROM SiteProperties
JOIN Properties ON Properties.ID = SiteProperties.PropertyID
WHERE Properties.Name = 'Drink Actions Parameter'
AND EDISID = @EDISID

SELECT @IsUSSite = CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END
FROM SiteProperties
JOIN Properties ON Properties.ID = SiteProperties.PropertyID
WHERE Properties.Name = 'International'
AND UPPER(SiteProperties.Value) = 'EN-US'

SET @Today = CAST(CONVERT(VARCHAR(10), @LocalTimeNow, 12) AS DATETIME)
SET @To = DATEADD(DAY, -1, @Today)
SET @From = @To

SET @ThroughputFrom = DATEADD(DAY, -27, @To)
SET @EquipmentFrom = DATEADD(HOUR, -12, @LocalTimeNow)
SET @AlarmFrom = DATEADD(day, -7, @LocalTimeNow)

-- Find out which EDISIDs are relevant (plough through SiteGroups) 
INSERT INTO #Sites (EDISID, POSYieldCashValue, CleaningCashValue, PouringYieldCashValue)
SELECT EDISID, POSYieldCashValue, CleaningCashValue, PouringYieldCashValue
FROM Sites
JOIN Owners ON Owners.ID = Sites.OwnerID
WHERE EDISID = @EDISID

SELECT @SiteGroupID = SiteGroupID
FROM SiteGroupSites
JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID WHERE TypeID = 1 AND EDISID = @EDISID

INSERT INTO #Sites (EDISID, POSYieldCashValue, CleaningCashValue, PouringYieldCashValue)
SELECT SiteGroupSites.EDISID, POSYieldCashValue, CleaningCashValue, PouringYieldCashValue
FROM SiteGroupSites
JOIN Sites ON Sites.EDISID = SiteGroupSites.EDISID
JOIN Owners ON Owners.ID = Sites.OwnerID
WHERE SiteGroupSites.SiteGroupID = @SiteGroupID 
AND SiteGroupSites.EDISID <> @EDISID

IF @SiteGroupID > 0
BEGIN
	SELECT @PrimaryEDISID = EDISID
	FROM SiteGroupSites
	WHERE SiteGroupID = @SiteGroupID
	AND IsPrimary = 1

	UPDATE #Sites SET PrimaryEDISID = @PrimaryEDISID

END
ELSE
BEGIN
    SET @PrimaryEDISID = @EDISID

END

-- Get pumps for secondary sites (note that 1st EDISID IN #Sites is primary site)
INSERT INTO #SitePumpCounts (EDISID, MaxPump)
SELECT PumpSetup.EDISID, MAX(Pump)
FROM PumpSetup
JOIN #Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
WHERE (ValidFrom <= @To)
AND (ISNULL(ValidTo, @To) >= @From)
AND (ISNULL(ValidTo, @To) >= @SiteOnline)
GROUP BY PumpSetup.EDISID, Sites.CellarID
ORDER BY CellarID

INSERT INTO #SitePumpOffsets (EDISID, PumpOffset)
SELECT MainCounts.EDISID, COALESCE(QuaternaryCounts.MaxPump+TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, SecondaryCounts.MaxPump, 0)
FROM #SitePumpCounts AS MainCounts
LEFT JOIN #SitePumpCounts AS SecondaryCounts ON SecondaryCounts.Counter+1 = MainCounts.Counter
LEFT JOIN #SitePumpCounts AS TertiaryCounts ON TertiaryCounts.Counter+2 = MainCounts.Counter
LEFT JOIN #SitePumpCounts AS QuaternaryCounts ON QuaternaryCounts.Counter+3 = MainCounts.Counter

INSERT INTO #PrimaryProducts(ProductID, PrimaryProductID) 
SELECT ProductID, ProductGroupPrimaries.PrimaryProductID
FROM ProductGroupProducts
JOIN ProductGroups 
  ON ProductGroups.ID = ProductGroupProducts.ProductGroupID
JOIN (
	SELECT ProductGroupID, ProductID AS PrimaryProductID
	FROM ProductGroupProducts
	JOIN ProductGroups ON ProductGroups.ID = ProductGroupProducts.ProductGroupID
	WHERE TypeID = 1 AND IsPrimary = 1
	) AS ProductGroupPrimaries 
  ON ProductGroupPrimaries.ProductGroupID = ProductGroups.ID 
WHERE TypeID = 1 
  AND IsPrimary = 0

INSERT INTO #AllSitePumps (PumpID, LocationID, ProductID, DaysBeforeAmber, DaysBeforeRed, ValidFrom, ValidTo, EDISID, RealPumpID, IsCask, FlowRateSpecification, FlowRateTolerance, TemperatureSpecification, TemperatureTolerance)
SELECT Pump+PumpOffset, LocationID, PumpSetup.ProductID,
	COALESCE(SiteProductSpecifications.CleanDaysBeforeAmber, SiteSpecifications.CleanDaysBeforeAmber, Products.LineCleanDaysBeforeAmber),
	COALESCE(SiteProductSpecifications.CleanDaysBeforeRed, SiteSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed),
	ValidFrom,
	ISNULL(ValidTo, @To),
	Sites.EDISID,
	PumpSetup.Pump,
	Products.IsCask,
	ISNULL(SiteProductSpecifications.FlowSpec, Products.FlowRateSpecification),
	ISNULL(SiteProductSpecifications.FlowTolerance, Products.FlowRateTolerance),
	ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification),
	ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance)
FROM PumpSetup
JOIN #Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
JOIN #SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = PumpSetup.EDISID
JOIN Products ON Products.[ID] = PumpSetup.ProductID
LEFT JOIN SiteProductSpecifications ON Products.ID = SiteProductSpecifications.ProductID AND PumpSetup.EDISID = SiteProductSpecifications.EDISID
LEFT JOIN SiteSpecifications ON Sites.EDISID = SiteSpecifications.EDISID
WHERE (ValidFrom <= @To)
AND (ISNULL(ValidTo, @To) >= @From)
AND (ISNULL(ValidTo, @To) >= @SiteOnline)
AND Products.IsWater = 0
AND Products.IsMetric = 0

INSERT INTO #SitePumpLastCleans
(PumpID, LastCleaned)
SELECT  AllSitePumps.PumpID,
	MAX(DispenseActions.TradingDay) AS LastCleaned
FROM DispenseActions
JOIN #SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = DispenseActions.EDISID
JOIN #AllSitePumps AS AllSitePumps ON AllSitePumps.PumpID = DispenseActions.Pump + PumpOffset
				     AND AllSitePumps.ProductID = DispenseActions.Product
				     AND AllSitePumps.LocationID = DispenseActions.Location

WHERE DispenseActions.EDISID IN (SELECT EDISID FROM #Sites)
AND TradingDay >= @SiteOnline
AND TradingDay <= @Today			-- This is critical when faking the current date
AND LiquidType = 3
GROUP BY AllSitePumps.PumpID

INSERT INTO #SiteDispenseActions
(EDISID, Pump, TradingDay, LiquidType, ProductID, Pints, EstimatedDrinks, Location, AverageTemperature)
SELECT	DispenseActions.EDISID,
		DispenseActions.Pump,
		TradingDay,
		LiquidType,
		Product,
		Pints,
		EstimatedDrinks,
		Location,
		AverageTemperature
FROM DispenseActions WITH (INDEX ([IX_DispenseActions_ForQuality]))
WHERE DispenseActions.EDISID IN (SELECT EDISID FROM #Sites) AND
		  TradingDay BETWEEN @From AND @To AND
		  TradingDay >= @SiteOnline AND
		  LiquidType IN (2, 3, 5) AND
		  Pints >= 0 --AND
		  --Location IS NOT NULL AND
		  --AverageTemperature IS NOT NULL

SELECT @MaxDaysBackForClean = MAX(DaysBeforeRed) FROM #AllSitePumps
SET @CheckForCleansFrom = DATEADD(Day, -@MaxDaysBackForClean, @From)

-- Find date each pump was last cleaned
UPDATE #AllSitePumps
SET LastClean = LastPumpCleans.LastCleaned,
	Dirty = (CASE WHEN DATEADD([Day], DaysBeforeRed, LastPumpCleans.LastCleaned) < DATEADD([Day], 1, @To) THEN 1 ELSE 0 END),
	DispenseFrom = CASE WHEN DATEADD([Day], DaysBeforeRed, LastPumpCleans.LastCleaned) > @From THEN DATEADD([Day], DaysBeforeRed, LastPumpCleans.LastCleaned) ELSE @From END
FROM #SitePumpLastCleans AS LastPumpCleans
JOIN #AllSitePumps AS AllSitePumps ON LastPumpCleans.PumpID = AllSitePumps.PumpID

UPDATE #AllSitePumps SET DispenseFrom = @From WHERE DispenseFrom IS NULL

--;WITH WeeklyDispense AS (
INSERT INTO #SiteLowVolume
(EDISID, TradingDate, Pump, Product, ProductCategory, Location, WeeklyVolume, WeeklyWastedVolume, IsCask)
SELECT	COALESCE(Sites.PrimaryEDISID, Sites.EDISID),
		DATEADD(dw, -DATEPART(dw, PeriodCacheTradingDispense.TradingDay) + 1, PeriodCacheTradingDispense.TradingDay) AS TradingDate,
		PeriodCacheTradingDispense.Pump + PumpOffset AS Pump,
		Products.[Description] AS Product,
		ProductCategories.[Description] AS ProductCategory,
		Locations.[Description] AS Location,
		SUM(PeriodCacheTradingDispense.Volume) AS WeeklyVolume,
		SUM(PeriodCacheTradingDispense.WastedVolume) AS WeeklyWastedVolume,
		Products.IsCask
FROM PeriodCacheTradingDispense
JOIN Products
  ON Products.ID = PeriodCacheTradingDispense.ProductID
JOIN ProductCategories
  ON ProductCategories.ID = Products.CategoryID
JOIN Locations
  ON Locations.ID = PeriodCacheTradingDispense.LocationID
JOIN #SitePumpOffsets AS SitePumpOffsets 
  ON SitePumpOffsets.EDISID = PeriodCacheTradingDispense.EDISID
JOIN PumpSetup 
  ON PumpSetup.EDISID = PeriodCacheTradingDispense.EDISID
 AND PumpSetup.Pump = PeriodCacheTradingDispense.Pump
 AND PumpSetup.ProductID = PeriodCacheTradingDispense.ProductID
 AND PumpSetup.LocationID = PeriodCacheTradingDispense.LocationID
 AND PumpSetup.ValidTo IS NULL AND PumpSetup.InUse = 1
 JOIN #Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
WHERE PeriodCacheTradingDispense.EDISID IN (SELECT EDISID FROM #Sites)
  AND PeriodCacheTradingDispense.TradingDay BETWEEN @ThroughputFrom AND @To
  AND Products.IncludeInLowVolume = 1
  AND Products.IsMetric = 0
  AND NOT EXISTS (SELECT ID
			FROM ServiceIssuesQuality AS siq
			WHERE siq.DateFrom <= TradingDay
			AND (siq.DateTo IS NULL OR siq.DateTo >= TradingDay)
			AND siq.RealEDISID = PeriodCacheTradingDispense.EDISID
			AND siq.ProductID = Products.ID
			AND siq.RealPumpID = PeriodCacheTradingDispense.Pump
		  )
GROUP BY	COALESCE(Sites.PrimaryEDISID, Sites.EDISID),
			DATEADD(dw, -DATEPART(dw, PeriodCacheTradingDispense.TradingDay) + 1, PeriodCacheTradingDispense.TradingDay),
			PeriodCacheTradingDispense.Pump + PumpOffset,
			Products.[Description],
			ProductCategories.[Description],
			Locations.[Description],
			Products.IsCask
--)


INSERT INTO #SiteYield
(EDISID, ProductID, Product, QuantityDispensed, DrinksDispensed, OperationalYield, Sold, RetailYield, IsCask, MinPouringYield, MaxPouringYield, LowPouringYieldErrThreshold, HighPouringYieldErrThreshold, POSYieldCashValue, CleaningCashValue, PouringYieldCashValue, BeerInLineCleaning)
SELECT  COALESCE(DispenseActions.EDISID, Sales.EDISID) AS EDISID,
		Products.[ID] AS ProductID,
		Products.[Description] AS Product,
		ISNULL(SUM(DispenseActions.Pints),0) AS QuantityDispensed,
		ISNULL(SUM(DispenseActions.EstimatedDrinks),0) AS DrinksDispensed,
		ISNULL(SUM(DispenseActions.EstimatedDrinks),0) - ISNULL(SUM(DispenseActions.Pints),0) AS OperationalYield,
		ISNULL(SUM(Sales.Quantity), 0) AS [Sold],
		ISNULL(SUM(Sales.Quantity),0)-ISNULL(SUM(DispenseActions.EstimatedDrinks),0) AS RetailYield,
		Products.IsCask AS IsCask,
		ISNULL(SiteProductCategorySpecs.MinimumPouringYield, ProductCategories.MinimumPouringYield) AS MinPouringYield,
		ISNULL(SiteProductCategorySpecs.MaximumPouringYield, ProductCategories.MaximumPouringYield) AS MaxPouringYield,
		ISNULL(SiteProductCategorySpecs.LowPouringYieldErrThreshold, ProductCategories.LowPouringYieldErrThreshold) AS LowPouringYieldErrThreshold,
		ISNULL(SiteProductCategorySpecs.HighPouringYieldErrThreshold, ProductCategories.HighPouringYieldErrThreshold) AS HighPouringYieldErrThreshold,
		COALESCE(DispenseActions.POSYieldCashValue, Sales.POSYieldCashValue) AS POSYieldCashValue,
		COALESCE(DispenseActions.CleaningCashValue, Sales.CleaningCashValue) AS CleaningCashValue,
		COALESCE(DispenseActions.PouringYieldCashValue, Sales.PouringYieldCashValue) AS PouringYieldCashValue,
		ISNULL(SUM(DispenseActions.BeerInLineCleaning),0) AS BeerInLineCleaning
FROM Products 
FULL OUTER JOIN (
	SELECT	DispenseActions.EDISID,
			ISNULL(PrimaryProducts.PrimaryProductID, DispenseActions.ProductID) AS ProductID, 
			SUM(CASE WHEN LiquidType = 2 THEN DispenseActions.Pints ELSE 0 END) AS Pints,
			SUM(CASE WHEN LiquidType = 2 THEN DispenseActions.EstimatedDrinks ELSE 0 END) AS EstimatedDrinks,
			POSYieldCashValue,
			CleaningCashValue,
			PouringYieldCashValue,
			SUM(CASE WHEN LiquidType = 5 THEN DispenseActions.Pints ELSE 0 END) AS BeerInLineCleaning
	FROM #SiteDispenseActions AS DispenseActions
	JOIN #Sites AS RelevantSites
      ON RelevantSites.EDISID = DispenseActions.EDISID
    FULL OUTER JOIN #PrimaryProducts AS PrimaryProducts
      ON PrimaryProducts.ProductID = DispenseActions.ProductID
	WHERE LiquidType IN (2, 5)
	AND NOT EXISTS
	(
		SELECT ID
		FROM ServiceIssuesYield AS siy
		WHERE siy.DateFrom <= TradingDay
			AND (siy.DateTo IS NULL OR siy.DateTo >= TradingDay)
			AND siy.RealEDISID = DispenseActions.EDISID
			AND siy.ProductID = DispenseActions.ProductID
	)
	GROUP BY DispenseActions.EDISID, ISNULL(PrimaryProducts.PrimaryProductID, DispenseActions.ProductID), POSYieldCashValue, CleaningCashValue, PouringYieldCashValue
	) AS DispenseActions ON Products.ID = DispenseActions.ProductID
FULL OUTER JOIN (
	SELECT	Sales.EDISID,
			ISNULL(PrimaryProducts.PrimaryProductID, Sales.ProductID) AS ProductID,
			SUM(Sales.Quantity) AS Quantity,
			POSYieldCashValue,
			CleaningCashValue,
			PouringYieldCashValue
	FROM Sales
	JOIN #Sites AS RelevantSites
	  ON RelevantSites.EDISID = Sales.EDISID
    FULL OUTER JOIN #PrimaryProducts AS PrimaryProducts
      ON PrimaryProducts.ProductID = Sales.ProductID
	WHERE (Sales.TradingDate BETWEEN @From AND @To)
	  AND Sales.TradingDate >= @SiteOnline
	  AND NOT EXISTS
		(
			SELECT ID
			FROM ServiceIssuesYield AS siy
			WHERE siy.DateFrom <= TradingDate
				AND (siy.DateTo IS NULL OR siy.DateTo >= TradingDate)
				AND siy.RealEDISID = Sales.EDISID
				AND siy.ProductID = Sales.ProductID
		)
	GROUP BY Sales.EDISID, ISNULL(PrimaryProducts.PrimaryProductID, Sales.ProductID), POSYieldCashValue, CleaningCashValue, PouringYieldCashValue
	) AS Sales
  ON Products.ID = Sales.ProductID AND Sales.EDISID = COALESCE(DispenseActions.EDISID, Sales.EDISID)
JOIN ProductCategories
  ON ProductCategories.ID = Products.CategoryID 
FULL OUTER JOIN (
	SELECT ProductCategoryID, MinimumPouringYield, MaximumPouringYield, HighPouringYieldErrThreshold, LowPouringYieldErrThreshold
	FROM SiteProductCategorySpecifications
	JOIN #Sites AS RelevantSites
	  ON RelevantSites.EDISID = SiteProductCategorySpecifications.EDISID
	) AS SiteProductCategorySpecs
  ON SiteProductCategorySpecs.ProductCategoryID = ProductCategories.ID
WHERE Products.IsWater = 0
AND Products.IsMetric = 0
GROUP BY COALESCE(DispenseActions.EDISID, Sales.EDISID), Products.[ID], Products.[Description], Products.IsCask, ISNULL(SiteProductCategorySpecs.MinimumPouringYield, ProductCategories.MinimumPouringYield), ISNULL(SiteProductCategorySpecs.MaximumPouringYield, ProductCategories.MaximumPouringYield), 	ISNULL(SiteProductCategorySpecs.LowPouringYieldErrThreshold, ProductCategories.LowPouringYieldErrThreshold), ISNULL(SiteProductCategorySpecs.HighPouringYieldErrThreshold, ProductCategories.HighPouringYieldErrThreshold), COALESCE(DispenseActions.POSYieldCashValue, Sales.POSYieldCashValue), COALESCE(DispenseActions.CleaningCashValue, Sales.CleaningCashValue), COALESCE(DispenseActions.PouringYieldCashValue, Sales.PouringYieldCashValue)
HAVING (ISNULL(SUM(DispenseActions.Pints),0) > 0 OR ISNULL(SUM(Sales.Quantity), 0) > 0) 
ORDER BY Products.[Description]


INSERT INTO #WebSiteTLThroughput
(EDISID, Pump, Product, Category, AvgVolumePerWeek, TotalCleaningWastage, IsCask)
SELECT	SiteLowVolume.EDISID,
		SiteLowVolume.Pump,
		SiteLowVolume.Product,
		SiteLowVolume.ProductCategory,
		AVG(SiteLowVolume.WeeklyVolume) AS AverageWeeklyVolume,
		SUM(SiteLowVolume.WeeklyWastedVolume) AS TotalWastedVolume,
		SiteLowVolume.IsCask
FROM #SiteLowVolume AS SiteLowVolume
JOIN #Sites AS Sites
  ON Sites.EDISID = SiteLowVolume.EDISID
JOIN Sites AS SiteDetails
  ON SiteDetails.EDISID = Sites.EDISID
GROUP BY	SiteLowVolume.EDISID,
			SiteLowVolume.Pump,
			SiteLowVolume.Product,
			SiteLowVolume.ProductCategory,
			SiteLowVolume.IsCask
HAVING AVG(SiteLowVolume.WeeklyVolume) < @ThroughputLowValue


INSERT INTO #WebSiteTLCleaning
(EDISID, Product, Location, Volume, LastClean, IsCask, DaysBeforeAmber, DaysBeforeRed, Pump, DirtyDispense)
SELECT	AllSitePumps.EDISID, 
		Products.Description AS Product,
		Locations.Description AS Location,
		SUM(BeerDispense.Quantity) AS Quantity,
		CASE WHEN AllSitePumps.LastClean IS NULL THEN '1899-12-30' ELSE AllSitePumps.LastClean END,
		Products.IsCask,
		DaysBeforeAmber,
		DaysBeforeRed,
		AllSitePumps.PumpID,
		SUM(CASE WHEN DATEDIFF(DAY, CASE WHEN AllSitePumps.LastClean IS NULL THEN '1899-12-30' ELSE AllSitePumps.LastClean END, TradingDay) >= DaysBeforeRed THEN Quantity ELSE 0 END) AS DirtyDispense
FROM #AllSitePumps AS AllSitePumps
JOIN Locations ON (Locations.ID = AllSitePumps.LocationID)
JOIN Products ON (Products.ID = AllSitePumps.ProductID)
LEFT JOIN (
	SELECT	EDISID,
			Pump,
			ProductID,
			Location,
			TradingDay,
			SUM(Pints) AS Quantity
	FROM #SiteDispenseActions AS DispenseActions
	WHERE LiquidType = 2
	GROUP BY EDISID, Pump, TradingDay, ProductID, Location
) AS BeerDispense ON (BeerDispense.EDISID = AllSitePumps.EDISID
						AND BeerDispense.Pump = AllSitePumps.RealPumpID
						AND BeerDispense.TradingDay BETWEEN @From AND @To
						AND BeerDispense.ProductID = AllSitePumps.ProductID
					    AND BeerDispense.Location = AllSitePumps.LocationID)
GROUP BY AllSitePumps.EDISID, AllSitePumps.PumpID, Products.Description, Locations.Description, LastClean, Products.IsCask, DaysBeforeAmber, DaysBeforeRed
HAVING SUM(BeerDispense.Quantity) > 0


INSERT INTO #WebSiteTLPouringYield
(EDISID, Product, [Percent], IsCask, IsInErrorThreshold)
SELECT	EDISID,
		Product,
	    ROUND((DrinksDispensed / dbo.fnConvertSiteDispenseVolume(EDISID, QuantityDispensed)) * 100, 0),
	    IsCask,
	    CASE WHEN ((DrinksDispensed / dbo.fnConvertSiteDispenseVolume(EDISID, QuantityDispensed)) * 100) >= HighPouringYieldErrThreshold OR ((DrinksDispensed / dbo.fnConvertSiteDispenseVolume(EDISID, QuantityDispensed)) * 100) <= LowPouringYieldErrThreshold THEN 1 ELSE 0 END
FROM #SiteYield
WHERE DrinksDispensed <> 0 
AND QuantityDispensed <> 0
AND ((ROUND(DrinksDispensed / QuantityDispensed * 100, 0) > MaxPouringYield) 
OR (ROUND(DrinksDispensed / QuantityDispensed * 100, 0) < MinPouringYield))


INSERT INTO #WebSiteTLTillYield
(EDISID, Product, [Percent], IsCask, Sold, CashValue, RetailDispensed)
SELECT @PrimaryEDISID,
       Product,
       (dbo.fnConvertSiteDispenseVolume(@PrimaryEDISID, SUM(Sold)) / CASE WHEN SUM(DrinksDispensed) = 0 THEN 1 ELSE SUM(DrinksDispensed) END) * 100,
       IsCask,
       SUM(Sold),
       POSYieldCashValue,
       SUM(DrinksDispensed)
FROM #SiteYield
WHERE IsCask = 0
GROUP BY Product, IsCask, POSYieldCashValue


INSERT INTO #WebSiteTLTillYield
(EDISID, Product, [Percent], IsCask, Sold, CashValue, RetailDispensed)
SELECT @PrimaryEDISID,
       'Consolidated Casks',
       (dbo.fnConvertSiteDispenseVolume(@PrimaryEDISID, SUM(Sold)) / CASE WHEN SUM(DrinksDispensed) = 0 THEN 1 ELSE SUM(DrinksDispensed) END) * 100,
       1,
       SUM(Sold),
       POSYieldCashValue,
       SUM(DrinksDispensed)
FROM #SiteYield
WHERE IsCask = 1
GROUP BY POSYieldCashValue


INSERT INTO #WebSiteTLTemperature
(EDISID, Pump, Product, Specification, Tolerance, Location, AcceptableQuantity, PoorQuantity, IsCask, TotalQuantity)
SELECT  AllSitePumps.EDISID,
		AllSitePumps.PumpID AS Pump,
		Products.Description AS Product,
		MIN(AllSitePumps.TemperatureSpecification),
		MIN(AllSitePumps.TemperatureTolerance),
		Locations.Description AS Location,
		ISNULL(SUM(DispenseSummary.QuantityInAmber),0) AS QuantityInAmber,
		ISNULL(SUM(DispenseSummary.QuantityOutOfSpec),0) AS QuantityOutOfSpec,
		Products.IsCask,
		ISNULL(SUM(DispenseSummary.Quantity), 0) AS TotalQuantity
FROM #AllSitePumps AS AllSitePumps
LEFT JOIN (
	SELECT  DispenseActions.EDISID,
			TradingDay,
			Pump,
			DispenseActions.ProductID,
			Location AS LocationID,
			SUM(Pints) AS Quantity,
			SUM(CASE WHEN (AverageTemperature < ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) - ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance)
				  AND AverageTemperature >= ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) - ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance) - @TemperatureAmberValue
				  AND @UnderSpecIsInSpec = 0)
				  OR (AverageTemperature > ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) + ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance)
				  AND AverageTemperature <= ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) + ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance) + @TemperatureAmberValue)
				 THEN Pints ELSE 0 END) AS QuantityInAmber,
			SUM(CASE WHEN (AverageTemperature < ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) - ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance) - @TemperatureAmberValue
				  AND @UnderSpecIsInSpec = 0)
				  OR AverageTemperature > ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) + ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance) + @TemperatureAmberValue THEN Pints ELSE 0 END) AS QuantityOutOfSpec
	FROM #SiteDispenseActions AS DispenseActions
	JOIN Products ON Products.[ID] = DispenseActions.ProductID
	LEFT JOIN SiteProductSpecifications ON SiteProductSpecifications.ProductID = DispenseActions.ProductID AND SiteProductSpecifications.EDISID = DispenseActions.EDISID
	WHERE LiquidType = 2 AND
		  Pints >= 0.3 AND
		  Location IS NOT NULL AND
		  AverageTemperature IS NOT NULL
	AND NOT EXISTS (SELECT ID
					FROM ServiceIssuesQuality AS siq
					WHERE siq.DateFrom <= TradingDay
					AND (siq.DateTo IS NULL OR siq.DateTo >= TradingDay)
					AND siq.RealEDISID = DispenseActions.EDISID
					AND siq.ProductID = DispenseActions.ProductID
					AND siq.RealPumpID = DispenseActions.Pump
		  )
	GROUP BY DispenseActions.EDISID,
			 TradingDay,
			 Pump,
			 DispenseActions.ProductID,
			 Location

) AS DispenseSummary ON (AllSitePumps.EDISID = DispenseSummary.EDISID AND
						 AllSitePumps.RealPumpID = DispenseSummary.Pump AND
						 AllSitePumps.LocationID = DispenseSummary.LocationID AND
						 AllSitePumps.ProductID = DispenseSummary.ProductID AND
						 DispenseSummary.TradingDay BETWEEN AllSitePumps.ValidFrom AND AllSitePumps.ValidTo)
JOIN Locations ON (Locations.ID = AllSitePumps.LocationID)
JOIN Products ON (Products.ID = AllSitePumps.ProductID)
LEFT JOIN SiteProductSpecifications ON (Products.ID = SiteProductSpecifications.ProductID AND DispenseSummary.EDISID = SiteProductSpecifications.EDISID)
GROUP BY AllSitePumps.EDISID,
		 AllSitePumps.PumpID,
		Products.Description,
		Products.Description + '  ' + CAST(AllSitePumps.PumpID AS VARCHAR),
		Locations.Description,
		Products.IsCask
HAVING ISNULL(SUM(DispenseSummary.QuantityInAmber),0) > 0
OR	ISNULL(SUM(DispenseSummary.QuantityOutOfSpec),0) > 0

IF @IgnoreLocalTime = 0
BEGIN
INSERT INTO #WebSiteTLEquipment
(EDISID, Name, EquipmentTypeID, EquipmentSubTypeID, [Type], Location, Temperature, HasRedTLReadings, HasAmberTLReadings, AlertNoData, AlertDate, AlertValue)
SELECT	EquipmentItems.EDISID,
		LTRIM(RTRIM(EquipmentItems.[Description])),
		EquipmentItems.EquipmentTypeID,
		EquipmentTypes.EquipmentSubTypeID,
		EquipmentTypes.[Description],
		Locations.[Description],
		AVG(EquipmentReadings.Value),
		CASE WHEN SUM(EquipmentReadings.RedTL) > 0 THEN 1 ELSE 0 END,
		CASE WHEN SUM(EquipmentReadings.AmberTL) > 0 THEN 1 ELSE 0 END,
		CASE WHEN AVG(EquipmentReadings.Value) IS NULL THEN 1 ELSE 0 END,
		CASE WHEN EquipmentItems.LastAlarmingReading >= @AlarmFrom THEN EquipmentItems.LastAlarmingReading ELSE NULL END,
		CASE WHEN EquipmentItems.LastAlarmingReading >= @AlarmFrom THEN EquipmentItems.LastAlarmingValue ELSE NULL END
FROM EquipmentItems
JOIN #Sites AS Sites ON Sites.EDISID = EquipmentItems.EDISID
JOIN EquipmentTypes ON EquipmentTypes.ID = EquipmentItems.EquipmentTypeID
LEFT JOIN
(
	SELECT	EquipmentReadings.EDISID,
			EquipmentReadings.InputID,
			EquipmentReadings.LogDate,
			EquipmentReadings.LocationID,
			EquipmentTypes.EquipmentSubTypeID,
			EquipmentReadings.Value,
			CASE WHEN (CASE WHEN (CAST( CONVERT( VARCHAR(8), DATEADD(Second, -DATEPART(Second, DATEADD(Minute, -DATEPART(Minute, EquipmentReadings.LogDate), EquipmentReadings.LogDate)), DATEADD(Minute, -DATEPART(Minute, EquipmentReadings.LogDate), EquipmentReadings.LogDate)), 108) AS TIME(0)) BETWEEN EquipmentItems.AlarmStartTime AND DATEADD(SECOND, -1, EquipmentItems.AlarmEndTime)) THEN 1 ELSE 0 END) = 1 AND EquipmentReadings.Value > EquipmentItems.HighAlarmThreshold THEN 1 ELSE 0 END AS RedTL,
			CASE WHEN (CASE WHEN (CAST( CONVERT( VARCHAR(8), DATEADD(Second, -DATEPART(Second, DATEADD(Minute, -DATEPART(Minute, EquipmentReadings.LogDate), EquipmentReadings.LogDate)), DATEADD(Minute, -DATEPART(Minute, EquipmentReadings.LogDate), EquipmentReadings.LogDate)), 108) AS TIME(0)) BETWEEN EquipmentItems.AlarmStartTime AND DATEADD(SECOND, -1, EquipmentItems.AlarmEndTime)) THEN 1 ELSE 0 END) = 1 AND EquipmentReadings.Value > EquipmentItems.ValueHighSpecification THEN 1 ELSE 0 END AS AmberTL
	FROM EquipmentReadings
	JOIN #Sites AS Sites ON Sites.EDISID = EquipmentReadings.EDISID
	JOIN EquipmentItems ON EquipmentItems.EDISID = EquipmentReadings.EDISID AND EquipmentItems.InputID = EquipmentReadings.InputID
	JOIN EquipmentTypes ON EquipmentTypes.ID = EquipmentReadings.EquipmentTypeID
	AND EquipmentReadings.LogDate BETWEEN @EquipmentFrom AND @LocalTimeNow
) AS EquipmentReadings ON EquipmentReadings.EDISID = Sites.EDISID 
AND EquipmentReadings.InputID = EquipmentItems.InputID
JOIN Locations ON Locations.ID = EquipmentReadings.LocationID
WHERE InUse = 1
AND NOT EXISTS (SELECT ID
	FROM ServiceIssuesEquipment AS sie
	WHERE sie.DateFrom <= LogDate
	AND (sie.DateTo IS NULL OR sie.DateTo >= LogDate)
	AND sie.RealEDISID = EquipmentItems.EDISID
	AND sie.InputID = EquipmentItems.InputID
)
GROUP BY EquipmentItems.EDISID,
		LTRIM(RTRIM(EquipmentItems.[Description])),
		EquipmentItems.EquipmentTypeID,
		EquipmentTypes.EquipmentSubTypeID,
		EquipmentTypes.[Description],
		Locations.[Description],
		CASE WHEN EquipmentItems.LastAlarmingReading >= @AlarmFrom THEN EquipmentItems.LastAlarmingReading ELSE NULL END,
		CASE WHEN EquipmentItems.LastAlarmingReading >= @AlarmFrom THEN EquipmentItems.LastAlarmingValue ELSE NULL END

END

DECLARE @EquipmentAmbientTL INT = 3
DECLARE @EquipmentRecircTL INT = 3
DECLARE @CleaningTL INT = 3
DECLARE @CleaningKegTL INT = 3
DECLARE @CleaningCaskTL INT = 3
DECLARE @ThroughputTL INT = 3
DECLARE @ThroughputKegTL INT = 3
DECLARE @ThroughputCaskTL INT = 3
DECLARE @TemperatureTL INT = 3
DECLARE @TemperatureKegTL INT = 3
DECLARE @TemperatureCaskTL INT = 3
DECLARE @PouringYieldTL INT = 3
DECLARE @PouringYieldKegTL INT = 3
DECLARE @PouringYieldCaskTL INT = 3
DECLARE @TillYieldTL INT = 3
DECLARE @TillYieldKegTL INT = 3
DECLARE @TillYieldCaskTL INT = 3

--DECLARE @EquipmentReadings INT = 0
DECLARE @DispenseReadings INT = 0
DECLARE @DispenseLowVolumeRangeReadings INT = 0
DECLARE @SalesReadings INT = 0

--SELECT @EquipmentReadings = COUNT(*)
--FROM EquipmentReadings
--JOIN #Sites AS Sites ON Sites.EDISID = EquipmentReadings.EDISID
--WHERE TradingDate BETWEEN @From AND DATEADD(SECOND, -1, DATEADD(DAY, 1, @To))

SELECT @SalesReadings = COUNT(*)
FROM Sales
JOIN #Sites AS Sites ON Sites.EDISID = Sales.EDISID
WHERE TradingDate BETWEEN @From AND @To

SELECT	@DispenseLowVolumeRangeReadings = ISNULL(COUNT(*), 3),
		@DispenseReadings = ISNULL(SUM(CASE WHEN TradingDay BETWEEN @From AND @To THEN 1 ELSE 0 END), 3)
FROM DispenseActions
JOIN #Sites AS Sites ON Sites.EDISID = DispenseActions.EDISID
WHERE TradingDay BETWEEN @ThroughputFrom AND @To

IF @IgnoreLocalTime = 0
BEGIN
	SELECT @EquipmentAmbientTL = ISNULL(CASE WHEN SUM(CASE WHEN AlertDate IS NOT NULL THEN 1 ELSE 0 END) > 0 THEN 1
										  WHEN SUM(CASE WHEN HasRedTLReadings = 1 THEN 1 ELSE 0 END) > 0 THEN 1
										  WHEN SUM(CASE WHEN HasAmberTLReadings = 1 THEN 1 ELSE 0 END) > 0 THEN 2
										  ELSE 3 END, 3)
	FROM #WebSiteTLEquipment
	WHERE EDISID IN (SELECT EDISID FROM #Sites)
	AND EquipmentSubTypeID = 2
	
	SELECT @EquipmentRecircTL = ISNULL(CASE WHEN SUM(CASE WHEN AlertDate IS NOT NULL THEN 1 ELSE 0 END) > 0 THEN 1
								 WHEN SUM(CASE WHEN HasRedTLReadings = 1 THEN 1 ELSE 0 END) > 0 THEN 1
								 WHEN SUM(CASE WHEN HasAmberTLReadings = 1 THEN 1 ELSE 0 END) > 0 THEN 2
								 ELSE 3 END, 3)
	FROM #WebSiteTLEquipment
	WHERE EDISID IN (SELECT EDISID FROM #Sites)
	AND EquipmentSubTypeID = 1
	
END
ELSE
BEGIN
	SELECT @EquipmentAmbientTL = EquipmentAmbientTL,
		   @EquipmentRecircTL = EquipmentRecircTL
	FROM SiteRankingCurrent
	WHERE EDISID IN (SELECT EDISID FROM #Sites)
END

SELECT @CleaningTL = CASE WHEN (SUM(DirtyDispense) / CASE WHEN SUM(Volume) = 0 THEN 1 ELSE SUM(Volume) END) * 100 >= @CleaningRedPercentTarget THEN 1
						  WHEN (SUM(DirtyDispense) / CASE WHEN SUM(Volume) = 0 THEN 1 ELSE SUM(Volume) END) * 100 >= @CleaningAmberPercentTarget THEN 2
						  ELSE 3 END,
	   @CleaningKegTL = CASE WHEN (SUM(CASE WHEN IsCask = 0 THEN DirtyDispense ELSE 0 END) / CASE WHEN SUM(CASE WHEN IsCask = 0 THEN Volume ELSE 0 END) = 0 THEN 1 ELSE SUM(CASE WHEN IsCask = 0 THEN Volume ELSE 0 END) END) * 100 >= @CleaningRedPercentTarget THEN 1
						  WHEN (SUM(CASE WHEN IsCask = 0 THEN DirtyDispense ELSE 0 END) / CASE WHEN SUM(CASE WHEN IsCask = 0 THEN Volume ELSE 0 END) = 0 THEN 1 ELSE SUM(CASE WHEN IsCask = 0 THEN Volume ELSE 0 END) END) * 100 >= @CleaningAmberPercentTarget THEN 2
						  ELSE 3 END,
	   @CleaningCaskTL = CASE WHEN (SUM(CASE WHEN IsCask = 1 THEN DirtyDispense ELSE 0 END) / CASE WHEN SUM(CASE WHEN IsCask = 1 THEN Volume ELSE 0 END) = 0 THEN 1 ELSE SUM(CASE WHEN IsCask = 1 THEN Volume ELSE 0 END) END) * 100 >= @CleaningRedPercentTarget THEN 1
						  WHEN (SUM(CASE WHEN IsCask = 1 THEN DirtyDispense ELSE 0 END) / CASE WHEN SUM(CASE WHEN IsCask = 1 THEN Volume ELSE 0 END) = 0 THEN 1 ELSE SUM(CASE WHEN IsCask = 1 THEN Volume ELSE 0 END) END) * 100 >= @CleaningAmberPercentTarget THEN 2
						  ELSE 3 END
FROM #WebSiteTLCleaning
WHERE EDISID IN (SELECT EDISID FROM #Sites)

SELECT	@ThroughputTL = ISNULL(CASE WHEN COUNT(*) >= @ThroughputRedTaps THEN 1 WHEN COUNT(*) >= @ThroughputAmberTaps THEN 2 ELSE 3 END, 3),
		@ThroughputKegTL = ISNULL(CASE WHEN SUM(CASE WHEN IsCask = 0 THEN 1 ELSE 0 END) >= @ThroughputRedTaps THEN 1 WHEN SUM(CASE WHEN IsCask = 0 THEN 1 ELSE 0 END) >= @ThroughputAmberTaps THEN 2 ELSE 3 END, 3),
		@ThroughputCaskTL = ISNULL(CASE WHEN SUM(CASE WHEN IsCask = 1 THEN 1 ELSE 0 END) >= @ThroughputRedTaps THEN 1 WHEN SUM(CASE WHEN IsCask = 1 THEN 1 ELSE 0 END) >= @ThroughputAmberTaps THEN 2 ELSE 3 END, 3)
FROM #WebSiteTLThroughput
WHERE EDISID IN (SELECT EDISID FROM #Sites)

SELECT @TemperatureTL = ISNULL(MIN(CASE WHEN (PoorQuantity / TotalQuantity) * 100 >= @TemperatureRedPercentTarget THEN 1
								WHEN (PoorQuantity / TotalQuantity) * 100 >= @TemperatureAmberPercentTarget THEN 2
								ELSE 3 END), 3),
	   @TemperatureKegTL = ISNULL(MIN(CASE WHEN (PoorQuantity / TotalQuantity) * 100 >= @TemperatureRedPercentTarget AND IsCask = 0 THEN 1
								 WHEN (PoorQuantity / TotalQuantity) * 100 >= @TemperatureAmberPercentTarget AND IsCask = 0 THEN 2
							ELSE 3 END), 3),		
	   @TemperatureCaskTL = ISNULL(MIN(CASE WHEN (PoorQuantity / TotalQuantity) * 100 >= @TemperatureRedPercentTarget AND IsCask = 1 THEN 1
								 WHEN (PoorQuantity / TotalQuantity) * 100 >= @TemperatureAmberPercentTarget AND IsCask = 1 THEN 2
							ELSE 3 END), 3)				
FROM #WebSiteTLTemperature
WHERE EDISID IN (SELECT EDISID FROM #Sites)

IF @DrinksParameter = 2
BEGIN
	SET @PouringYieldTL = 6
	SET @PouringYieldCaskTL = 6
	SET @PouringYieldKegTL = 6
	
END
ELSE
BEGIN
	SELECT @PouringYieldTL = ISNULL(MIN(CASE WHEN [Percent] > (@TargetPouringYieldPercent + @PouringYieldRedPercentFromTarget) OR [Percent] < (@TargetPouringYieldPercent - @PouringYieldRedPercentFromTarget)  THEN 1 
									 WHEN [Percent] >= (@TargetPouringYieldPercent + @PouringYieldAmberPercentFromTarget) OR [Percent] < (@TargetPouringYieldPercent - @PouringYieldAmberPercentFromTarget)  THEN 2 
									 ELSE 3 END), 3),
		   @PouringYieldKegTL = ISNULL(MIN(CASE WHEN ([Percent] > (@TargetPouringYieldPercent + @PouringYieldRedPercentFromTarget) OR [Percent] < (@TargetPouringYieldPercent - @PouringYieldRedPercentFromTarget)) AND IsCask = 0 THEN 1 
									 WHEN ([Percent] >= (@TargetPouringYieldPercent + @PouringYieldAmberPercentFromTarget) OR [Percent] < (@TargetPouringYieldPercent - @PouringYieldAmberPercentFromTarget)) AND IsCask = 0  THEN 2 
									 ELSE 3 END), 3),
		   @PouringYieldCaskTL = ISNULL(MIN(CASE WHEN ([Percent] > (@TargetPouringYieldPercent + @PouringYieldRedPercentFromTarget) OR [Percent] < (@TargetPouringYieldPercent - @PouringYieldRedPercentFromTarget)) AND IsCask = 1  THEN 1 
									 WHEN ([Percent] >= (@TargetPouringYieldPercent + @PouringYieldAmberPercentFromTarget) OR [Percent] < (@TargetPouringYieldPercent - @PouringYieldAmberPercentFromTarget)) AND IsCask = 1 THEN 2 
									 ELSE 3 END), 3)
	FROM #WebSiteTLPouringYield
	WHERE EDISID IN (SELECT EDISID FROM #Sites)

END

SELECT @TillYieldTL = ISNULL(MIN(CASE WHEN [Percent] > (@TargetTillYieldPercent + @TillYieldRedPercentFromTarget) OR [Percent] < (@TargetTillYieldPercent - @TillYieldRedPercentFromTarget)  THEN 1 
								 WHEN [Percent] >= (@TargetTillYieldPercent + @TillYieldAmberPercentFromTarget) OR [Percent] < (@TargetTillYieldPercent - @TillYieldAmberPercentFromTarget)  THEN 2 
								 ELSE 3 END), 3),
	   @TillYieldKegTL = ISNULL(MIN(CASE WHEN ([Percent] > (@TargetTillYieldPercent + @TillYieldRedPercentFromTarget) OR [Percent] < (@TargetTillYieldPercent - @TillYieldRedPercentFromTarget)) AND IsCask = 0 THEN 1 
								 WHEN ([Percent] >= (@TargetTillYieldPercent + @TillYieldAmberPercentFromTarget) OR [Percent] < (@TargetTillYieldPercent - @TillYieldAmberPercentFromTarget)) AND IsCask = 0  THEN 2 
								 ELSE 3 END), 3),
	   @TillYieldCaskTL = ISNULL(MIN(CASE WHEN ([Percent] > (@TargetTillYieldPercent + @TillYieldRedPercentFromTarget) OR [Percent] < (@TargetTillYieldPercent - @TillYieldRedPercentFromTarget)) AND IsCask = 1  THEN 1 
								 WHEN ([Percent] >= (@TargetTillYieldPercent + @TillYieldAmberPercentFromTarget) OR [Percent] < (@TargetTillYieldPercent - @TillYieldAmberPercentFromTarget)) AND IsCask = 1 THEN 2 
								 ELSE 3 END), 3)						  		
FROM #WebSiteTLTillYield
WHERE EDISID IN (SELECT EDISID FROM #Sites)

IF @DispenseReadings = 0 OR @SalesReadings = 0
BEGIN
	SET @TillYieldTL = 6
	SET @TillYieldCaskTL = 6
	SET @TillYieldKegTL = 6
	
END

IF @DispenseReadings = 0
BEGIN
	SET @CleaningTL = 6
	SET @CleaningCaskTL = 6
	SET @CleaningKegTL = 6
	SET @PouringYieldTL = 6
	SET @PouringYieldCaskTL = 6
	SET @PouringYieldKegTL = 6
	SET @TemperatureTL = 6
	SET @TemperatureCaskTL = 6
	SET @TemperatureKegTL = 6

END

IF @DispenseLowVolumeRangeReadings = 0
BEGIN
	SET @ThroughputTL = 6
	SET @ThroughputCaskTL = 6
	SET @ThroughputKegTL = 6
	
END

DELETE
FROM WebSiteTLThroughput
WHERE EDISID IN (SELECT EDISID FROM #Sites)
	
INSERT INTO WebSiteTLThroughput
(EDISID, Pump, Product, Category, AvgVolumePerWeek, TotalCleaningWastage, IsCask)
SELECT EDISID, Pump, Product, Category, AvgVolumePerWeek, TotalCleaningWastage, IsCask
FROM #WebSiteTLThroughput
	
DELETE
FROM WebSiteTLCleaning
WHERE EDISID IN (SELECT EDISID FROM #Sites)

-- Note old-fashioned 3 pint minimum for 'dirty dispense' to flag as issue on site summary	
-- DMG: Changed to 1 pints as per discussion with MF and AW. 
--      This should become a user configurable option in the future. This is only a quick fix.
INSERT INTO WebSiteTLCleaning
(EDISID, Product, Location, Volume, LastClean, IsCask, DaysBeforeAmber, DaysBeforeRed, Pump, Issue)
SELECT EDISID, Product, Location, Volume, LastClean, IsCask, DaysBeforeAmber, DaysBeforeRed, Pump, CASE WHEN DirtyDispense > @PintLimit THEN 1 ELSE 0 END
FROM #WebSiteTLCleaning

DELETE
FROM WebSiteTLPouringYield
WHERE EDISID IN (SELECT EDISID FROM #Sites)
	
INSERT INTO WebSiteTLPouringYield
(EDISID, Product, [Percent], IsCask, IsInErrorThreshold)
SELECT EDISID, Product, [Percent], IsCask, IsInErrorThreshold
FROM #WebSiteTLPouringYield

DELETE
FROM WebSiteTLTillYield
WHERE EDISID IN (SELECT EDISID FROM #Sites)
	
INSERT INTO WebSiteTLTillYield
(EDISID, Product, [Percent], IsCask, Sold, CashValue, RetailDispensed)
SELECT EDISID, Product, [Percent], IsCask, Sold, CashValue, RetailDispensed
FROM #WebSiteTLTillYield

DELETE
FROM WebSiteTLTemperature
WHERE EDISID IN (SELECT EDISID FROM #Sites)
	
INSERT INTO WebSiteTLTemperature
(EDISID, Pump, Product, Specification, Tolerance, Location, AcceptableQuantity, PoorQuantity, IsCask, TotalQuantity) 
SELECT EDISID, Pump, Product, Specification, Tolerance, Location, AcceptableQuantity, PoorQuantity, IsCask, TotalQuantity
FROM #WebSiteTLTemperature

IF @IgnoreLocalTime = 0
BEGIN
	DELETE
	FROM WebSiteTLEquipment
	WHERE EDISID IN (SELECT EDISID FROM #Sites)
		
	INSERT INTO WebSiteTLEquipment
	(EDISID, Name, EquipmentTypeID, EquipmentSubTypeID, [Type], Location, Temperature, HasRedTLReadings, HasAmberTLReadings, AlertNoData, AlertDate, AlertValue)
	SELECT EDISID, Name, EquipmentTypeID, EquipmentSubTypeID, [Type], Location, Temperature, HasRedTLReadings, HasAmberTLReadings, AlertNoData, AlertDate, AlertValue
	FROM #WebSiteTLEquipment
		
END

DECLARE @RankingCount INT

SELECT @RankingCount = COUNT(*)
FROM SiteRankingCurrent
WHERE EDISID IN (SELECT EDISID FROM #Sites)

IF @RankingCount = 0
BEGIN
	INSERT INTO SiteRankingCurrent
	(EDISID, PouringYield, TillYield, Cleaning, Audit, SiteEquipmentAmbientTL, SiteEquipmentRecircTL, SiteCleaningTL, SiteCleaningKegTL, SiteCleaningCaskTL, SiteThroughputTL, SiteThroughputKegTL, SiteThroughputCaskTL, SiteTemperatureTL, SiteTemperatureKegTL, SiteTemperatureCaskTL, SitePouringYieldTL, SitePouringYieldKegTL, SitePouringYieldCaskTL, SiteTillYieldTL, SiteTillYieldKegTL, SiteTillYieldCaskTL, LastUpdated)
	SELECT EDISID, 6, 6, 6, 6, @EquipmentAmbientTL, @EquipmentRecircTL, @CleaningTL, @CleaningKegTL, @CleaningCaskTL, @ThroughputTL, @ThroughputKegTL, @ThroughputCaskTL, @TemperatureTL, @TemperatureKegTL, @TemperatureCaskTL, @PouringYieldTL, @PouringYieldKegTL, @PouringYieldCaskTL, @TillYieldTL, @TillYieldKegTL, @TillYieldCaskTL, GETDATE()
	FROM #Sites

END
ELSE
BEGIN
	UPDATE SiteRankingCurrent
	SET EquipmentAmbientTL = @EquipmentAmbientTL,
		EquipmentRecircTL = @EquipmentRecircTL,
		CleaningTL = @CleaningTL, 
		ThroughputTL = @ThroughputTL, 
		TemperatureTL = @TemperatureTL, 
		PouringYieldTL = @PouringYieldTL, 
		TillYieldTL = @TillYieldTL,
		SiteEquipmentAmbientTL = @EquipmentAmbientTL,
		SiteEquipmentRecircTL = @EquipmentRecircTL,
		SiteCleaningTL = @CleaningTL, 
		SiteCleaningKegTL = @CleaningKegTL,
		SiteCleaningCaskTL = @CleaningCaskTL, 
		SiteThroughputTL = @ThroughputTL, 
		SiteThroughputKegTL = @ThroughputKegTL, 
		SiteThroughputCaskTL = @ThroughputCaskTL, 
		SiteTemperatureTL = @TemperatureTL, 
		SiteTemperatureKegTL = @TemperatureKegTL, 
		SiteTemperatureCaskTL = @TemperatureCaskTL, 
		SitePouringYieldTL = @PouringYieldTL, 
		SitePouringYieldKegTL = @PouringYieldKegTL, 
		SitePouringYieldCaskTL = @PouringYieldCaskTL, 
		SiteTillYieldTL = @TillYieldTL,
		SiteTillYieldKegTL = @TillYieldKegTL, 
		SiteTillYieldCaskTL = @TillYieldCaskTL,
		LastUpdated = GETDATE()
	WHERE EDISID IN (SELECT EDISID FROM #Sites)
	
END

DECLARE @DayRankingHistoryCount INT
	
SELECT	@DayRankingHistoryCount = COUNT(*)
FROM SiteRankingHistory
WHERE EDISID IN (SELECT EDISID FROM #Sites)
AND TradingDay = @To
	
IF @DayRankingHistoryCount = 0
BEGIN
	INSERT INTO SiteRankingHistory
	(EDISID, TradingDay, SiteEquipmentAmbientTL, SiteEquipmentRecircTL, SiteCleaningTL, SiteCleaningKegTL, SiteCleaningCaskTL, SiteThroughputTL, SiteThroughputKegTL, SiteThroughputCaskTL, SiteTemperatureTL, SiteTemperatureKegTL, SiteTemperatureCaskTL, SitePouringYieldTL, SitePouringYieldKegTL, SitePouringYieldCaskTL, SiteTillYieldTL, SiteTillYieldKegTL, SiteTillYieldCaskTL)
	SELECT EDISID, @To, @EquipmentAmbientTL, @EquipmentRecircTL, @CleaningTL, @CleaningKegTL, @CleaningCaskTL, @ThroughputTL, @ThroughputKegTL, @ThroughputCaskTL, @TemperatureTL, @TemperatureKegTL, @TemperatureCaskTL, @PouringYieldTL, @PouringYieldKegTL, @PouringYieldCaskTL, @TillYieldTL, @TillYieldKegTL, @TillYieldCaskTL
	FROM #Sites
		
END
ELSE
BEGIN
	UPDATE SiteRankingHistory
	SET SiteEquipmentAmbientTL = @EquipmentAmbientTL,
		SiteEquipmentRecircTL = @EquipmentRecircTL,
		SiteCleaningTL = @CleaningTL, 
		SiteCleaningKegTL = @CleaningKegTL,
		SiteCleaningCaskTL = @CleaningCaskTL, 
		SiteThroughputTL = @ThroughputTL, 
		SiteThroughputKegTL = @ThroughputKegTL, 
		SiteThroughputCaskTL = @ThroughputCaskTL, 
		SiteTemperatureTL = @TemperatureTL, 
		SiteTemperatureKegTL = @TemperatureKegTL, 
		SiteTemperatureCaskTL = @TemperatureCaskTL, 
		SitePouringYieldTL = @PouringYieldTL, 
		SitePouringYieldKegTL = @PouringYieldKegTL, 
		SitePouringYieldCaskTL = @PouringYieldCaskTL, 
		SiteTillYieldTL = @TillYieldTL,
		SiteTillYieldKegTL = @TillYieldKegTL, 
		SiteTillYieldCaskTL = @TillYieldCaskTL
	WHERE EDISID IN (SELECT EDISID FROM #Sites)
	AND TradingDay = @To
		
END


DROP TABLE #Sites
DROP TABLE #PrimaryProducts
DROP TABLE #SitePumpCounts
DROP TABLE #SitePumpOffsets
DROP TABLE #SitePumpLastCleans
DROP TABLE #AllSitePumps
DROP TABLE #SiteDispenseActions
DROP TABLE #SiteLowVolume
DROP TABLE #SiteYield
DROP TABLE #WebSiteTLThroughput
DROP TABLE #WebSiteTLCleaning
DROP TABLE #WebSiteTLPouringYield
DROP TABLE #WebSiteTLTillYield
DROP TABLE #WebSiteTLTemperature
DROP TABLE #WebSiteTLEquipment

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteTrafficLights] TO PUBLIC
    AS [dbo];

