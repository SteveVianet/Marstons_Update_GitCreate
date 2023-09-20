

CREATE PROCEDURE [dbo].[GenerateAndSendSiteScorecardEmail]
(
	@ScorecardID		INT
)
AS

SET NOCOUNT ON

DECLARE @SiteID VARCHAR(50)
DECLARE @SiteName VARCHAR(100)
DECLARE @From DATETIME
DECLARE @To DATETIME
DECLARE @ThroughputFrom DATETIME
DECLARE @ThroughputTo DATETIME
DECLARE @FromString VARCHAR(50)
DECLARE @ToString VARCHAR(50)
DECLARE @UserName VARCHAR(255)
DECLARE @Login VARCHAR(255)
DECLARE @Password VARCHAR(255)
DECLARE @EMail VARCHAR(255)
DECLARE @UnitMultiplier FLOAT
DECLARE @UnitString VARCHAR(50)
DECLARE @TemperatureMultiplier FLOAT
DECLARE @TemperatureUnitString VARCHAR(50)

DECLARE @Subject VARCHAR(1000)
DECLARE @Head VARCHAR(8000)
DECLARE @Body VARCHAR(8000)
DECLARE @FinalBody VARCHAR(8000)
DECLARE	@EDISID INT
DECLARE @UserID INT

SELECT @EDISID = EDISID, @UserID = RecipientUserID
FROM dbo.SiteScorecardEmails
WHERE ID = @ScorecardID

SELECT @SiteID = SiteID, @SiteName = Name
FROM Sites
WHERE EDISID = @EDISID

SELECT @UserName = UserName, @Login = [Login], @Password = [Password], @EMail = EMail
FROM Users
WHERE ID = @UserID

IF @EMail = '' OR @EMail IS NULL
BEGIN
	RETURN
END

DECLARE @MultipleAuditors BIT
DECLARE @AuditorEmail AS VARCHAR(255)
DECLARE @DatabaseID INT

SELECT @DatabaseID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

SELECT @MultipleAuditors = MultipleAuditors
FROM [SQL1\SQL1].ServiceLogger.dbo.EDISDatabases 
WHERE ID = @DatabaseID

IF @MultipleAuditors = 0
BEGIN
	SELECT @AuditorEmail = PropertyValue
	FROM Configuration
	WHERE PropertyName = 'AuditorEMail'
	
END
ELSE
BEGIN
	SELECT @AuditorEmail = CASE WHEN ISNULL(SiteUser, '') <> '' THEN REPLACE(SiteUser, 'MAINGROUP\', '') + '@vianetplc.com' ELSE '' END
	FROM Sites
	WHERE EDISID = @EDISID
	
END

DECLARE @IsUSSite BIT = 0

SELECT @IsUSSite = CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END
FROM SiteProperties
JOIN Properties ON Properties.ID = SiteProperties.PropertyID
WHERE Properties.Name = 'International'
AND UPPER(SiteProperties.Value) = 'EN-US'

SET @To = DATEADD(DAY, -1, FLOOR(CAST(GETDATE() AS FLOAT)))
SET @From = DATEADD(DAY, -7, @To)
SET @ThroughputTo = FLOOR(CAST(GETDATE() AS FLOAT))
SET @ThroughputFrom = DATEADD(DAY, 1, DATEADD(WEEK, -4, @ThroughputTo))

IF @IsUSSite = 1
BEGIN
	SET @FromString = DATENAME(dw, @From) + ' ' + CAST(DATEPART(MONTH, @From) AS VARCHAR) + '/' + CAST(DATEPART(DAY, @From) AS VARCHAR) + '/' + CAST(DATEPART(YEAR, @From) AS VARCHAR)
	SET @ToString = DATENAME(dw, @To) + ' ' + CAST(DATEPART(MONTH, @To) AS VARCHAR) + '/' + CAST(DATEPART(DAY, @To) AS VARCHAR) + '/' + CAST(DATEPART(YEAR, @To) AS VARCHAR)
	SET @UnitMultiplier = 1.20095042
	SET @UnitString = 'US Pints'
	SET @TemperatureUnitString = 'Fahrenheit'
	SET @TemperatureMultiplier = 1.8
	
END
ELSE
BEGIN
	SET @FromString = DATENAME(dw, @From) + ' ' + CAST(DATEPART(DAY, @From) AS VARCHAR) + '/' + CAST(DATEPART(MONTH, @From) AS VARCHAR) + '/' + CAST(DATEPART(YEAR, @From) AS VARCHAR)
	SET @ToString = DATENAME(dw, @To) + ' ' + CAST(DATEPART(DAY, @To) AS VARCHAR) + '/' + CAST(DATEPART(MONTH, @To) AS VARCHAR) + '/' + CAST(DATEPART(YEAR, @To) AS VARCHAR)
	SET @TemperatureUnitString = 'Celsius'
	SET @TemperatureMultiplier = 1
	
	SELECT @UnitString = SiteProperties.Value
	FROM SiteProperties
	JOIN Properties ON Properties.ID = SiteProperties.PropertyID
	WHERE SiteProperties.EDISID = @EDISID
	AND Properties.Name = 'Small Unit'
	
	IF @UnitString = '50 Centilitres'
	BEGIN
		SET @UnitMultiplier = 56.8261485 / 50
		
	END
	ELSE
	BEGIN
		SET @UnitMultiplier = 1
		SET @UnitString = 'Pints'
		
	END
	
END
------------------------------------------------------------------------------------------------
------SITE CALCULATIONS------
CREATE TABLE #TradingDispensed (EDISID INT, TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, LiquidType INT NOT NULL, Quantity FLOAT NOT NULL, Pump INT NOT NULL, Drinks FLOAT NOT NULL)
CREATE CLUSTERED INDEX IX_TRADINGDISPENSED_LIQUIDTYPE_PRODUCTID ON #TradingDispensed (LiquidType, ProductID)
CREATE TABLE #LineCleans (EDISID INT, Pump INT, ProductID INT, LocationID INT, [Date] DATETIME, UNIQUE (EDISID, Pump, ProductID, LocationID, [Date]))

DECLARE @BeerInCleans TABLE(PumpID INT NOT NULL, ProductID INT NOT NULL, 
					  [TradingDate] DATETIME NOT NULL, 
					  LiquidType INT NOT NULL, StartTime DATETIME NOT NULL, 
					  Pints FLOAT NOT NULL, Duration FLOAT NOT NULL,
					  LocationID INT NULL, 
					  MinCleaningTime DATETIME NULL, MaxCleaningTime DATETIME NULL)
								  
--Water/Beer-in-clean liquid types
CREATE TABLE #WaterBeerInClean (PumpID INT NOT NULL, ProductID INT NOT NULL, 
				    			[TradingDate] DATETIME NOT NULL, 
								LiquidType INT NOT NULL, StartTime DATETIME NOT NULL, 
								Pints FLOAT NOT NULL, Duration FLOAT NOT NULL,
								LocationID INT NULL)

CREATE TABLE #CleanSumamry   (PumpID INT NOT NULL, 
							  Product VARCHAR(50) NOT NULL, Location VARCHAR(30) NOT NULL, 
							  [TradingDate] DATETIME NOT NULL, Volume FLOAT NOT NULL, 
							  SoakTimeMinsIncDuration FLOAT NOT NULL, 
							  MinCleaningTime DATETIME NOT NULL, MaxCleaningTime DATETIME NOT NULL,
							  Distributor VARCHAR(100) NOT NULL, DistributorShortName VARCHAR(5) NOT NULL)

CREATE TABLE #AllSitePumps (EDISID INT NOT NULL, SitePump INT NOT NULL,
			    	 PumpID INT NOT NULL, LocationID INT NOT NULL, ProductID INT NOT NULL,
			    	 ValidFrom DATETIME NOT NULL, ValidTo DATETIME NOT NULL,
                     DaysBeforeAmber INT NOT NULL, DaysBeforeRed INT NOT NULL)

CREATE TABLE #BeerDispensedByPump(EDISID INT, TradingDate DATETIME NOT NULL, PumpID INT, ProductID INT NOT NULL, ActualQuantity FLOAT NOT NULL, RoundedQuantity FLOAT NOT NULL)

                    
DECLARE @BeerSold TABLE (TradingDate DATETIME NOT NULL, ProductID INT, Quantity FLOAT NOT NULL)
DECLARE @BeerDispensed TABLE (TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, ActualQuantity FLOAT NOT NULL, RoundedQuantity FLOAT NOT NULL)
DECLARE @CleaningWaste TABLE (TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @Cleans TABLE (TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, Pump INT NOT NULL)

DECLARE @Sites TABLE(EDISID INT NOT NULL)
DECLARE @SitePumpCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL PRIMARY KEY, PumpOffset INT NOT NULL)
DECLARE @SiteGroupID INT
DECLARE @PrimaryProducts TABLE(ProductID INT NOT NULL, PrimaryProductID INT NOT NULL)
DECLARE @SiteOnline  DATETIME
DECLARE @NumberOfLinesCleaned INT

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

