CREATE PROCEDURE [neo].[GetBDMiDraughtSummaryForSites]
(
	@UserID         INT,
	@TradingDate    DATE,
	@InternalTemperatureAmberValue INT = 2,
    @RelevantSites  [neo].[IDTable] READONLY
)
AS

--DECLARE @UserID         INT = 160
--DECLARE @UserID         INT = 21518
--DECLARE @TradingDate    DATE = '2018-01-11'
--DECLARE @InternalTemperatureAmberValue INT = 2
--DECLARE @RelevantSites  [neo].[IDTable]

/* Wadworth */
--insert into @RelevantSites values(154)
--insert into @RelevantSites values(149)
--insert into @RelevantSites values(190)
--insert into @RelevantSites values(144)
--insert into @RelevantSites values(163)
--insert into @RelevantSites values(160)
--insert into @RelevantSites values(182)
--insert into @RelevantSites values(168)
--insert into @RelevantSites values(194)
--insert into @RelevantSites values(97)

/* Enterprise */
--insert into @RelevantSites values(9531)
--insert into @RelevantSites values(6191)
--insert into @RelevantSites values(9531)
--insert into @RelevantSites values(1075)
--insert into @RelevantSites values(498)
--insert into @RelevantSites values(9137)
--insert into @RelevantSites values(4599)
--insert into @RelevantSites values(13053)
--insert into @RelevantSites values(14980)
--insert into @RelevantSites values(6883)
--insert into @RelevantSites values(3004)
--insert into @RelevantSites values(14944)

-- Note that @RefreshEstateTLs is no longer used

SET NOCOUNT ON
SET DATEFIRST 1

CREATE TABLE #Sites (EDISID INT NOT NULL, SiteOnline DATE NOT NULL, POSYieldCashValue FLOAT, CleaningCashValue FLOAT, PouringYieldCashValue FLOAT) 
CREATE TABLE #PrimaryEDIS (PrimaryEDISID INT NOT NULL, EDISID INT NOT NULL)
CREATE TABLE #PrimaryProducts (PrimaryProductID INT NOT NULL, ProductID INT NOT NULL) 

--DECLARE @From DATETIME
--DECLARE @To DATETIME
--DECLARE @SiteGroupID INT
--DECLARE @SiteOnline DATETIME
--DECLARE @Today DATETIME

--DECLARE @IgnoreLocalTime BIT = 0
--DECLARE @PrimaryEDISID INT

-- User Conditions
DECLARE @UserHasAllSites    BIT -- 0 = Sites assigned to User via UserSites table; 1 = User automatically has access to all non-hidden Sites
DECLARE @WebActive          BIT -- 0 = User cannot log into any website; 1 = User can log as normal
DECLARE @Expired            BIT -- 0 = User can log on as normal; 1 = User has been deactivated due to inactivity
DECLARE @Deleted            BIT -- 0 = User can log on as normal; 1 = User has been deleted and cannot be used for any purpose

CREATE TABLE #SiteData (EDISID INT, ProductID INT, Product VARCHAR(100), QuantityDispensed FLOAT, TemperatureQuantityDispensed FLOAT, PoorQuantityDispensed FLOAT, DrinksDispensed FLOAT, OperationalYield FLOAT, Sold FLOAT, RetailYield FLOAT, IsCask BIT, MinPouringYield FLOAT, MaxPouringYield FLOAT, LowPouringYieldErrThreshold FLOAT, HighPouringYieldErrThreshold FLOAT, POSYieldCashValue FLOAT, CleaningCashValue FLOAT, PouringYieldCashValue FLOAT, BeerInLineCleaning FLOAT)
CREATE TABLE #SiteDispenseActions (EDISID INT, Pump INT, TradingDay DATETIME, LiquidType INT, ProductID INT, Pints FLOAT, EstimatedDrinks FLOAT, Location INT, AverageTemperature FLOAT)
DECLARE @LineCleans TABLE (EDISID INT, Pump INT, ProductID INT, LocationID INT, [Date] DATE)

