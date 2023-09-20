CREATE PROCEDURE [dbo].[GetWebSiteYieldByShift]
(
      @EDISID                                   INT,
      @From                                            DATETIME,
      @To                                              DATETIME,
      @IncludeCasks                 BIT,
      @IncludeKegs                  BIT,
      @IncludeMetric                BIT,
         @IncludeMondayDispense          BIT = 1,
         @IncludeTuesdayDispense         BIT = 1,
         @IncludeWednesdayDispense       BIT = 1,
         @IncludeThursdayDispense        BIT = 1,
         @IncludeFridayDispense          BIT = 1,
         @IncludeSaturdayDispense        BIT = 1,
         @IncludeSundayDispense          BIT = 1,
         @ExcludeServiceIssues                  BIT = 0
)

AS

SET NOCOUNT ON
SET DATEFIRST 1

CREATE TABLE #TradingDispensed (EDISID INT NOT NULL, TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, LiquidType INT NOT NULL, Quantity FLOAT NOT NULL, Pump INT NOT NULL, Drinks FLOAT NOT NULL, StartTime DATETIME)
CREATE CLUSTERED INDEX IX_TRADINGDISPENSED_LIQUIDTYPE_PRODUCTID ON #TradingDispensed (LiquidType, ProductID)

CREATE TABLE #SiteDayTradingShifts (ShiftID INT, EDISID INT, [DayOfWeek] INT, ShiftStart DATETIME2, ShiftEnd DATETIME2, Name VARCHAR(100))

DECLARE @BeerSold TABLE (TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, Quantity FLOAT NOT NULL, ShiftName VARCHAR(100), ShiftID INT, ShiftStart DATETIME, ShiftEnd DATETIME)
DECLARE @BeerDispensed TABLE (TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, ActualQuantity FLOAT NOT NULL, RoundedQuantity FLOAT NOT NULL, ShiftName VARCHAR(100), ShiftID INT, ShiftStart DATETIME, ShiftEnd DATETIME)
DECLARE @CleaningWaste TABLE (TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, Quantity FLOAT NOT NULL, ShiftName VARCHAR(100), ShiftID INT, ShiftStart DATETIME, ShiftEnd DATETIME)
DECLARE @Cleans TABLE (TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, Pump INT NOT NULL, ShiftName VARCHAR(100), ShiftID INT, ShiftStart DATETIME, ShiftEnd DATETIME)
DECLARE @NumberOfLinesCleaned TABLE (TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, NumberOfLinesCleaned INT NOT NULL, ShiftName VARCHAR(100), ShiftID INT, ShiftStart DATETIME, ShiftEnd DATETIME)

DECLARE @Sites TABLE(EDISID INT NOT NULL)
DECLARE @SitePumpCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL PRIMARY KEY, PumpOffset INT NOT NULL)
DECLARE @SiteGroupID INT
DECLARE @PrimaryProducts TABLE(ProductID INT NOT NULL, PrimaryProductID INT NOT NULL)
DECLARE @SiteOnline  DATETIME
DECLARE @PrimaryEDISID INT

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

IF @SiteGroupID IS NOT NULL
BEGIN
       SELECT @PrimaryEDISID = EDISID
       FROM SiteGroupSites
       WHERE SiteGroupSites.IsPrimary = 1
       AND SiteGroupID = @SiteGroupID
END
ELSE
BEGIN
       SET @PrimaryEDISID = @EDISID
END

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