INSERT INTO @SitePumpCounts (EDISID, MaxPump)
SELECT PumpSetup.EDISID, MAX(Pump)
FROM PumpSetup
JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
WHERE (ValidFrom <= @To)
AND (ISNULL(ValidTo, @To) >= @From)
AND (ISNULL(ValidTo, @To) >= @SiteOnline)
GROUP BY PumpSetup.EDISID

INSERT INTO @SitePumpOffsets (EDISID, PumpOffset)
SELECT MainCounts.EDISID, COALESCE(QuaternaryCounts.MaxPump+TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, SecondaryCounts.MaxPump, 0)
FROM @SitePumpCounts AS MainCounts
LEFT JOIN @SitePumpCounts AS SecondaryCounts ON SecondaryCounts.Counter+1 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS TertiaryCounts ON TertiaryCounts.Counter+2 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS QuaternaryCounts ON QuaternaryCounts.Counter+3 = MainCounts.Counter

INSERT INTO #AllSitePumps (EDISID, SitePump, PumpID, LocationID, ProductID, ValidFrom, ValidTo, DaysBeforeAmber, DaysBeforeRed)
SELECT	PumpSetup.EDISID, PumpSetup.Pump,
	PumpSetup.Pump+PumpOffset, LocationID, PumpSetup.ProductID,
	PumpSetup.ValidFrom,
	ISNULL(PumpSetup.ValidTo, @To),
	COALESCE(SiteProductSpecifications.CleanDaysBeforeAmber, SiteSpecifications.CleanDaysBeforeAmber, Products.LineCleanDaysBeforeAmber),
	COALESCE(SiteProductSpecifications.CleanDaysBeforeRed, SiteSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed)
FROM PumpSetup
JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = PumpSetup.EDISID
JOIN Products ON Products.[ID] = PumpSetup.ProductID
LEFT JOIN SiteProductSpecifications ON SiteProductSpecifications.EDISID = PumpSetup.EDISID
				   AND SiteProductSpecifications.ProductID = PumpSetup.ProductID
LEFT JOIN SiteSpecifications ON Sites.EDISID = SiteSpecifications.EDISID
WHERE (ValidFrom <= @To)
AND (ISNULL(ValidTo, @To) >= @From)
AND (ISNULL(ValidTo, @To) >= @SiteOnline)

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

-- Get dispense for period and bodge about into 'trading hours'
INSERT INTO #TradingDispensed
(EDISID, TradingDate, ProductID, LiquidType, Quantity, Pump, Drinks)
SELECT RelevantSites.EDISID,
		TradingDay,
      ISNULL(PrimaryProducts.PrimaryProductID, DispenseActions.Product) AS ProductID,
      LiquidType,
      Pints,
      Pump + PumpOffset,
      EstimatedDrinks
FROM DispenseActions WITH (NOLOCK)
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = DispenseActions.EDISID
LEFT OUTER JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = DispenseActions.Product
JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = DispenseActions.EDISID
WHERE TradingDay BETWEEN @From AND @To
AND TradingDay >= @SiteOnline
AND DispenseActions.LiquidType IN (2,3,5)

-- All beer dispensed
INSERT INTO @BeerDispensed
(TradingDate, ProductID, ActualQuantity, RoundedQuantity)
SELECT  TradingDate,
      ProductID,
      SUM(Quantity),
      SUM(Drinks)
FROM #TradingDispensed AS TradingDispensed
JOIN Products ON Products.ID = TradingDispensed.ProductID
WHERE LiquidType = 2
GROUP BY TradingDate, ProductID

INSERT INTO #BeerDispensedByPump
(EDISID, TradingDate, PumpID, ProductID, ActualQuantity, RoundedQuantity)
SELECT  EDISID,
		TradingDate,
	  Pump,
      ProductID,
      SUM(Quantity),
      SUM(Drinks)
FROM #TradingDispensed AS TradingDispensed
JOIN Products ON Products.ID = TradingDispensed.ProductID
WHERE LiquidType = 2
GROUP BY EDISID, TradingDate, Pump, ProductID

-- All beer dispensed during line clean
INSERT INTO @CleaningWaste
(TradingDate, ProductID, Quantity)
SELECT  TradingDate,
      ProductID, 
        SUM(Quantity)
FROM #TradingDispensed AS TradingDispensed
WHERE LiquidType = 5
GROUP BY TradingDate, ProductID

-- Get line cleaning instances for each product/pump
INSERT INTO @Cleans
(TradingDate, ProductID, Pump)
SELECT  TradingDate,
      ProductID,
      Pump
FROM #TradingDispensed AS TradingDispensed
WHERE LiquidType = 3
GROUP BY TradingDate, ProductID, Pump

SELECT  @NumberOfLinesCleaned = COUNT(*)
FROM @Cleans

INSERT INTO @BeerSold
(TradingDate, ProductID, Quantity)
SELECT Sales.TradingDate,
      ISNULL(PrimaryProducts.PrimaryProductID, Sales.ProductID) AS ProductID,
      SUM(Sales.Quantity)
FROM Sales
JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = Sales.EDISID
LEFT OUTER JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = Sales.ProductID
WHERE Sales.TradingDate BETWEEN @From AND @To
GROUP BY Sales.TradingDate, ISNULL(PrimaryProducts.PrimaryProductID, Sales.ProductID)

INSERT INTO #LineCleans
SELECT
	 DispenseActions.EDISID
	,DispenseActions.Pump
	,DispenseActions.Product AS ProductID
	,DispenseActions.Location AS LocationID
	,DispenseActions.TradingDay AS [Date]
FROM
	DispenseActions
JOIN PumpSetup 
	ON PumpSetup.EDISID = DispenseActions.EDISID
	AND PumpSetup.Pump = DispenseActions.Pump
	AND PumpSetup.ProductID = DispenseActions.Product
	AND PumpSetup.LocationID = DispenseActions.Location
JOIN @Sites AS Sites ON Sites.EDISID = DispenseActions.EDISID
WHERE DispenseActions.TradingDay >= PumpSetup.ValidFrom
	AND (PumpSetup.ValidTo IS NULL OR DispenseActions.TradingDay <= PumpSetup.ValidTo)
	AND DispenseActions.LiquidType IN (3, 4)
GROUP BY DispenseActions.EDISID, DispenseActions.Pump, DispenseActions.Product, DispenseActions.Location, DispenseActions.TradingDay
ORDER BY EDISID, Pump, ProductID, LocationID, [Date]

DECLARE @LinesInRedWithDispense INT

SELECT @LinesInRedWithDispense = SUM(CASE WHEN DATEADD(DAY, DaysBeforeRed, LastClean) <= @To THEN 1 ELSE 0 END)
FROM
(
	SELECT LineCleans.Pump, LineCleans.ProductID, ISNULL(SiteProductSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed) AS DaysBeforeRed, MAX([Date]) AS LastClean
	FROM #LineCleans AS LineCleans
	JOIN #AllSitePumps AS AllSitePumps ON AllSitePumps.PumpID = LineCleans.Pump AND AllSitePumps.ProductID = LineCleans.ProductID AND AllSitePumps.ValidTo = @To
	JOIN Products ON Products.ID = AllSitePumps.ProductID
	LEFT JOIN SiteProductSpecifications ON (AllSitePumps.ProductID = SiteProductSpecifications.ProductID AND AllSitePumps.EDISID = SiteProductSpecifications.EDISID)
	LEFT JOIN (
		SELECT	EDISID,
				PumpID,
				ProductID,
				TradingDate,
				SUM(ActualQuantity) AS Quantity
		FROM #BeerDispensedByPump
		GROUP BY EDISID, PumpID, TradingDate, ProductID
	) AS DirtyDispense ON (DirtyDispense.EDISID = AllSitePumps.EDISID
							AND DirtyDispense.PumpID = AllSitePumps.PumpID
							AND DirtyDispense.TradingDate BETWEEN @From AND @To
							AND DirtyDispense.ProductID = AllSitePumps.ProductID)
	WHERE Products.IsMetric = 0
	GROUP BY LineCleans.Pump, LineCleans.ProductID, ISNULL(SiteProductSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed)
	HAVING SUM(DirtyDispense.Quantity) > 3
) AS LastCleans