DECLARE @Sites TABLE (EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
DECLARE @SitePumpCounts TABLE ([Counter] INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE (EDISID INT NOT NULL, PumpOffset INT NOT NULL)
DECLARE @AllSitePumps TABLE(
    EDISID INT NOT NULL, SitePump INT NOT NULL,
	PumpID INT NOT NULL, LocationID INT NOT NULL, ProductID INT NOT NULL,
	ValidFrom DATETIME NOT NULL, ValidTo DATETIME NOT NULL,
    DaysBeforeAmber INT NOT NULL, DaysBeforeRed INT NOT NULL,  
	PreviousClean DATETIME NOT NULL, PreviousPumpClean DATETIME NOT NULL)

-- What special conditions does the user have?
SELECT 
    @UserHasAllSites = UserTypes.AllSitesVisible
FROM dbo.UserTypes
JOIN dbo.Users ON Users.UserType = UserTypes.[ID]
WHERE Users.ID = @UserID

IF YEAR(@TradingDate) <= 1900
BEGIN
	SET @TradingDate = GETDATE()
	--SET @IgnoreLocalTime = 1
END

--SELECT * FROM @UserSites

INSERT INTO #PrimaryEDIS (PrimaryEDISID,EDISID)
SELECT MAX(PrimaryEDISID) AS PrimaryEDISID, SiteGroupSites.EDISID
FROM(
      SELECT SiteGroupID, SiteGroupSites.EDISID AS PrimaryEDISID
      FROM SiteGroupSites 
      WHERE SiteGroupID IN (SELECT ID FROM SiteGroups WHERE TypeID = 1)
      AND IsPrimary = 1
      GROUP BY SiteGroupID, SiteGroupSites.EDISID
) AS PrimarySites
JOIN SiteGroupSites ON SiteGroupSites.SiteGroupID = PrimarySites.SiteGroupID
LEFT JOIN PumpSetup ON PumpSetup.EDISID = SiteGroupSites.EDISID
GROUP BY SiteGroupSites.EDISID;

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


IF @UserHasAllSites = 0
BEGIN
    INSERT INTO #Sites (EDISID, SiteOnline, POSYieldCashValue, CleaningCashValue, PouringYieldCashValue)
    SELECT Sites.EDISID, Sites.SiteOnline, Owners.POSYieldCashValue, Owners.CleaningCashValue, Owners.PouringYieldCashValue
    FROM dbo.Sites
    JOIN Owners ON Owners.ID = Sites.OwnerID
    JOIN dbo.UserSites ON Sites.EDISID = UserSites.EDISID
    JOIN @RelevantSites AS [RelevantSites] ON Sites.EDISID = [RelevantSites].[ID]
    WHERE Sites.[Hidden] = 0
    AND UserSites.UserID = @UserID
END
ELSE
BEGIN
    INSERT INTO #Sites (EDISID, SiteOnline, POSYieldCashValue, CleaningCashValue, PouringYieldCashValue)
    SELECT Sites.EDISID, Sites.SiteOnline, Owners.POSYieldCashValue, Owners.CleaningCashValue, Owners.PouringYieldCashValue
    FROM dbo.Sites
    JOIN Owners ON Owners.ID = Sites.OwnerID
    JOIN @RelevantSites AS [RelevantSites] ON Sites.EDISID = [RelevantSites].[ID]
    WHERE Sites.[Hidden] = 0
END

--SELECT * FROM #Sites

-- Per-Pump (Cleaning)
INSERT INTO @LineCleans(EDISID,Pump,ProductID,LocationID,[Date])
SELECT MasterDates.EDISID,
	PumpSetup.Pump,
	PumpSetup.ProductID,
	PumpSetup.LocationID,
	CONVERT(DATE,MasterDates.[Date])
FROM CleaningStack
JOIN MasterDates ON MasterDates.ID = CleaningStack.CleaningID
JOIN #Sites AS Sites ON Sites.EDISID = MasterDates.EDISID
JOIN Sites AS SiteDetail ON Sites.EDISID = SiteDetail.EDISID
JOIN PumpSetup ON MasterDates.EDISID = PumpSetup.EDISID
	AND CleaningStack.Line = PumpSetup.Pump
	AND MasterDates.[Date] >= PumpSetup.ValidFrom
	AND (MasterDates.[Date] <= PumpSetup.ValidTo OR PumpSetup.ValidTo IS NULL)
    AND Sites.EDISID = PumpSetup.EDISID
--JOIN #PrimaryEDIS AS PrimaryEDIS ON PrimaryEDIS.EDISID = MasterDates.EDISID
LEFT JOIN SiteProductSpecifications AS Specs ON (PumpSetup.ProductID = Specs.ProductID AND PumpSetup.EDISID = Specs.EDISID)
JOIN Products ON Products.[ID] = PumpSetup.ProductID
WHERE MasterDates.Date BETWEEN CAST(DATEADD(DAY, -(ISNULL(Specs.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed)), @TradingDate) AS DATETIME) AND @TradingDate
AND SiteDetail.Quality = 1 -- BQM
GROUP BY
	MasterDates.EDISID,
	PumpSetup.Pump,
	PumpSetup.ProductID,
	PumpSetup.LocationID,
	MasterDates.[Date]

--SELECT * FROM #LineCleans WHERE EDISID = 97 ORDER BY [Pump], [Date]
-- Get BMS cleans (from WaterStack where volume >=4 pints)
-- Note that an iDraught site may previously have been BMS!!!
INSERT INTO @LineCleans(EDISID,Pump,ProductID,LocationID,[Date])
SELECT
    MasterDates.EDISID,
	PumpSetup.Pump,
	PumpSetup.ProductID,
	PumpSetup.LocationID,
	CONVERT(DATE,MasterDates.[Date])
FROM WaterStack
JOIN MasterDates ON MasterDates.ID = WaterStack.WaterID
--JOIN #PrimaryEDIS AS PrimaryEDIS ON PrimaryEDIS.EDISID = MasterDates.EDISID
JOIN #Sites AS Sites ON Sites.EDISID = MasterDates.EDISID
JOIN Sites AS SiteDetail ON Sites.EDISID = SiteDetail.EDISID
JOIN PumpSetup ON MasterDates.EDISID = PumpSetup.EDISID
	AND WaterStack.Line = PumpSetup.Pump
	AND MasterDates.[Date] >= PumpSetup.ValidFrom
	AND (MasterDates.[Date] <= PumpSetup.ValidTo OR PumpSetup.ValidTo IS NULL)
    AND Sites.EDISID = PumpSetup.EDISID
LEFT JOIN SiteProductSpecifications AS Specs ON (PumpSetup.ProductID = Specs.ProductID AND PumpSetup.EDISID = Specs.EDISID)
JOIN Products ON Products.[ID] = PumpSetup.ProductID
LEFT JOIN (
    SELECT EDISID, CalendarDate AS [Date]
    FROM SiteQualityHistory
    JOIN Calendar ON Calendar.CalendarDate BETWEEN QualityStart AND ISNULL(QualityEnd, CAST(GETDATE() AS DATE))
    ) AS iDraughtTime ON iDraughtTime.EDISID = MasterDates.EDISID 
	AND iDraughtTime.[Date] = MasterDates.[Date]
WHERE MasterDates.Date BETWEEN CAST(DATEADD(DAY, -(ISNULL(Specs.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed)), @TradingDate) AS DATETIME) AND @TradingDate
	--AND ( (MasterDates.Date < iDraughtTime.FirstPour) OR (MasterDates.Date > iDraughtTime.LastPour) OR (iDraughtTime.FirstPour IS NULL AND iDraughtTime.LastPour IS NULL) )
	AND (iDraughtTime.[Date] IS NULL OR SiteDetail.Quality = 0) -- BMS
GROUP BY 
	MasterDates.EDISID,
      PumpSetup.Pump,
      PumpSetup.ProductID,
      PumpSetup.LocationID,
      MasterDates.[Date]
HAVING SUM(WaterStack.Volume) >= 4

--SELECT * FROM @LineCleans

-- Per-Product (Yield, Temperature)
INSERT INTO #SiteData (EDISID, ProductID, Product, QuantityDispensed, TemperatureQuantityDispensed, PoorQuantityDispensed, DrinksDispensed, OperationalYield, Sold, RetailYield, IsCask, BeerInLineCleaning)
SELECT 
    COALESCE(Dispense.EDISID, Sales.EDISID) AS EDISID,
    Products.[ID] AS ProductID,
    Products.[Description] AS Product,
    ISNULL(SUM(Dispense.Pints),0) AS QuantityDispensed, -- Yield
    ISNULL(SUM(Dispense.TemperaturePints),0) AS TemperatureQuantityDispensed, -- Temperature
    ISNULL(SUM(Dispense.PoorPints),0) AS PoorQuantityDispensed, -- Temperature
    ISNULL(SUM(Dispense.EstimatedDrinks),0) AS DrinksDispensed,
    ISNULL(SUM(Dispense.EstimatedDrinks),0) - ISNULL(SUM(Dispense.Pints),0) AS OperationalYield,
    ISNULL(SUM(Sales.Sold), 0) AS [Sold],
    ISNULL(SUM(Sales.Sold),0)-ISNULL(SUM(Dispense.EstimatedDrinks),0) AS RetailYield,
    Products.IsCask AS IsCask,
    ISNULL(SUM(Dispense.BeerInLineCleaning),0) AS BeerInLineCleaning
FROM #Sites AS Sites
CROSS APPLY [dbo].[Products]
FULL OUTER JOIN (
    SELECT	
        DispenseActions.EDISID,
        ISNULL(PrimaryProducts.PrimaryProductID, DispenseActions.ProductID) AS ProductID, 
        SUM(CASE WHEN LiquidType = 2 THEN DispenseActions.Pints ELSE 0 END) AS Pints,
        SUM(CASE WHEN LiquidType = 2 AND DispenseActions.Pints >= 0.3 THEN DispenseActions.Pints ELSE 0 END) AS TemperaturePints,
        SUM(CASE WHEN LiquidType = 2 THEN DispenseActions.EstimatedDrinks ELSE 0 END) AS EstimatedDrinks,
        SUM(CASE WHEN LiquidType = 5 THEN DispenseActions.Pints ELSE 0 END) AS BeerInLineCleaning,
        SUM(
            CASE WHEN (AverageTemperature > 
                ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) + 
                ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance) + 
                @InternalTemperatureAmberValue) AND [DispenseActions].Pints >= 0.3 AND [DispenseActions].[LiquidType] = 2 -- Product Only
            THEN DispenseActions.Pints
            ELSE 0
            END) AS PoorPints -- Temperature
    FROM (
        SELECT	FixedSites.PrimaryEDISID AS EDISID,
		        DispenseActions.Pump,
		        TradingDay,
		        LiquidType,
		        Product AS ProductID,
		        Pints,
		        EstimatedDrinks,
		        [Location],
		        AverageTemperature
        FROM DispenseActions
        JOIN (
            SELECT
                ISNULL(PrimarySites.PrimaryEDISID, Sites.EDISID) AS PrimaryEDISID,
                ISNULL(PrimarySites.EDISID, Sites.EDISID) AS ActualEDISID
            FROM #Sites AS Sites 
            LEFT JOIN #PrimaryEDIS AS PrimarySites ON Sites.EDISID = PrimarySites.PrimaryEDISID
        ) AS FixedSites ON DispenseActions.[EDISID] = FixedSites.ActualEDISID
        JOIN Sites ON DispenseActions.[EDISID] = Sites.EDISID
        WHERE 
            TradingDay = @TradingDate
        AND TradingDay >= Sites.SiteOnline
        AND LiquidType IN (2, 3, 5)) AS DispenseActions -- 0.3 for Temperature
    JOIN #Sites AS RelevantSites
        ON RelevantSites.EDISID = DispenseActions.EDISID
    JOIN Products ON DispenseActions.ProductID = Products.ID
    LEFT JOIN SiteProductSpecifications 
        ON Products.ID = SiteProductSpecifications.ProductID AND RelevantSites.EDISID = SiteProductSpecifications.EDISID
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
    ) AS Dispense 
      ON Products.ID = Dispense.ProductID
     AND Sites.EDISID = Dispense.EDISID