INSERT INTO #SiteDayTradingShifts
(ShiftID, EDISID, [DayOfWeek], ShiftStart, ShiftEnd, Name)
SELECT COALESCE(SiteTradingShifts.ID, OwnerTradingShifts.ID) AS ShiftID,
              @PrimaryEDISID,
              COALESCE(SiteTradingShifts.[DayOfWeek], OwnerTradingShifts.[DayOfWeek]) AS [DayOfWeek],
              CAST(CalendarDate AS DATETIME) + CAST(COALESCE(SiteTradingShifts.ShiftStartTime, OwnerTradingShifts.ShiftStartTime) AS DATETIME) AS ShiftStart,
              --DATEADD(MINUTE, COALESCE(SiteTradingShifts.ShiftDurationMinutes, OwnerTradingShifts.ShiftDurationMinutes), CAST(CalendarDate AS DATETIME) + CAST(COALESCE(SiteTradingShifts.ShiftStartTime, OwnerTradingShifts.ShiftStartTime) AS DATETIME)) AS ShiftEnd,
              DATEADD(MILLISECOND, -1, CAST(DATEADD(MINUTE, COALESCE(SiteTradingShifts.ShiftDurationMinutes, OwnerTradingShifts.ShiftDurationMinutes), CAST(CalendarDate AS DATETIME) + CAST(COALESCE(SiteTradingShifts.ShiftStartTime, OwnerTradingShifts.ShiftStartTime) AS DATETIME)) AS datetime2)) AS ShiftEnd,
              ISNULL(COALESCE(SiteTradingShifts.Name, OwnerTradingShifts.Name), 'Shift ' + CAST(CAST(COALESCE(SiteTradingShifts.ShiftStartTime, OwnerTradingShifts.ShiftStartTime) AS TIME(0)) AS VARCHAR)) AS Name
FROM Calendar
CROSS JOIN @Sites AS RawSites
JOIN Sites ON Sites.EDISID = RawSites.EDISID AND Sites.EDISID = @PrimaryEDISID
JOIN Owners ON Owners.ID = Sites.OwnerID
JOIN OwnerTradingShifts ON OwnerTradingShifts.[DayOfWeek] = Calendar.[DayOfWeek] AND OwnerTradingShifts.OwnerID = Owners.ID
LEFT JOIN SiteTradingShifts ON SiteTradingShifts.[DayOfWeek] = Calendar.[DayOfWeek] AND SiteTradingShifts.EDISID = Sites.EDISID
WHERE Calendar.CalendarDate BETWEEN @From AND @To
GROUP BY COALESCE(SiteTradingShifts.ID, OwnerTradingShifts.ID),
              Sites.EDISID,
              COALESCE(SiteTradingShifts.[DayOfWeek], OwnerTradingShifts.[DayOfWeek]),
              CAST(CalendarDate AS DATETIME) + CAST(COALESCE(SiteTradingShifts.ShiftStartTime, OwnerTradingShifts.ShiftStartTime) AS DATETIME),
              --DATEADD(MINUTE, COALESCE(SiteTradingShifts.ShiftDurationMinutes, OwnerTradingShifts.ShiftDurationMinutes), CAST(CalendarDate AS DATETIME) + CAST(COALESCE(SiteTradingShifts.ShiftStartTime, OwnerTradingShifts.ShiftStartTime) AS DATETIME)),
              DATEADD(MILLISECOND, -1, CAST(DATEADD(MINUTE, COALESCE(SiteTradingShifts.ShiftDurationMinutes, OwnerTradingShifts.ShiftDurationMinutes), CAST(CalendarDate AS DATETIME) + CAST(COALESCE(SiteTradingShifts.ShiftStartTime, OwnerTradingShifts.ShiftStartTime) AS DATETIME)) AS datetime2)),
              ISNULL(COALESCE(SiteTradingShifts.Name, OwnerTradingShifts.Name), 'Shift ' + CAST(CAST(COALESCE(SiteTradingShifts.ShiftStartTime, OwnerTradingShifts.ShiftStartTime) AS TIME(0)) AS VARCHAR))

-- Get dispense for period and bodge about into 'trading hours'
INSERT INTO #TradingDispensed
(EDISID, TradingDate, ProductID, LiquidType, Quantity, Pump, Drinks, StartTime)
SELECT DispenseActions.EDISID,
         TradingDay,
      ISNULL(PrimaryProducts.PrimaryProductID, DispenseActions.Product) AS ProductID,
      LiquidType,
      Pints,
      Pump + PumpOffset,
      EstimatedDrinks,
         StartTime