DECLARE @OverdueLines INT

SELECT @OverdueLines = SUM(CASE WHEN DATEADD(DAY, DaysBeforeRed, LastClean) <= @To THEN 1 ELSE 0 END)
FROM
(
	SELECT LineCleans.Pump, LineCleans.ProductID, ISNULL(SiteProductSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed) AS DaysBeforeRed, LastClean
	FROM #AllSitePumps AS AllSitePumps
	JOIN
	(
		SELECT EDISID, Pump, ProductID, LocationID, MAX([Date]) AS LastClean 
		FROM #LineCleans
		GROUP BY EDISID, Pump, ProductID, LocationID
	) AS LineCleans ON AllSitePumps.PumpID = LineCleans.Pump AND AllSitePumps.ProductID = LineCleans.ProductID AND AllSitePumps.ValidTo = @To
	JOIN Products ON Products.ID = AllSitePumps.ProductID
	LEFT JOIN SiteProductSpecifications ON (AllSitePumps.ProductID = SiteProductSpecifications.ProductID AND AllSitePumps.EDISID = SiteProductSpecifications.EDISID)
	WHERE Products.IsMetric = 0
	AND AllSitePumps.ValidTo = @To
) AS LastCleans

INSERT INTO @BeerInCleans
(PumpID, ProductID, [TradingDate], LiquidType, StartTime, Pints, Duration)
SELECT DispenseActions.Pump,
       DispenseActions.Product,
       TradingDay,
       DispenseActions.LiquidType,
       DispenseActions.StartTime,
       DispenseActions.Pints,
       DispenseActions.Duration
FROM DispenseActions
JOIN #AllSitePumps AS AllSitePumps ON DispenseActions.Pump = AllSitePumps.SitePump AND DispenseActions.EDISID = AllSitePumps.EDISID
WHERE TradingDay BETWEEN @From AND @To
AND TradingDay BETWEEN AllSitePumps.ValidFrom AND AllSitePumps.ValidTo
AND TradingDay >= @SiteOnline
AND DispenseActions.LiquidType = 3

INSERT INTO #WaterBeerInClean
(PumpID, ProductID, [TradingDate], LiquidType, StartTime, Pints, Duration)
SELECT DispenseActions.Pump,
       DispenseActions.Product,
       TradingDay,
       DispenseActions.LiquidType,
       DispenseActions.StartTime,
       DispenseActions.Pints,
       DispenseActions.Duration
FROM DispenseActions
JOIN #AllSitePumps AS AllSitePumps ON DispenseActions.Pump = AllSitePumps.SitePump AND DispenseActions.EDISID = AllSitePumps.EDISID
WHERE TradingDay BETWEEN @From AND @To
AND TradingDay BETWEEN AllSitePumps.ValidFrom AND AllSitePumps.ValidTo
AND TradingDay >= @SiteOnline
AND DispenseActions.LiquidType IN (1, 5)

UPDATE @BeerInCleans
SET LocationID = AllSitePumps.LocationID
FROM @BeerInCleans AS DispenseConditions, #AllSitePumps AS AllSitePumps
WHERE AllSitePumps.PumpID = DispenseConditions.PumpID
	AND AllSitePumps.ProductID = DispenseConditions.ProductID

UPDATE #WaterBeerInClean
SET LocationID = AllSitePumps.LocationID
FROM #WaterBeerInClean AS DispenseConditions, #AllSitePumps AS AllSitePumps
WHERE AllSitePumps.PumpID = DispenseConditions.PumpID
	AND AllSitePumps.ProductID = DispenseConditions.ProductID

UPDATE @BeerInCleans
SET MinCleaningTime = x.MinCleaningTime,
	MaxCleaningTime = x.MaxCleaningTime
FROM @BeerInCleans AS Cleans
	INNER JOIN 
	(	SELECT PumpID,
			   ProductID,
			   LocationID,
			   LiquidType,
			   TradingDate,
			   MIN(StartTime) AS MinCleaningTime,
			   MAX(StartTime) AS MaxCleaningTime
		FROM @BeerInCleans
		GROUP BY PumpID, ProductID, LocationID, LiquidType, TradingDate
		HAVING LiquidType = 3
	) AS x
	ON  Cleans.PumpID = x.PumpID
	AND Cleans.ProductID = x.ProductID
	AND Cleans.LocationID = x.LocationID
	AND Cleans.TradingDate = x.TradingDate

INSERT INTO #CleanSumamry
(PumpID, Product, Location, [TradingDate], Volume, SoakTimeMinsIncDuration, MinCleaningTime, MaxCleaningTime, Distributor, DistributorShortName)
SELECT Cleans.PumpID AS Pump, 
	   Products.[Description] AS Product, 
	   Locations.[Description] AS Location, 
	   Cleans.TradingDate AS [Date], 
       SUM(Cleans.Pints) AS Volume,
       (DATEDIFF(ss, MIN(Cleans.StartTime), MAX(Cleans.StartTime))+SUM(Cleans.Duration))/60 AS SoakTimeMinsIncDuration,
       MinCleaningTime,
       MaxCleaningTime,
       ProductDistributors.[Description],
       ProductDistributors.ShortName
FROM @BeerInCleans AS Cleans
JOIN Products ON Products.ID = Cleans.ProductID
JOIN ProductDistributors ON ProductDistributors.ID = Products.DistributorID
JOIN Locations ON Locations.ID = Cleans.LocationID
GROUP BY Cleans.PumpID,
		 Products.[Description],
		 Locations.[Description],
		 Cleans.TradingDate,
		 MinCleaningTime,
		 MaxCleaningTime,
		 ProductDistributors.ShortName,
		 ProductDistributors.[Description]
ORDER BY Cleans.PumpID, 
		 Cleans.[TradingDate]

DECLARE @BeerMeasured FLOAT
DECLARE @BeerDispense FLOAT
DECLARE @Dispensed FLOAT
DECLARE @DrinksDispensed FLOAT
DECLARE @BeerInLineCleaning FLOAT
DECLARE @Sold FLOAT
DECLARE @OverallYield FLOAT
DECLARE @OverallYieldPercent INT
DECLARE @PouringYield FLOAT
DECLARE @PouringYieldPercent INT
DECLARE @TillYield FLOAT
DECLARE @TillYieldPercent INT
DECLARE @Variance FLOAT
DECLARE @VariancePercent INT

SELECT	@BeerMeasured = SUM(ISNULL(BeerDispensed.ActualQuantity, 0) + ISNULL(CleaningWaste.Quantity, 0)) * @UnitMultiplier,
		@Dispensed = SUM(ISNULL(BeerDispensed.ActualQuantity, 0)) * @UnitMultiplier,
		@BeerDispense = SUM(ISNULL(BeerDispensed.ActualQuantity, 0)) * @UnitMultiplier,
		@DrinksDispensed = SUM(ISNULL(BeerDispensed.RoundedQuantity, 0)) * @UnitMultiplier,
		@BeerInLineCleaning = SUM(ISNULL(CleaningWaste.Quantity, 0)) * @UnitMultiplier,
		@Sold = SUM(ISNULL(BeerSold.Quantity, 0)) * @UnitMultiplier
FROM @BeerDispensed AS BeerDispensed
FULL OUTER JOIN @BeerSold AS BeerSold ON (BeerDispensed.[TradingDate] = BeerSold.[TradingDate] AND BeerDispensed.ProductID = BeerSold.ProductID)
FULL OUTER JOIN @CleaningWaste AS CleaningWaste ON ((BeerDispensed.[TradingDate] = CleaningWaste.[TradingDate] AND BeerDispensed.ProductID = CleaningWaste.ProductID)
                                          OR (BeerSold.[TradingDate] = CleaningWaste.[TradingDate] AND BeerSold.ProductID = CleaningWaste.ProductID))
JOIN Products ON Products.[ID] = COALESCE(BeerDispensed.ProductID, BeerSold.ProductID, CleaningWaste.ProductID)
LEFT JOIN ProductCategories ON Products.CategoryID = ProductCategories.ID
LEFT JOIN (SELECT ProductCategories.ID,
			      ISNULL(SiteProductCategorySpecifications.LowPouringYieldErrThreshold, ProductCategories.LowPouringYieldErrThreshold) AS LowPouringYieldErrThreshold, 
			      ISNULL(SiteProductCategorySpecifications.HighPouringYieldErrThreshold, ProductCategories.HighPouringYieldErrThreshold) AS HighPouringYieldErrThreshold,
			      ISNULL(SiteProductCategorySpecifications.MinimumPouringYield, ProductCategories.MinimumPouringYield) AS MinPouringYield,
				  ISNULL(SiteProductCategorySpecifications.MaximumPouringYield, ProductCategories.MaximumPouringYield) AS MaxPouringYield
		   FROM ProductCategories
		   LEFT JOIN SiteProductCategorySpecifications ON ProductCategoryID = ID AND EDISID = @EDISID) 
		   AS Thresholds ON Thresholds.ID = ProductCategories.ID
