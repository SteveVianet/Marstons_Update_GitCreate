CREATE PROCEDURE [dbo].[GetWebSiteDispenseHourly]
(
 @EDISID INT,
 @From DATETIME,
 @To DATETIME,
 @IncludeCasks BIT,
 @IncludeKegs BIT,
 @IncludeMetric BIT,
 @IncludeMondayDispense BIT = 1,
 @IncludeTuesdayDispense BIT = 1,
 @IncludeWednesdayDispense BIT = 1,
 @IncludeThursdayDispense BIT = 1,
 @IncludeFridayDispense BIT = 1,
 @IncludeSaturdayDispense BIT = 1,
 @IncludeSundayDispense BIT = 1,
 @IncludeLiquidUnknown BIT = 0,
 @IncludeLiquidWater BIT = 1,
 @IncludeLiquidBeer BIT = 1,
 @IncludeLiquidCleaner BIT = 1,
 @IncludeLiquidInTransition BIT = 1,
 @IncludeLiquidBeerInClean BIT = 1
)
AS

SET NOCOUNT ON
SET DATEFIRST 1

DECLARE @SiteGroupID INT
DECLARE @SiteOnline DATETIME

CREATE TABLE #Sites (EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
CREATE TABLE #SitePumpCounts (Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
CREATE TABLE #SitePumpOffsets (EDISID INT NOT NULL, PumpOffset INT NOT NULL)

SELECT @SiteOnline = SiteOnline
FROM dbo.Sites
WHERE EDISID = @EDISID

-- Find out which EDISIDs are relevant (plough through SiteGroups)
INSERT INTO #Sites
(EDISID)
SELECT @EDISID AS EDISID

SELECT @SiteGroupID = SiteGroupID
FROM SiteGroupSites
JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
WHERE TypeID = 1 AND EDISID = @EDISID

INSERT INTO #Sites
(EDISID)
SELECT EDISID
FROM SiteGroupSites
WHERE SiteGroupID = @SiteGroupID AND EDISID <> @EDISID

-- Get pumps for secondary sites (note that 1st EDISID IN @Sites is primary site)
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

SELECT DATEADD(HOUR, DATEPART(Hour, StartTime), CAST(CONVERT(DATE, StartTime, 101) AS DATETIME)) AS DateAndTime,
    DATEADD(HOUR, DATEPART(Hour, StartTime), TradingDay) AS TradingDateAndTime,
    DATEPART(WEEKDAY, StartTime) AS [WeekDay],
 DATEPART(Hour, DispenseActions.[StartTime])+1 AS Shift,
 Pump + PumpOffset AS Pump,
 Products.Description AS Product,
 IsCask,
 SUM(CASE WHEN LiquidType = 0 THEN Pints ELSE 0 END) AS QuantityUnknown,
 SUM(CASE WHEN LiquidType = 1 THEN Pints ELSE 0 END) AS QuantityWater,
 SUM(CASE WHEN LiquidType = 2 THEN Pints ELSE 0 END) AS QuantityBeer,
 SUM(CASE WHEN LiquidType = 3 THEN Pints ELSE 0 END) AS QuantityCleaner,
 SUM(CASE WHEN LiquidType = 4 THEN Pints ELSE 0 END) AS QuantityInTransition,
 SUM(CASE WHEN LiquidType = 5 THEN Pints ELSE 0 END) AS QuantityBeerInClean,
 SUM(Pints) AS Quantity,
 SUM(EstimatedDrinks) AS Drinks,
 Locations.[Description] AS Location
FROM DispenseActions
JOIN Locations ON Locations.ID = DispenseActions.Location
JOIN Products ON Products.ID = DispenseActions.Product
JOIN Sites ON Sites.EDISID = DispenseActions.EDISID
JOIN #SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = DispenseActions.EDISID
WHERE TradingDay BETWEEN @From AND @To
AND TradingDay >= @SiteOnline
AND DispenseActions.EDISID IN (SELECT EDISID FROM #Sites)
AND (Products.IsCask = 0 OR @IncludeCasks = 1)
AND (Products.IsCask = 1 OR @IncludeKegs = 1)
AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
AND (
 (LiquidType = 0 AND @IncludeLiquidUnknown = 1)
 OR (LiquidType = 1 AND @IncludeLiquidWater = 1)
 OR (LiquidType = 2 AND @IncludeLiquidBeer = 1)
 OR (LiquidType = 3 AND @IncludeLiquidCleaner = 1)
 OR (LiquidType = 4 AND @IncludeLiquidInTransition = 1)
 OR (LiquidType = 5 AND @IncludeLiquidBeerInClean = 1)
)
AND (
 (DATEPART(DW, TradingDay) = 1 AND @IncludeMondayDispense = 1)
 OR (DATEPART(DW, TradingDay) = 2 AND @IncludeTuesdayDispense = 1)
 OR (DATEPART(DW, TradingDay) = 3 AND @IncludeWednesdayDispense = 1)
 OR (DATEPART(DW, TradingDay) = 4 AND @IncludeThursdayDispense = 1)
 OR (DATEPART(DW, TradingDay) = 5 AND @IncludeFridayDispense = 1)
 OR (DATEPART(DW, TradingDay) = 6 AND @IncludeSaturdayDispense = 1)
 OR (DATEPART(DW, TradingDay) = 7 AND @IncludeSundayDispense = 1)
)
GROUP BY DATEADD(HOUR, DATEPART(Hour, StartTime), CAST(CONVERT(DATE, StartTime, 101) AS DATETIME)),
 DATEADD(HOUR, DATEPART(Hour, StartTime), TradingDay),
 DATEPART(WEEKDAY, StartTime),
 DATEPART(Hour, DispenseActions.[StartTime]) +1,
 Pump + PumpOffset,
 Products.Description,
 IsCask,
 Locations.[Description]

DROP TABLE #Sites
DROP TABLE #SitePumpCounts
DROP TABLE #SitePumpOffsets
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteDispenseHourly] TO PUBLIC
    AS [dbo];