FROM DispenseActions WITH (NOLOCK)
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = DispenseActions.EDISID
LEFT OUTER JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = DispenseActions.Product
JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = DispenseActions.EDISID
WHERE TradingDay BETWEEN @From AND @To
AND NOT EXISTS
(
       SELECT ID
       FROM ServiceIssuesYield AS siy
       WHERE siy.DateFrom <= TradingDay
              AND (siy.DateTo IS NULL OR siy.DateTo >= TradingDay)
              AND siy.RealEDISID = DispenseActions.EDISID
              AND siy.ProductID = DispenseActions.Product
              AND @ExcludeServiceIssues = 1
)
AND TradingDay >= @SiteOnline
AND DispenseActions.LiquidType IN (2,3,5)

-- All beer dispensed
INSERT INTO @BeerDispensed
(TradingDate, ProductID, ActualQuantity, RoundedQuantity, ShiftName, ShiftID, ShiftStart, ShiftEnd)
SELECT  TradingDate,
      ProductID,
      SUM(Quantity),
      SUM(Drinks),
         SiteDayTradingShifts.Name,
         SiteDayTradingShifts.ShiftID,
         SiteDayTradingShifts.ShiftStart,
         SiteDayTradingShifts.ShiftEnd
FROM #TradingDispensed AS TradingDispensed
JOIN Products ON Products.ID = TradingDispensed.ProductID
LEFT JOIN #SiteDayTradingShifts AS SiteDayTradingShifts ON SiteDayTradingShifts.[DayOfWeek] = DATEPART(DW, TradingDispensed.TradingDate)
AND (TradingDispensed.StartTime BETWEEN SiteDayTradingShifts.ShiftStart AND SiteDayTradingShifts.ShiftEnd)
AND SiteDayTradingShifts.EDISID = @PrimaryEDISID
WHERE LiquidType = 2
GROUP BY TradingDate, ProductID, SiteDayTradingShifts.Name, SiteDayTradingShifts.ShiftID, SiteDayTradingShifts.ShiftStart, SiteDayTradingShifts.ShiftEnd

-- All beer dispensed during line clean
INSERT INTO @CleaningWaste
(TradingDate, ProductID, Quantity, ShiftName, ShiftID, ShiftStart, ShiftEnd)
SELECT  TradingDate,
      ProductID, 
      SUM(Quantity),
         SiteDayTradingShifts.Name,
         SiteDayTradingShifts.ShiftID,
         SiteDayTradingShifts.ShiftStart,
         SiteDayTradingShifts.ShiftEnd
FROM #TradingDispensed AS TradingDispensed
LEFT JOIN #SiteDayTradingShifts AS SiteDayTradingShifts ON SiteDayTradingShifts.[DayOfWeek] = DATEPART(DW, TradingDispensed.TradingDate)
AND (TradingDispensed.StartTime BETWEEN SiteDayTradingShifts.ShiftStart AND SiteDayTradingShifts.ShiftEnd)
AND SiteDayTradingShifts.EDISID = @PrimaryEDISID
WHERE LiquidType = 5
AND NOT EXISTS
(
       SELECT ID
       FROM ServiceIssuesYield AS siy
       WHERE siy.DateFrom <= TradingDate
              AND (siy.DateTo IS NULL OR siy.DateTo >= TradingDate)
              AND siy.RealEDISID = TradingDispensed.EDISID
              AND siy.ProductID = TradingDispensed.ProductID
              AND @ExcludeServiceIssues = 1
)
GROUP BY TradingDate, ProductID, SiteDayTradingShifts.Name, SiteDayTradingShifts.ShiftID, SiteDayTradingShifts.ShiftStart, SiteDayTradingShifts.ShiftEnd

-- Get line cleaning instances for each product/pump
INSERT INTO @Cleans
(TradingDate, ProductID, Pump, ShiftName, ShiftID, ShiftStart, ShiftEnd)
SELECT  TradingDate,
      ProductID,
      Pump,
         SiteDayTradingShifts.Name,
         SiteDayTradingShifts.ShiftID,
         SiteDayTradingShifts.ShiftStart,
         SiteDayTradingShifts.ShiftEnd