WHERE Products.IsMetric = 0

DECLARE @PouringYieldOutsideToleranceCount INT
DECLARE @TillYieldOutsidePercentToleranceCount INT
DECLARE @ConsolidatedCasksTillYieldOutsidePercentToleranceCount INT

CREATE TABLE #ProductYields(ProductID INT, Quantity FLOAT, Drinks FLOAT, PouringYield FLOAT, PouringYieldPercent FLOAT, Sold FLOAT, TillYield FLOAT, TillYieldPercent FLOAT, MinPouringYield INT, MaxPouringYield INT, IsCask BIT)

INSERT INTO #ProductYields
SELECT	Products.ID,
		SUM(ISNULL(BeerDispensed.ActualQuantity, 0)) AS Quantity,
		SUM(ISNULL(BeerDispensed.RoundedQuantity, 0)) AS Drinks,
		SUM(ISNULL(BeerDispensed.RoundedQuantity, 0)) - SUM(ISNULL(BeerDispensed.ActualQuantity, 0)) AS PouringYield,
		(SUM(ISNULL(BeerDispensed.RoundedQuantity, 0)) / CASE WHEN SUM(ISNULL(BeerDispensed.ActualQuantity, 0)) = 0 THEN 1 ELSE SUM(ISNULL(BeerDispensed.ActualQuantity, 0)) END) * 100 AS PouringYieldPercent,
		SUM(ISNULL(BeerSold.Quantity, 0)) AS Sold,
		CASE WHEN @IsUSSite = 1 THEN SUM(ISNULL(BeerSold.Quantity, 0)) - SUM(ISNULL(BeerDispensed.ActualQuantity, 0)) ELSE SUM(ISNULL(BeerSold.Quantity, 0)) - SUM(ISNULL(BeerDispensed.RoundedQuantity, 0)) END AS TillYield,
		CASE WHEN @IsUSSite = 1 THEN SUM(ISNULL(BeerSold.Quantity, 0)) / CASE WHEN SUM(ISNULL(BeerDispensed.ActualQuantity, 0)) = 0 THEN 1 ELSE SUM(ISNULL(BeerDispensed.ActualQuantity, 0)) END * 100 ELSE SUM(ISNULL(BeerSold.Quantity, 0)) / CASE WHEN SUM(ISNULL(BeerDispensed.RoundedQuantity, 0)) = 0 THEN 1 ELSE SUM(ISNULL(BeerDispensed.RoundedQuantity, 0)) END * 100 END AS TillYieldPercent,
		Thresholds.MinPouringYield,
		Thresholds.MaxPouringYield,
		Products.IsCask
FROM @BeerDispensed AS BeerDispensed
FULL OUTER JOIN @BeerSold AS BeerSold ON (BeerDispensed.[TradingDate] = BeerSold.[TradingDate] AND BeerDispensed.ProductID = BeerSold.ProductID)
FULL OUTER JOIN @CleaningWaste AS CleaningWaste ON ((BeerDispensed.[TradingDate] = CleaningWaste.[TradingDate] AND BeerDispensed.ProductID = CleaningWaste.ProductID)
										  OR (BeerSold.[TradingDate] = CleaningWaste.[TradingDate] AND BeerSold.ProductID = CleaningWaste.ProductID))
JOIN Products ON Products.[ID] = COALESCE(BeerDispensed.ProductID, BeerSold.ProductID, CleaningWaste.ProductID)
LEFT JOIN ProductCategories ON Products.CategoryID = ProductCategories.ID
LEFT JOIN (SELECT ProductCategories.ID,
				  ISNULL(SiteProductCategorySpecifications.LowPouringYieldErrThreshold, ProductCategories.LowPouringYieldErrThreshold) AS LowPouringYieldErrThreshold, 
				  ISNULL(SiteProductCategorySpecifications.HighPouringYieldErrThreshold, ProductCategories.HighPouringYieldErrThreshold) AS HighPouringYieldErrThreshold,
				  ISNULL(SiteProductCategorySpecifications.MinimumPouringYield, ProductCategories.MinimumPouringYield) AS MinPouringYield,
				  ISNULL(SiteProductCategorySpecifications.MaximumPouringYield, ProductCategories.MaximumPouringYield) AS MaxPouringYield
		   FROM ProductCategories
		   LEFT JOIN SiteProductCategorySpecifications ON ProductCategoryID = ID AND EDISID = @EDISID) 
		   AS Thresholds ON Thresholds.ID = ProductCategories.ID
WHERE Products.IsMetric = 0
GROUP BY Products.ID, Thresholds.MinPouringYield, Thresholds.MaxPouringYield, Products.IsCask
	
-- Individual products
SELECT	@PouringYieldOutsideToleranceCount = SUM(CASE WHEN Drinks <> 0 AND Quantity <> 0 AND (PouringYieldPercent > MaxPouringYield OR PouringYieldPercent < MinPouringYield) THEN 1 ELSE 0 END),
		@TillYieldOutsidePercentToleranceCount = CASE WHEN @IsUSSite = 1 THEN SUM(CASE WHEN (Sold / CASE WHEN ISNULL(Quantity, 0) = 0 THEN 1 ELSE Quantity END) * 100 <= 99 THEN 1 ELSE 0 END) ELSE SUM(CASE WHEN (Sold / CASE WHEN ISNULL(Drinks, 0) = 0 THEN 1 ELSE Drinks END) * 100 <= 98 THEN 1 WHEN (Sold / CASE WHEN ISNULL(Drinks, 0) = 0 THEN 1 ELSE Drinks END) * 100 >= 102 THEN 1 ELSE 0 END) END
FROM #ProductYields

--Consolidated casks
SELECT 	@ConsolidatedCasksTillYieldOutsidePercentToleranceCount = CASE WHEN @IsUSSite = 1 THEN SUM(CASE WHEN (Sold / CASE WHEN ISNULL(Quantity, 0) = 0 THEN 1 ELSE Quantity END) * 100 <= 99 THEN 1 ELSE 0 END) ELSE SUM(CASE WHEN (Sold / CASE WHEN ISNULL(Drinks, 0) = 0 THEN 1 ELSE Drinks END) * 100 <= 98 THEN 1 WHEN (Sold / CASE WHEN ISNULL(Drinks, 0) = 0 THEN 1 ELSE Drinks END) * 100 >= 102 THEN 1 ELSE 0 END) END
FROM
(
	SELECT	SUM(Sold) AS Sold,
			SUM(Drinks) AS Drinks,
			SUM(Quantity) AS Quantity
	FROM #ProductYields
	WHERE IsCask = 1
) AS ConsolidatedCaskTillYield

--Worst performing products
DECLARE @WorstPouringProductName VARCHAR(100) = ''
DECLARE @WorstProductPouringYield FLOAT
DECLARE @WorstProductPouringYieldPercent FLOAT
DECLARE @WorstTillProductName VARCHAR(100) = ''
DECLARE @WorstProductTillYield FLOAT
DECLARE @WorstProductTillYieldPercent FLOAT

IF @IsUSSite = 0
BEGIN
	SELECT TOP 1 @WorstPouringProductName = Products.[Description],
				 @WorstProductPouringYield = PouringYield * @UnitMultiplier,
				 @WorstProductPouringYieldPercent = PouringYieldPercent
	FROM #ProductYields AS ProductYields
	JOIN Products ON Products.ID = ProductYields.ProductID
	WHERE PouringYieldPercent <> 0 AND PouringYieldPercent < 100
	AND ProductYields.IsCask = 0
	ORDER BY PouringYieldPercent ASC

END

SELECT TOP 1 @WorstTillProductName = Products.[Description],
			 @WorstProductTillYield = TillYield * @UnitMultiplier,
			 @WorstProductTillYieldPercent = TillYieldPercent
FROM #ProductYields AS ProductYields
JOIN Products ON Products.ID = ProductYields.ProductID
WHERE TillYieldPercent <> 0 AND Drinks <> 0 AND TillYieldPercent < 100
AND ProductYields.IsCask = 0
ORDER BY TillYieldPercent ASC