FULL OUTER JOIN (
    SELECT
        Sales.EDISID,
        ISNULL(PrimaryProducts.PrimaryProductID, Sales.ProductID) AS ProductID,
        SUM(Sales.Quantity) AS Sold
    FROM Sales
    JOIN #Sites AS RelevantSites
	    ON RelevantSites.EDISID = Sales.EDISID
    FULL OUTER JOIN #PrimaryProducts AS PrimaryProducts
        ON PrimaryProducts.ProductID = Sales.ProductID
    WHERE Sales.TradingDate = @TradingDate
	    AND Sales.TradingDate >= RelevantSites.SiteOnline
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
      ON Products.ID = Sales.ProductID 
     AND Sites.EDISID = Sales.EDISID
WHERE 
    COALESCE(Dispense.EDISID, Sales.EDISID) IS NOT NULL
AND Products.IsWater = 0
AND Products.IsMetric = 0
GROUP BY
    COALESCE(Dispense.EDISID, Sales.EDISID), Products.[ID], Products.[Description], Products.IsCask
HAVING
    (ISNULL(SUM(Dispense.Pints),0) > 0 OR ISNULL(SUM(Sales.Sold), 0) > 0) 
ORDER BY 
    COALESCE(Dispense.EDISID, Sales.EDISID),
    Products.[Description]

--SELECT * FROM #SiteData

SELECT 
    ProductData.EDISID,
    ProductData.[Name],
    ProductData.[PostCode],
    ProductData.POSYieldCashValue,
    ProductData.CleaningCashValue,
    ProductData.PouringYieldCashValue,
    ISNULL(ProductData.RetailYieldPercent,0) AS [RetailYieldPercent],
    ProductData.RetailYield,
    ISNULL(ProductData.PouringYieldPercent,0) AS [PouringYieldPercent],
    ProductData.PouringYield,
    ISNULL(ProductData.TemperaturePercent,0) AS [TemperaturePercent],
    ProductData.Sold,
    ProductData.Drinks,
    SUM(ProductData.Quantity) AS Quantity,
    ISNULL(SUM(CleanData.TotalPints),0) AS TotalPints,
    ISNULL(SUM(CleanData.DirtyQuantity),0) AS DirtyQuantity,
    ISNULL(ROUND((SUM(CleanData.DirtyQuantity) / NULLIF(SUM(CleanData.TotalPints),0)) * 100, 0), 0) AS [UncleanPercent]
FROM (
    SELECT
        SourceData.EDISID,
        Sites.[Name],
        Sites.[PostCode],
        Owners.POSYieldCashValue,
        Owners.CleaningCashValue,
        Owners.PouringYieldCashValue,
        ROUND((dbo.fnConvertSiteDispenseVolume(SourceData.EDISID, SUM(Sold)) / CASE WHEN SUM(Drinks) = 0 THEN 1 ELSE SUM(Drinks) END) * 100, 0) AS [RetailYieldPercent],
        SUM(Sold) - SUM(Drinks) AS [RetailYield],
        ROUND((SUM(Drinks) / NULLIF(dbo.fnConvertSiteDispenseVolume(SourceData.EDISID, SUM(Quantity)),0)) * 100, 0) AS [PouringYieldPercent],
        SUM(Quantity) - SUM(Drinks) AS [PouringYield],
        SUM(Quantity) AS [Quantity],
        ROUND((SUM(PoorQuantity) / NULLIF(SUM(TemperatureQuantity),0)) * 100, 0) AS [TemperaturePercent],
        SUM(Sold) AS Sold,
        SUM(Drinks) AS Drinks
    FROM (
        SELECT 
            COALESCE(PrimarySites.PrimaryEDISID, Sites.EDISID) AS EDISID,
            Product,
            (dbo.fnConvertSiteDispenseVolume(PrimarySites.PrimaryEDISID, SUM(Sold)) / NULLIF(CASE WHEN SUM(DrinksDispensed) = 0 THEN 1 ELSE SUM(DrinksDispensed) END,0)) * 100 AS RetailYield,
            IsCask,
            SUM(Sold) AS Sold,
            SUM(DrinksDispensed) AS Drinks,
            SUM(QuantityDispensed) AS Quantity,
            SUM(TemperatureQuantityDispensed) AS TemperatureQuantity,
            SUM(PoorQuantityDispensed) AS PoorQuantity
        FROM #SiteData AS Sites
        LEFT JOIN #PrimaryEDIS AS PrimarySites ON Sites.EDISID = PrimarySites.EDISID
        WHERE IsCask = 0
        GROUP BY PrimarySites.PrimaryEDISID, Sites.EDISID, Product, IsCask
        UNION ALL
        SELECT 
            COALESCE(PrimarySites.PrimaryEDISID, Sites.EDISID) AS EDISID,
            'Consolidated Casks' AS Product,
            (dbo.fnConvertSiteDispenseVolume(PrimarySites.PrimaryEDISID, SUM(Sold)) / NULLIF(CASE WHEN SUM(DrinksDispensed) = 0 THEN 1 ELSE SUM(DrinksDispensed) END,0)) * 100 AS RetailYield,
            1 AS IsCask,
            SUM(Sold) AS Sold,
            SUM(DrinksDispensed) AS Drinks,
            SUM(QuantityDispensed) AS Quantity,
            SUM(TemperatureQuantityDispensed) AS TemperatureQuantity,
            SUM(PoorQuantityDispensed) AS PoorQuantity
        FROM #SiteData AS Sites
        LEFT JOIN #PrimaryEDIS AS PrimarySites ON Sites.EDISID = PrimarySites.EDISID
        WHERE IsCask = 1
        GROUP BY PrimarySites.PrimaryEDISID, Sites.EDISID
        ) AS SourceData
    JOIN dbo.Sites ON SourceData.EDISID = Sites.EDISID
    JOIN dbo.Owners ON Sites.OwnerID = Owners.ID
    GROUP BY
        SourceData.EDISID,
        Sites.[Name],
        Sites.PostCode,
        Owners.POSYieldCashValue,
        Owners.CleaningCashValue,
        Owners.PouringYieldCashValue
    ) AS ProductData
LEFT JOIN (
    SELECT 
        COALESCE(PrimarySites.PrimaryEDISID, Dispense.EDISID) AS EDISID,
        TradingDay,
        SUM(Pints) AS TotalPints,
        --MAX(CleanDate) AS CleanDate,
        SUM(CASE WHEN DATEDIFF(DAY, CleanDate, TradingDay) < DaysBeforeAmber THEN Pints ELSE 0 END) AS CleanQuantity, 
	    SUM(CASE WHEN DATEDIFF(DAY, CleanDate, TradingDay) BETWEEN DaysBeforeAmber AND DaysBeforeRed - 1 THEN Pints ELSE 0 END) AS InToleranceQuantity,
	    SUM(CASE WHEN DATEDIFF(DAY, CleanDate, TradingDay) >= DaysBeforeRed OR CleanDate IS NULL THEN Pints ELSE 0 END) AS DirtyQuantity
    FROM (
        SELECT	DispenseActions.EDISID,
		        DispenseActions.Pump,
		        TradingDay,
		        Product AS ProductID,
		        SUM(Pints) AS Pints,
		        COALESCE(SiteProductSpecifications.CleanDaysBeforeAmber, SiteSpecifications.CleanDaysBeforeAmber, Products.LineCleanDaysBeforeAmber) AS DaysBeforeAmber,
                COALESCE(SiteProductSpecifications.CleanDaysBeforeRed, SiteSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed) AS DaysBeforeRed,
                MAX(LineCleans.[Date]) AS CleanDate
        FROM DispenseActions
        JOIN #Sites AS Sites ON DispenseActions.EDISID = Sites.EDISID
        JOIN PumpSetup 
            ON Sites.EDISID = PumpSetup.EDISID 
            AND DispenseActions.[Pump] = PumpSetup.Pump 
            AND DispenseActions.[Product] = PumpSetup.[ProductID]
            AND PumpSetup.[ValidFrom] <= @TradingDate
            AND (PumpSetup.[ValidTo] IS NULL OR PumpSetup.[ValidTo] >= @TradingDate)
        JOIN Products ON DispenseActions.Product = Products.ID
        JOIN ProductCategories ON Products.CategoryID = ProductCategories.ID
        --LEFT JOIN #LineCleans AS LineCleans 
        LEFT JOIN (SELECT EDISID, Pump, ProductID, LocationID, MAX([Date]) AS [Date] FROM @LineCleans GROUP BY EDISID, Pump, ProductID, LocationID) AS LineCleans 
            ON DispenseActions.EDISID = LineCleans.EDISID
            AND DispenseActions.TradingDay >= LineCleans.[Date]
            AND DispenseActions.Pump = LineCleans.Pump
            AND DispenseActions.Product = LineCleans.ProductID
            AND DispenseActions.[Location] = LineCleans.LocationID
        LEFT JOIN SiteProductSpecifications
            ON DispenseActions.EDISID = SiteProductSpecifications.EDISID
            AND DispenseActions.Product = SiteProductSpecifications.ProductID
        LEFT JOIN SiteSpecifications
            ON DispenseActions.EDISID = SiteSpecifications.EDISID
        WHERE 
            TradingDay = @TradingDate
        AND TradingDay >= Sites.SiteOnline
        AND LiquidType IN (2, 3, 5)
        AND Pints >= 0
        AND Products.IsMetric = 0
        AND InUse = 1
        GROUP BY
            DispenseActions.EDISID,
		    DispenseActions.Pump,
		    TradingDay,
		    Product,
		    COALESCE(SiteProductSpecifications.CleanDaysBeforeAmber, SiteSpecifications.CleanDaysBeforeAmber, Products.LineCleanDaysBeforeAmber),
            COALESCE(SiteProductSpecifications.CleanDaysBeforeRed, SiteSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed)
        ) AS Dispense
    LEFT JOIN #PrimaryEDIS AS PrimarySites ON Dispense.EDISID = PrimarySites.EDISID
    GROUP BY
        COALESCE(PrimarySites.PrimaryEDISID, Dispense.EDISID),
        TradingDay
    ) AS CleanData ON ProductData.EDISID = CleanData.EDISID
GROUP BY 
    ProductData.EDISID,
    ProductData.[Name],
    ProductData.[PostCode],
    ProductData.POSYieldCashValue,
    ProductData.CleaningCashValue,
    ProductData.PouringYieldCashValue,
    ProductData.RetailYieldPercent,
    ProductData.RetailYield,
    ProductData.PouringYieldPercent,
    ProductData.PouringYield,
    ProductData.TemperaturePercent,
    ProductData.Sold,
    ProductData.Drinks

DROP TABLE #Sites
DROP TABLE #SiteData
--DROP TABLE #LineCleans
DROP TABLE #PrimaryEDIS
DROP TABLE #PrimaryProducts
DROP TABLE #SiteDispenseActions


GO
GRANT EXECUTE
    ON OBJECT::[neo].[GetBDMiDraughtSummaryForSites] TO PUBLIC
    AS [dbo];