FROM #TradingDispensed AS TradingDispensed
LEFT JOIN #SiteDayTradingShifts AS SiteDayTradingShifts ON SiteDayTradingShifts.[DayOfWeek] = DATEPART(DW, TradingDispensed.TradingDate)
AND (TradingDispensed.StartTime BETWEEN SiteDayTradingShifts.ShiftStart AND SiteDayTradingShifts.ShiftEnd)
AND SiteDayTradingShifts.EDISID = @PrimaryEDISID
WHERE LiquidType = 3
GROUP BY TradingDate, ProductID, Pump, SiteDayTradingShifts.Name, SiteDayTradingShifts.ShiftID, SiteDayTradingShifts.ShiftStart, SiteDayTradingShifts.ShiftEnd

-- Get line cleaning instances for each product
INSERT INTO @NumberOfLinesCleaned
(TradingDate, ProductID, ShiftName, ShiftID, ShiftStart, ShiftEnd, NumberOfLinesCleaned)
SELECT  TradingDate,
      ProductID,
         ShiftName,
         ShiftID,
         ShiftStart,
         ShiftEnd,
      COUNT(DISTINCT Pump)
FROM @Cleans
GROUP BY TradingDate, ProductID, ShiftName, ShiftID, ShiftStart, ShiftEnd

-- Get sales for period and bodge about into 'trading hours'
INSERT INTO @BeerSold
(TradingDate, ProductID, Quantity, ShiftName, ShiftID, ShiftStart, ShiftEnd)
SELECT Sales.TradingDate,
      ISNULL(PrimaryProducts.PrimaryProductID, Sales.ProductID) AS ProductID,
      SUM(Sales.Quantity),
         SiteDayTradingShifts.Name,
         SiteDayTradingShifts.ShiftID,
         SiteDayTradingShifts.ShiftStart,
         SiteDayTradingShifts.ShiftEnd
FROM Sales
JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = Sales.EDISID
LEFT OUTER JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = Sales.ProductID
LEFT JOIN #SiteDayTradingShifts AS SiteDayTradingShifts ON SiteDayTradingShifts.[DayOfWeek] = DATEPART(DW, Sales.TradingDate)
AND (CAST(Sales.SaleDate AS DATETIME) + CAST(Sales.SaleTime AS TIME) BETWEEN SiteDayTradingShifts.ShiftStart AND SiteDayTradingShifts.ShiftEnd)
AND SiteDayTradingShifts.EDISID = @PrimaryEDISID
WHERE Sales.TradingDate BETWEEN @From AND @To
AND NOT EXISTS
(
       SELECT ID
       FROM ServiceIssuesYield AS siy
       WHERE siy.DateFrom <= Sales.TradingDate
              AND (siy.DateTo IS NULL OR siy.DateTo >= Sales.TradingDate)
              AND siy.RealEDISID = Sales.EDISID
              AND siy.ProductID = Sales.ProductID
              AND @ExcludeServiceIssues = 1
)
GROUP BY Sales.TradingDate, ISNULL(PrimaryProducts.PrimaryProductID, Sales.ProductID), SiteDayTradingShifts.Name, SiteDayTradingShifts.ShiftID, SiteDayTradingShifts.ShiftStart, SiteDayTradingShifts.ShiftEnd