DECLARE @TotalCleanQuantity FLOAT
DECLARE @DirtyQuantity FLOAT
DECLARE @BeerServedViaLinesOverdueClean FLOAT
DECLARE @BeerServedViaLinesOverdueCleanPercent INT

SELECT @TotalCleanQuantity = SUM(Volume) * @UnitMultiplier,
	   @DirtyQuantity = SUM(CASE WHEN DATEDIFF(DAY, CleanDate, TradingDay) > DaysBeforeRed OR CleanDate IS NULL THEN Volume ELSE 0 END) * @UnitMultiplier
FROM (
	SELECT ISNULL(Sites.EDISID, DispenseActions.EDISID) AS EDISID,
		   DispenseActions.StartTime,
		   DispenseActions.TradingDay,
		   DispenseActions.Product,
		   DispenseActions.Pump,
		   DispenseActions.Location,
		   COALESCE(SiteProductSpecifications.CleanDaysBeforeAmber, SiteSpecifications.CleanDaysBeforeAmber, Products.LineCleanDaysBeforeAmber) AS DaysBeforeAmber,
		   COALESCE(SiteProductSpecifications.CleanDaysBeforeRed, SiteSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed) AS DaysBeforeRed,
		   DispenseActions.Pints AS Volume,
		   MAX(LineCleans.[Date]) AS CleanDate
	FROM DispenseActions AS DispenseActions
	JOIN Products ON Products.[ID] = DispenseActions.Product
	JOIN @Sites AS Sites ON Sites.EDISID = DispenseActions.EDISID
	LEFT JOIN #LineCleans AS LineCleans ON LineCleans.EDISID = DispenseActions.EDISID
										AND LineCleans.[Date] <= DispenseActions.TradingDay
										AND LineCleans.ProductID = DispenseActions.Product
										AND LineCleans.Pump = DispenseActions.Pump
										AND LineCleans.LocationID = DispenseActions.Location
	LEFT JOIN SiteProductSpecifications ON (DispenseActions.Product = SiteProductSpecifications.ProductID AND DispenseActions.EDISID = SiteProductSpecifications.EDISID)
	LEFT JOIN SiteSpecifications ON Sites.EDISID = SiteSpecifications.EDISID
	WHERE Products.IsMetric = 0
	AND DispenseActions.TradingDay BETWEEN @From AND @To 
	GROUP BY ISNULL(Sites.EDISID, DispenseActions.EDISID),
		   DispenseActions.TradingDay,
		   DispenseActions.StartTime,
		   DispenseActions.Product,
		   DispenseActions.Pump,
		   DispenseActions.Location,
		   COALESCE(SiteProductSpecifications.CleanDaysBeforeAmber, SiteSpecifications.CleanDaysBeforeAmber, Products.LineCleanDaysBeforeAmber),
		   COALESCE(SiteProductSpecifications.CleanDaysBeforeRed, SiteSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed),
		   DispenseActions.Pints

) AS Dispense

DECLARE @TotalBeerServed FLOAT
DECLARE @TotalBeerServedTooWarm FLOAT
DECLARE @TotalBeerServedTooWarmPercent FLOAT

SELECT  @TotalBeerServed = ISNULL(SUM(DispenseSummary.Quantity),0) * @UnitMultiplier,
		@TotalBeerServedTooWarm = ISNULL(SUM(DispenseSummary.QuantityOutOfSpec),0) * @UnitMultiplier
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
	WHERE EDISID IN (SELECT EDISID FROM @Sites) AND
		  TradingDay BETWEEN @From AND @To AND
		  TradingDay >= @SiteOnline
	GROUP BY EDISID,
			 TradingDay,
			 Pump,
			 ProductID,
			 LocationID

) AS DispenseSummary ON (AllSitePumps.EDISID = DispenseSummary.EDISID AND
						 AllSitePumps.PumpID = DispenseSummary.Pump AND
						 AllSitePumps.LocationID = DispenseSummary.LocationID AND
						 AllSitePumps.ProductID = DispenseSummary.ProductID AND
						 DispenseSummary.TradingDay BETWEEN AllSitePumps.ValidFrom AND AllSitePumps.ValidTo)
JOIN Locations ON (Locations.ID = AllSitePumps.LocationID)
JOIN Products ON (Products.ID = AllSitePumps.ProductID)
LEFT JOIN SiteProductSpecifications ON (Products.ID = SiteProductSpecifications.ProductID AND @EDISID = SiteProductSpecifications.EDISID)

DECLARE @AverageCellarTemperature FLOAT
DECLARE @AverageCoolerTemperature FLOAT
DECLARE @CellarAlarmReadings INT
DECLARE @CoolerAlarmReadings INT
DECLARE @CellarAlarmsRaised INT
DECLARE @CoolerAlarmsRaised INT

SELECT	@AverageCellarTemperature = AVG(EquipmentReadings.Value)* @TemperatureMultiplier,
		@CellarAlarmReadings = SUM(CASE WHEN EquipmentReadings.Value > EquipmentItems.HighAlarmThreshold AND (CAST( CONVERT( VARCHAR(8), DATEADD(Second, -DATEPART(Second, DATEADD(Minute, -DATEPART(Minute, EquipmentReadings.LogDate), EquipmentReadings.LogDate)), DATEADD(Minute, -DATEPART(Minute, EquipmentReadings.LogDate), EquipmentReadings.LogDate)), 108) AS TIME(0)) BETWEEN EquipmentItems.AlarmStartTime AND DATEADD(SECOND, -1, EquipmentItems.AlarmEndTime)) THEN 1 ELSE 0 END),
		@CellarAlarmsRaised = SUM(CASE WHEN LastAlarmingReading IS NOT NULL THEN 1 ELSE 0 END)
FROM EquipmentReadings
JOIN EquipmentItems ON (EquipmentItems.EDISID = EquipmentReadings.EDISID AND
						EquipmentItems.InputID = EquipmentReadings.InputID)
JOIN EquipmentTypes ON EquipmentTypes.ID = EquipmentItems.EquipmentTypeID
JOIN @Sites AS Sites ON Sites.EDISID = EquipmentReadings.EDISID
WHERE EquipmentItems.EquipmentTypeID IN (12, 18) 
AND EquipmentTypes.EquipmentSubTypeID = 2
AND TradingDate BETWEEN @From AND DATEADD(second, -1, DATEADD(day, 1, @To))
AND TradingDate >= @SiteOnline

SELECT	@AverageCoolerTemperature = AVG(EquipmentReadings.Value) * @TemperatureMultiplier,
		@CoolerAlarmReadings = SUM(CASE WHEN EquipmentReadings.Value > EquipmentItems.HighAlarmThreshold AND (CAST( CONVERT( VARCHAR(8), DATEADD(Second, -DATEPART(Second, DATEADD(Minute, -DATEPART(Minute, EquipmentReadings.LogDate), EquipmentReadings.LogDate)), DATEADD(Minute, -DATEPART(Minute, EquipmentReadings.LogDate), EquipmentReadings.LogDate)), 108) AS TIME(0)) BETWEEN EquipmentItems.AlarmStartTime AND DATEADD(SECOND, -1, EquipmentItems.AlarmEndTime)) THEN 1 ELSE 0 END),
		@CoolerAlarmsRaised = SUM(CASE WHEN LastAlarmingReading IS NOT NULL THEN 1 ELSE 0 END)
FROM EquipmentReadings
JOIN EquipmentItems ON (EquipmentItems.EDISID = EquipmentReadings.EDISID AND
						EquipmentItems.InputID = EquipmentReadings.InputID)
JOIN EquipmentTypes ON EquipmentTypes.ID = EquipmentItems.EquipmentTypeID
JOIN @Sites AS Sites ON Sites.EDISID = EquipmentReadings.EDISID
WHERE EquipmentTypes.EquipmentSubTypeID = 1
AND TradingDate BETWEEN @From AND DATEADD(second, -1, DATEADD(day, 1, @To))
AND TradingDate >= @SiteOnline

DECLARE @AlarmsRaised INT
DECLARE @LastAlarmDate DATETIME
DECLARE @LastAlarmDateString VARCHAR(50)

SELECT @AlarmsRaised = COUNT(*),
	   @LastAlarmDate =	MAX(LastAlarmingReading)
FROM EquipmentItems
JOIN @Sites AS Sites ON Sites.EDISID = EquipmentItems.EDISID
WHERE LastAlarmingReading BETWEEN @From AND DATEADD(second, -1, DATEADD(day, 1, @To))

IF @LastAlarmDate IS NOT NULL
BEGIN
	IF @IsUSSite = 1
	BEGIN
		SET @LastAlarmDateString = '(Latest: ' + CAST(DATEPART(MONTH, @LastAlarmDate) AS VARCHAR) + '/' + CAST(DATEPART(DAY, @LastAlarmDate) AS VARCHAR) + '/' + CAST(DATEPART(YEAR, @LastAlarmDate) AS VARCHAR) + ' ' + CONVERT(VARCHAR, @LastAlarmDate, 108) + ')'
	END
	ELSE
	BEGIN
		SET @LastAlarmDateString = '(Latest: ' + CAST(DATEPART(DAY, @LastAlarmDate) AS VARCHAR) + '/' + CAST(DATEPART(MONTH, @LastAlarmDate) AS VARCHAR) + '/' + CAST(DATEPART(YEAR, @LastAlarmDate) AS VARCHAR) + ' ' + CONVERT(VARCHAR, @LastAlarmDate, 108) + ')'
	END
END
ELSE
BEGIN
	SET @LastAlarmDateString = ''

END

DECLARE @LowVolumeThreshold FLOAT

SELECT	@LowVolumeThreshold = EDISDBs.LowVolumeThreshold
FROM [EDISSQL1\SQL1].ServiceLogger.dbo.EDISDatabases AS EDISDBs
JOIN Configuration 
  ON Configuration.PropertyName = 'Service Owner ID'
WHERE EDISDBs.Name = DB_NAME()
  AND EDISDBs.ID = Configuration.PropertyValue

DECLARE @LowThroughputLines AS INTEGER

;WITH WeeklyDispense AS (
SELECT	PeriodCacheTradingDispense.EDISID,
		DATEADD(dw, -DATEPART(dw, PeriodCacheTradingDispense.TradingDay) + 1, PeriodCacheTradingDispense.TradingDay) AS TradingDate,
		PeriodCacheTradingDispense.Pump + PumpOffset AS Pump,
		Products.[Description] AS Product,
		ProductCategories.[Description] AS ProductCategory,
		Locations.[Description] AS Location,
		Products.IsMetric,
		SUM(PeriodCacheTradingDispense.Volume) AS WeeklyVolume,
		SUM(PeriodCacheTradingDispense.WastedVolume) AS WeeklyWastedVolume
FROM PeriodCacheTradingDispense
JOIN @Sites AS Sites
  ON Sites.EDISID = PeriodCacheTradingDispense.EDISID
JOIN Products
  ON Products.ID = PeriodCacheTradingDispense.ProductID
JOIN ProductCategories
  ON ProductCategories.ID = Products.CategoryID
JOIN Locations
  ON Locations.ID = PeriodCacheTradingDispense.LocationID
JOIN @SitePumpOffsets AS SitePumpOffsets 
  ON SitePumpOffsets.EDISID = PeriodCacheTradingDispense.EDISID
JOIN PumpSetup 
  ON PumpSetup.EDISID = Sites.EDISID
 AND PumpSetup.Pump = PeriodCacheTradingDispense.Pump
 AND PumpSetup.ValidTo IS NULL AND PumpSetup.InUse = 1
WHERE PeriodCacheTradingDispense.TradingDay BETWEEN @ThroughputFrom AND @ThroughputTo
  AND Products.IncludeInLowVolume = 1
GROUP BY	PeriodCacheTradingDispense.EDISID,
			DATEADD(dw, -DATEPART(dw, PeriodCacheTradingDispense.TradingDay) + 1, PeriodCacheTradingDispense.TradingDay),
			PeriodCacheTradingDispense.Pump + PumpOffset,
			Products.[Description],
			ProductCategories.[Description],
			Locations.[Description],
			Products.IsMetric
)

SELECT @LowThroughputLines = COUNT(*)
FROM
(
	SELECT	WeeklyDispense.Pump,
			AVG(WeeklyDispense.WeeklyVolume) AS AverageWeeklyVolume
	FROM WeeklyDispense
	JOIN @Sites AS Sites
	  ON Sites.EDISID = WeeklyDispense.EDISID
	JOIN Sites AS SiteDetails
	  ON SiteDetails.EDISID = Sites.EDISID
	JOIN (	SELECT UserSites.EDISID,
	 			MAX(CASE WHEN UserType = 2 THEN UserID ELSE 0 END) AS BDMID,
				MAX(CASE WHEN UserType = 1 THEN UserID ELSE 0 END) AS RMID
			FROM UserSites
			JOIN Users ON Users.ID = UserSites.UserID
			JOIN @Sites AS Sites ON UserSites.EDISID = Sites.EDISID
			WHERE UserType IN (1,2) AND UserSites.EDISID = Sites.EDISID
			GROUP BY UserSites.EDISID
		) AS SiteManagers
	  ON SiteManagers.EDISID = WeeklyDispense.EDISID
	JOIN Users AS BDMUser 
	  ON BDMUser.ID = SiteManagers.BDMID
	JOIN Users AS RMUser 
	  ON RMUser.ID = SiteManagers.RMID
	JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.EDISDatabases AS EDISDBs
	  ON EDISDBs.Name = DB_NAME()
	WHERE IsMetric = 0
	GROUP BY	EDISDBs.ID,
				WeeklyDispense.EDISID,
				SiteDetails.SiteID,
				SiteDetails.Name,
				BDMUser.UserName,
				RMUser.UserName,
				WeeklyDispense.Pump,
				WeeklyDispense.Product,
				WeeklyDispense.ProductCategory
	HAVING AVG(WeeklyDispense.WeeklyVolume) < @LowVolumeThreshold
) AS LowVolumeThresholds

DROP TABLE #LineCleans
DROP TABLE #TradingDispensed
DROP TABLE #WaterBeerInClean
DROP TABLE #CleanSumamry
DROP TABLE #AllSitePumps
DROP TABLE #ProductYields
DROP TABLE #BeerDispensedByPump

DECLARE @POSYieldCashValue MONEY
DECLARE @CleaningCashValue MONEY
DECLARE @ShowCashValues BIT

SELECT	@POSYieldCashValue = POSYieldCashValue, 
		@CleaningCashValue = CleaningCashValue,
		@ShowCashValues = CASE WHEN POSYieldCashValue > 0 AND CleaningCashValue > 0 THEN 1 ELSE 0 END
FROM Owners
JOIN Sites ON Sites.OwnerID = Owners.ID
WHERE Sites.EDISID = @EDISID

--Divide by zero errors!
SET @Sold = ISNULL(@Sold, '')
SET @BeerMeasured = ROUND(ISNULL(@BeerMeasured, 0), 2)
SET @DrinksDispensed = ROUND(ISNULL(@DrinksDispensed, 0), 2)
SET @OverallYield = ROUND(ISNULL((@Sold - @BeerMeasured), 0), 2)
SET @OverallYieldPercent = ROUND(ISNULL(((@Sold - @BeerMeasured) / @BeerMeasured + 1) * 100, 0), 0)
SET @PouringYield = ROUND(ISNULL((@DrinksDispensed - @Dispensed), 0), 2)
SET @PouringYieldPercent = ROUND(ISNULL(((@DrinksDispensed - @Dispensed) / @DrinksDispensed + 1) * 100, 0), 0)
SET @TillYield = ROUND(ISNULL((@Sold - @DrinksDispensed), 0), 2)
SET @TillYieldPercent = ROUND(ISNULL(((@Sold - @DrinksDispensed) / @DrinksDispensed + 1) * 100, 0), 0)
SET @BeerServedViaLinesOverdueClean = ROUND(ISNULL(@DirtyQuantity, 0), 2)
SET @BeerServedViaLinesOverdueCleanPercent = ROUND(ISNULL((100 / (@TotalCleanQuantity / CASE WHEN @BeerServedViaLinesOverdueClean = 0 THEN 1 ELSE @BeerServedViaLinesOverdueClean END)), 0), 0)
SET @BeerInLineCleaning = ROUND(@BeerInLineCleaning, 2)
SET @TotalBeerServedTooWarm = ROUND(ISNULL(@TotalBeerServedTooWarm, 0), 2)
SET @TotalBeerServedTooWarmPercent = ROUND(ISNULL((100 / (@TotalBeerServed / CASE WHEN @TotalBeerServedTooWarm = 0 THEN 1 ELSE @TotalBeerServedTooWarm END)), 0), 2)
SET @AverageCellarTemperature = ROUND(ISNULL(CASE WHEN @IsUSSite = 1 THEN @AverageCellarTemperature + 32 ELSE  @AverageCellarTemperature END, 0), 2)
SET @AlarmsRaised = ISNULL(@AlarmsRaised, 0)
SET @LowThroughputLines = ISNULL(@LowThroughputLines, 0)
SET @WorstProductPouringYield = ROUND(ISNULL(@WorstProductPouringYield, 0), 2)
SET @WorstProductTillYield = ROUND(ISNULL(@WorstProductTillYield, 0), 2)
SET @WorstProductPouringYieldPercent = ROUND(ISNULL(@WorstProductPouringYieldPercent, 0), 0)
SET @WorstProductTillYieldPercent = ROUND(ISNULL(@WorstProductTillYieldPercent, 0), 0)
SET @LinesInRedWithDispense = ISNULL(@LinesInRedWithDispense, 0)
SET @OverdueLines = ISNULL(@OverdueLines, 0)