-- Calculate daily yield
SELECT COALESCE(BeerDispensed.[TradingDate], BeerSold.[TradingDate], CleaningWaste.[TradingDate], NumberOfLinesCleaned.[TradingDate]) AS [TradingDate],
      Products.Description AS Product,
      Products.IsCask AS [IsCask],
      CASE WHEN Products.IsCask = 0 AND Products.IsMetric = 0 AND Products.IsWater = 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS [IsKeg],
      Products.IsMetric AS [IsMetric],
      ISNULL(BeerDispensed.ActualQuantity, 0) + ISNULL(CleaningWaste.Quantity, 0) AS [BeerMeasured],
      ISNULL(BeerDispensed.ActualQuantity, 0) AS [BeerDispensed],
      ISNULL(BeerDispensed.RoundedQuantity, 0) AS [DrinksDispensed],
      ISNULL(CleaningWaste.Quantity, 0) AS [BeerInLineCleaning],
      ISNULL(BeerSold.Quantity, 0) AS [Sold],
      ISNULL(BeerDispensed.RoundedQuantity, 0) - ISNULL(BeerDispensed.ActualQuantity, 0) AS [OperationalYield],
      ISNULL(BeerSold.Quantity, 0) - ISNULL(BeerDispensed.RoundedQuantity, 0) AS [RetailYield],
      ISNULL(BeerSold.Quantity, 0) - ISNULL(BeerDispensed.ActualQuantity, 0) - ISNULL(CleaningWaste.Quantity, 0) AS [OverallYield],
      ISNULL(NumberOfLinesCleaned, 0) AS [NumberOfLinesCleaned],
      Thresholds.LowPouringYieldErrThreshold,
      Thresholds.HighPouringYieldErrThreshold,
      SiteOwner.POSYieldCashValue,
      SiteOwner.CleaningCashValue,
      SiteOwner.PouringYieldCashValue,
      DATEPART(DW, COALESCE(BeerDispensed.[TradingDate], BeerSold.[TradingDate], CleaningWaste.[TradingDate], NumberOfLinesCleaned.[TradingDate])) AS [Day],
      Products.ID AS ProductID,
         COALESCE(BeerDispensed.ShiftName, BeerSold.ShiftName, CleaningWaste.ShiftName, NumberOfLinesCleaned.ShiftName, '') AS ShiftName,
         COALESCE(BeerDispensed.ShiftStart, BeerSold.ShiftStart, CleaningWaste.ShiftStart, NumberOfLinesCleaned.ShiftStart, @To) AS ShiftStart,
         COALESCE(BeerDispensed.ShiftEnd, BeerSold.ShiftEnd, CleaningWaste.ShiftEnd, NumberOfLinesCleaned.ShiftEnd, @To) AS ShiftEnd,
         CASE WHEN COALESCE(BeerDispensed.ShiftName, BeerSold.ShiftName, CleaningWaste.ShiftName, NumberOfLinesCleaned.ShiftName) IS NULL THEN 1 ELSE 0 END AS OutOfHours
FROM @BeerDispensed AS BeerDispensed
FULL OUTER JOIN @BeerSold AS BeerSold ON (BeerDispensed.[TradingDate] = BeerSold.[TradingDate] AND BeerDispensed.ProductID = BeerSold.ProductID AND BeerDispensed.ShiftID = BeerSold.ShiftID)
FULL OUTER JOIN @CleaningWaste AS CleaningWaste ON ((BeerDispensed.[TradingDate] = CleaningWaste.[TradingDate] AND BeerDispensed.ProductID = CleaningWaste.ProductID AND BeerDispensed.ShiftID = CleaningWaste.ShiftID)
                                          OR (BeerSold.[TradingDate] = CleaningWaste.[TradingDate] AND BeerSold.ProductID = CleaningWaste.ProductID AND BeerSold.ShiftID = CleaningWaste.ShiftID))
FULL OUTER JOIN @NumberOfLinesCleaned AS NumberOfLinesCleaned ON ((BeerDispensed.[TradingDate] = NumberOfLinesCleaned.[TradingDate] AND BeerDispensed.ProductID = NumberOfLinesCleaned.ProductID AND BeerDispensed.ShiftID = NumberOfLinesCleaned.ShiftID)
                                                OR (BeerSold.[TradingDate] = NumberOfLinesCleaned.[TradingDate] AND BeerSold.ProductID = NumberOfLinesCleaned.ProductID AND BeerSold.ShiftID = NumberOfLinesCleaned.ShiftID)
                                                OR (CleaningWaste.[TradingDate] = NumberOfLinesCleaned.[TradingDate] AND CleaningWaste.ProductID = NumberOfLinesCleaned.ProductID AND CleaningWaste.ShiftID = NumberOfLinesCleaned.ShiftID))