IF @IsUSSite = 1
BEGIN
	SET @Variance = ROUND(ISNULL(@Sold, 0), 2) - ROUND(ISNULL(@BeerDispense, 0), 2)

END
ELSE
BEGIN
	SET @Variance = ROUND(ISNULL(@Sold, 0), 2) - ROUND(ISNULL(@DrinksDispensed, 0), 2)
	
END

SET @VariancePercent = ROUND(@Sold / CASE WHEN @BeerMeasured = 0 THEN 1 ELSE @BeerMeasured END * 100, 0)
SET @POSYieldCashValue = ROUND((@POSYieldCashValue * @Variance), 2)
SET @CleaningCashValue = ROUND((@CleaningCashValue * @BeerInLineCleaning) * -1, 2)

-- Site TLs
DECLARE @SiteThroughputTL BIT = 0
DECLARE @SiteCellarTemperatureTL BIT = 0
DECLARE @SiteCoolerTemperatureTL BIT = 0
DECLARE @SiteCleaningTL BIT = 0
DECLARE @SiteTemperatureTL BIT = 0
DECLARE @SitePouringYieldTL BIT = 0
DECLARE @SiteTillYieldTL BIT = 0

IF @LowThroughputLines > 0
BEGIN
	SET @SiteThroughputTL = 1
END

IF @CellarAlarmReadings > 0 OR @CellarAlarmsRaised > 0
BEGIN
	SET @SiteCellarTemperatureTL = 1
END

IF @CoolerAlarmReadings > 0 OR @CoolerAlarmsRaised > 0
BEGIN
	SET @SiteCoolerTemperatureTL = 1
END

IF @LinesInRedWithDispense > 0
BEGIN
	SET @SiteCleaningTL = 1
END

IF @TotalBeerServedTooWarm > 5
BEGIN
	SET @SiteTemperatureTL = 1
END

IF @PouringYieldOutsideToleranceCount > 0
BEGIN
	SET @SitePouringYieldTL = 1
END

IF @Sold > 0 AND (@TillYieldOutsidePercentToleranceCount > 0 OR @ConsolidatedCasksTillYieldOutsidePercentToleranceCount > 0)
BEGIN
	SET @SiteTillYieldTL = 1
END
------------------------------------------------------------------------------------------------

DECLARE @WebSiteLoginString VARCHAR(512)
DECLARE @LogoURL VARCHAR(100)

IF @IsUSSite = 1
BEGIN
	SET @WebSiteLoginString = '<a href=' + 'http://app.i-draft.com/Secure/Disclaimer.aspx?u=' + @Login + '&pwd=' + REPLACE(master.sys.fn_varbintohexstr(HashBytes('MD5', CONVERT(varchar(4000), @Password + 'DGJRR'))), '0x', '') + '>http://www.iDraft.com</a>'
	SET @LogoURL = '<img src="http://www.idraught.com/Library/Images/Layout/LogoUS.gif"/>'
	
END
ELSE
BEGIN
	SET @WebSiteLoginString = '<a href=' + 'http://app.idraught.com/Secure/Disclaimer.aspx?u=' + @Login + '&pwd=' + REPLACE(master.sys.fn_varbintohexstr(HashBytes('MD5', CONVERT(varchar(4000), @Password + 'DGJRR'))), '0x', '') + '>http://www.iDraught.com</a>'
	SET @LogoURL = '<img src="http://www.idraught.com/Library/Images/Layout/Logo.gif"/>'
	
END

SET @Subject = 'Site Report Card for ' + @SiteID + ', ' + @SiteName

SET @Head = '<html><head>'
		+'<style type="text/css">'
			+ 'html, form, body {padding: 0px; margin: 0px; font-family: Arial, Calibri; font-size: 14px;} '
			+ 'table {table-layout: fixed; width: 750px; border-spacing:0; border-collapse:collapse; border: solid 2px #FFFFFF; border: solid 2px #FFFFFF;}'
			+ 'th {text-align: left; border-bottom: 2px solid;}'
			+ '#TLTable td {width: 100px; text-align:center;}'
			+ '.greyText {color: #828282; border-bottom: 2px solid;}'
			+ '.titleColumn {width: 500px;}'
			+ '.percentColumn {width: 100px;}'
			+ '.unitsColumn {width: 150px}'
			+ '.smallText {font-size: 11px; padding-top: 10px; padding-bottom: 10px;}'
			+ '.smallTextIndented {font-size: 11px; margin-left:25px; padding-top: 10px; padding-bottom: 10px;}'
		+ '</style>'
		+ '</head><body>'