JOIN Products ON Products.[ID] = COALESCE(BeerDispensed.ProductID, BeerSold.ProductID, CleaningWaste.ProductID, NumberOfLinesCleaned.ProductID)

--Includes the error thresholds in the results to save looking them up individually in ASP. Sue me.
LEFT JOIN ProductCategories ON Products.CategoryID = ProductCategories.ID
LEFT JOIN (SELECT ProductCategories.ID,
                 ISNULL(SiteProductCategorySpecifications.LowPouringYieldErrThreshold, ProductCategories.LowPouringYieldErrThreshold) AS LowPouringYieldErrThreshold, 
                 ISNULL(SiteProductCategorySpecifications.HighPouringYieldErrThreshold, ProductCategories.HighPouringYieldErrThreshold) AS HighPouringYieldErrThreshold
                 FROM ProductCategories
                 LEFT JOIN SiteProductCategorySpecifications ON ProductCategoryID = ID AND EDISID = @EDISID) 
                 AS Thresholds ON Thresholds.ID = ProductCategories.ID
JOIN (
       SELECT EDISID, POSYieldCashValue, CleaningCashValue, PouringYieldCashValue
       FROM Sites
       JOIN Owners ON Owners.ID = Sites.OwnerID
       WHERE EDISID = @EDISID
) AS SiteOwner ON SiteOwner.EDISID = @EDISID

WHERE (Products.IsCask = 0 OR @IncludeCasks = 1) AND (Products.IsCask = 1 OR @IncludeKegs = 1) AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
AND (
       (DATEPART(DW, COALESCE(BeerDispensed.[TradingDate], BeerSold.[TradingDate], CleaningWaste.[TradingDate], NumberOfLinesCleaned.[TradingDate])) = 1 AND @IncludeMondayDispense = 1)
       OR (DATEPART(DW, COALESCE(BeerDispensed.[TradingDate], BeerSold.[TradingDate], CleaningWaste.[TradingDate], NumberOfLinesCleaned.[TradingDate])) = 2 AND @IncludeTuesdayDispense = 1)
       OR (DATEPART(DW, COALESCE(BeerDispensed.[TradingDate], BeerSold.[TradingDate], CleaningWaste.[TradingDate], NumberOfLinesCleaned.[TradingDate])) = 3 AND @IncludeWednesdayDispense = 1)
       OR (DATEPART(DW, COALESCE(BeerDispensed.[TradingDate], BeerSold.[TradingDate], CleaningWaste.[TradingDate], NumberOfLinesCleaned.[TradingDate])) = 4 AND @IncludeThursdayDispense = 1)
       OR (DATEPART(DW, COALESCE(BeerDispensed.[TradingDate], BeerSold.[TradingDate], CleaningWaste.[TradingDate], NumberOfLinesCleaned.[TradingDate])) = 5 AND @IncludeFridayDispense = 1)
       OR (DATEPART(DW, COALESCE(BeerDispensed.[TradingDate], BeerSold.[TradingDate], CleaningWaste.[TradingDate], NumberOfLinesCleaned.[TradingDate])) = 6 AND @IncludeSaturdayDispense = 1)
       OR (DATEPART(DW, COALESCE(BeerDispensed.[TradingDate], BeerSold.[TradingDate], CleaningWaste.[TradingDate], NumberOfLinesCleaned.[TradingDate])) = 7 AND @IncludeSundayDispense = 1)
)
ORDER BY COALESCE(BeerDispensed.[TradingDate], BeerSold.[TradingDate], CleaningWaste.[TradingDate], NumberOfLinesCleaned.[TradingDate]),  Products.Description

DROP TABLE #SiteDayTradingShifts
DROP TABLE #TradingDispensed

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteYieldByShift] TO PUBLIC
    AS [dbo];