SET @Body =	@LogoURL
			+	'<h2>Site report card</h2>'
			+	'<h3>Status update ' + @FromString + ' to  ' + @ToString + '</h3>'
			+	'<h4>Red traffic lights highlight areas for investigation</h4>'
			+	'<table id="TLTable">'
			+	'<tr>'
			+	'<td>' + CASE WHEN @SiteTillYieldTL = 1 THEN '<img src="http://app.idraught.com/Library/Images/Icons/Small/' + CASE WHEN @IsUSSite = 1 THEN 'TillYieldRedDollar.png' ELSE 'TillYieldRed.png' END + '"/>' ELSE '' END + '</td>'
			+	CASE WHEN @IsUSSite = 1 THEN '' ELSE ('<td>' + CASE WHEN @SitePouringYieldTL = 1 THEN '<img src="http://app.idraught.com/Library/Images/Icons/Small/PouringRed.png"/>' ELSE '' END) + '</td>' END
			+	'<td>' + CASE WHEN @SiteCleaningTL = 1 THEN '<img src="http://app.idraught.com/Library/Images/Icons/Small/LineCleaningRed.png"/>' ELSE '' END + '</td>'
			+	'<td>' + CASE WHEN @SiteTemperatureTL = 1 THEN '<img src="http://app.idraught.com/Library/Images/Icons/Small/TemperatureRed.png"/>' ELSE '' END + '</td>'
			+	CASE WHEN @IsUSSite = 1 THEN '' ELSE ('<td>' + CASE WHEN @SiteCoolerTemperatureTL = 1 THEN '<img src="http://app.idraught.com/Library/Images/Icons/Small/RemoteCoolingRed.png"/>' ELSE '' END) + '</td>' END
			+	'<td>' + CASE WHEN @SiteCellarTemperatureTL = 1 THEN '<img src="http://app.idraught.com/Library/Images/Icons/Small/CellarTempRed.png"/>' ELSE '' END + '</td>'
			+	'<td>' + CASE WHEN @SiteThroughputTL = 1 THEN '<img src="http://app.idraught.com/Library/Images/Icons/Small/ThroughputRed.png"/>' ELSE '' END + '</td>'
			+	'</tr>'			
			+	'<tr class="greyText"><td>Till Yield</td>' + CASE WHEN @IsUSSite = 1 THEN '' ELSE '<td>Pouring Yield</td>' END + '<td>Line Cleaning</td>' + '<td>Temperature</td>' + CASE WHEN @IsUSSite = 1 THEN '' ELSE '<td>Remote Cooling</td>' END + '<td>' + CASE WHEN @IsUSSite = 1 THEN 'Walk in Cooler' ELSE 'Cellar Temperature' END + '</td><td>' + + CASE WHEN @IsUSSite = 1 THEN 'Low Dispense' ELSE 'Throughput' END + '</td></tr>'
			+	'</table>'
			+	'<p>The reports can be accessed via ' + @WebSiteLoginString + '</p>'
			
			
			+ CASE WHEN @IsUSSite = 1 THEN
			+	'<table><tr><th class="titleColumn"></th><th class="percentColumn"></th><th class="unitsColumn">Units (' + ISNULL(@UnitString, '') + ')</th></tr>'
			+	'<tr><td class="titleColumn">Volume beer served</td><td class="percentColumn"></td><td class="unitsColumn">' + CAST(@BeerMeasured AS VARCHAR) + '</td></tr>'
			+	'<tr><td class="titleColumn">POS</td><td class="percentColumn"></td><td class="unitsColumn">' + CAST(@Sold AS VARCHAR) + '</td></tr>'
			+	'<tr><td class="titleColumn">#</td><td class="percentColumn"></td><td class="unitsColumn">' + CAST(@Variance AS VARCHAR) + '</td></tr>'
			+	'<tr><td class="titleColumn">%</td><td class="percentColumn"></td><td class="unitsColumn">' + CAST(@VariancePercent AS VARCHAR) + '</td></tr>'
			+	CASE WHEN @ShowCashValues = 1 THEN '<tr><td class="titleColumn">$</td><td class="percentColumn"></td><td class="unitsColumn">' + CAST(@POSYieldCashValue AS VARCHAR) + '</td></tr>' ELSE '' END
			+	CASE WHEN ISNULL(@WorstTillProductName, '') <> '' THEN '<tr><td class="smallTextIndented">' + '&bull; Investigate: ' + @WorstTillProductName + '</td><td class="smallText">' + CAST(@WorstProductTillYieldPercent AS VARCHAR) + '%' + '</td><td class="smallText">' + CAST(@WorstProductTillYield AS VARCHAR) + '</td></tr>' ELSE '' END
			+	'</table>'
			+	'<br />' ELSE '' END
			
			+ CASE WHEN @IsUSSite = 0 THEN
			+	'<table><tr><th class="titleColumn"></th><th class="percentColumn">%</th><th class="unitsColumn">Units (' + ISNULL(@UnitString, '') + ')</th></tr>'
			+	'<tr><td class="titleColumn">Overall Yield</td><td class="percentColumn">' + CAST(@OverallYieldPercent AS VARCHAR) + '%' + '</td><td class="unitsColumn">' + CAST(@OverallYield AS VARCHAR) + '</td></tr>'
			+	'<tr><td class="titleColumn">Pouring Yield</td><td class="percentColumn">' + CAST(@PouringYieldPercent AS VARCHAR) + '%' + '</td><td class="unitsColumn">' + CAST(@PouringYield AS VARCHAR) + '</td></tr>'
			+	CASE WHEN ISNULL(@WorstPouringProductName, '') = '' THEN '' ELSE '<tr><td class="smallTextIndented">' + '&bull; Investigate: ' + @WorstPouringProductName + '</td><td class="smallText">' + CAST(@WorstProductPouringYieldPercent AS VARCHAR) + '%' + '</td><td class="smallText">' + CAST(@WorstProductPouringYield AS VARCHAR) + '</td></tr>' END
			+	'<tr><td class="titleColumn">' + 'Till Yield</td><td class="percentColumn">' + CAST(@TillYieldPercent AS VARCHAR) + '%' + '</td><td class="unitsColumn">' + CAST(@TillYield AS VARCHAR) + '</td></tr>'
			+	CASE WHEN ISNULL(@WorstTillProductName, '') = '' THEN '' ELSE '<tr><td class="smallTextIndented">' + '&bull; Investigate: ' + @WorstTillProductName + '</td><td class="smallText">' + CAST(@WorstProductTillYieldPercent AS VARCHAR) + '%' + '</td><td class="smallText">' + CAST(@WorstProductTillYield AS VARCHAR) + '</td></tr>' END
			+	'</table>'
			+	'<br />' ELSE '' END
			
			+	'<table><tr><th class="titleColumn"></th><th class="percentColumn">%</th><th class="unitsColumn">Units (' + ISNULL(@UnitString, '') + ')</th></tr>'
			+	'<tr><td class="titleColumn">Beer served via lines overdue a clean</td><td class="percentColumn">' + CAST(@BeerServedViaLinesOverdueCleanPercent AS VARCHAR) + '%' + '</td><td class="unitsColumn">' + CAST(@BeerServedViaLinesOverdueClean AS VARCHAR) + '</td></tr>'
			+	'<tr><td class="titleColumn">Beer used in line cleaning</td><td class="percentColumn"></td><td class="unitsColumn">' + CAST(@BeerInLineCleaning AS VARCHAR) + '</td></tr>'
			+	CASE WHEN @IsUSSite = 1 THEN '<tr><td class="titleColumn">Lines Overdue Clean</td><td class="percentColumn"></td><td class="unitsColumn">' + CAST(@OverdueLines AS VARCHAR) + '</td></tr>' 
			+	CASE WHEN @ShowCashValues = 1 THEN '<tr><td class="titleColumn">$</td><td class="percentColumn"></td><td class="unitsColumn">' + CAST(@CleaningCashValue AS VARCHAR) + '</td></tr>' ELSE '' END
			ELSE '' END
			+	'</table>'
			+	'<br />'
			
			+	'<table><tr><th class="titleColumn"></th><th class="percentColumn">%</th><th class="unitsColumn">Units (' + ISNULL(@UnitString, '') + ')</th></tr>'
			+	'<tr><td class="titleColumn">Total beer served too warm</td><td class="percentColumn">' + CAST(@TotalBeerServedTooWarmPercent AS VARCHAR) + '%' + '</td><td class="unitsColumn">' + CAST(@TotalBeerServedTooWarm AS VARCHAR) + '</td></tr>'
			+	'</table>'
			+	'<br />'
			+	'<table><tr><th class="titleColumn"></th><th class="percentColumn"></th><th class="unitsColumn">Units (' + ISNULL(@TemperatureUnitString, '') + ')</th></tr>'
			+	'<tr><td class="titleColumn">Average ' + CASE WHEN @IsUSSite = 1 THEN 'Cooler room' ELSE 'cellar' END + ' temperature</td><td class="percentColumn"></td><td class="unitsColumn">' + CAST(@AverageCellarTemperature AS VARCHAR) + '</td></tr>'
			+	'<tr><td class="titleColumn">Number of ' + CASE WHEN @IsUSSite = 1 THEN 'Cooler room' ELSE 'cooler/device' END + ' alarms raised</td><td class="percentColumn"></td><td class="unitsColumn">' + CAST(@AlarmsRaised AS VARCHAR) + CAST(@LastAlarmDateString AS VARCHAR) + '</td></tr>'
			+	'</table>'
			+	'<br />'
			+	CASE WHEN @IsUSSite = 1 THEN '' ELSE '<table><tr><th class="titleColumn"></th><th class="percentColumn"></th><th class="unitsColumn">Units (' + ISNULL(@UnitString, '') + ')</th></tr>'
			+	'<tr><td class="titleColumn">Volume beer served</td><td class="percentColumn"></td><td class="unitsColumn">' + CAST(@BeerMeasured AS VARCHAR) + '</td></tr>'
			+	'<tr><td class="titleColumn">Drink served</td><td class="percentColumn"></td><td class="unitsColumn">' + CAST(@DrinksDispensed AS VARCHAR) + '</td></tr>'
			+	'</table>'
			+	'<br />' END
			+	'<table><tr><th class="titleColumn"></th><th class="percentColumn"></th><th class="unitsColumn"></th></tr>'
			+	'<tr><td class="titleColumn">' + CASE WHEN @IsUSSite = 1 THEN 'Low dispense' ELSE 'Low throughput' END + ' lines (based on last 4 weeks)</td><td class="percentColumn"></td><td class="unitsColumn">' + CAST(@LowThroughputLines AS VARCHAR) + '</td></tr>'
			+	'</table>'
			+	'</body></html>'
			
DECLARE @OverrideToEmail VARCHAR(512)
DECLARE @CCList VARCHAR(512)

SELECT @OverrideToEmail = CAST(PropertyValue AS VARCHAR(512))
FROM Configuration
WHERE PropertyName = 'Scorecard Email To Override'

SELECT @CCList = CAST(PropertyValue AS VARCHAR(512))
FROM Configuration
WHERE PropertyName = 'Scorecard Email CC Recipients'

IF LEN(@CCList) > 0
BEGIN
	SET @CCList = @CCList + ';' + ISNULL(@AuditorEmail, '')
	
END
ELSE
BEGIN
	SET @CCList = ISNULL(@AuditorEmail, '')
	
END

IF LEN(@OverrideToEmail) > 0
BEGIN
	SET @EMail = @OverrideToEmail
END

--SET @CCList = ''

--PRINT @CCList
--PRINT @EMail
--PRINT @WorstTillProductName

SET @FinalBody = @Head + @Body

--PRINT @FinalBody

EXEC dbo.SendEmail '', '', @EMail, @Subject, @FinalBody, @CCList

UPDATE SiteScorecardEmails
SET HTMLString = @FinalBody,
	Processed = 1
WHERE ID = @ScorecardID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GenerateAndSendSiteScorecardEmail] TO PUBLIC
    AS [dbo];

