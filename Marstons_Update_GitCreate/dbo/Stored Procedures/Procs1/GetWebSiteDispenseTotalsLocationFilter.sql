CREATE PROCEDURE [dbo].[GetWebSiteDispenseTotalsLocationFilter]
(
	@EDISID							INT,
	@From							DATETIME,
	@To								DATETIME,
	@IncludeCasks					BIT,
	@IncludeKegs					BIT,
	@IncludeMetric					BIT,
	@IncludeMondayDispense			BIT = 1,
	@IncludeTuesdayDispense			BIT = 1,
	@IncludeWednesdayDispense		BIT = 1,
	@IncludeThursdayDispense		BIT = 1,
	@IncludeFridayDispense			BIT = 1,
	@IncludeSaturdayDispense		BIT = 1,
	@IncludeSundayDispense			BIT = 1,
	@IncludeLiquidUnknown			BIT = 0,
	@IncludeLiquidWater				BIT = 0,
	@IncludeLiquidBeer				BIT = 1,
	@IncludeLiquidCleaner			BIT = 0,
	@IncludeLiquidInTransition		BIT = 0,
	@IncludeLiquidBeerInClean		BIT = 0,
	@LocationFilter					LocationFilter READONLY
)
AS

SET NOCOUNT ON
SET DATEFIRST 1

DECLARE @ShowLatestData BIT
DECLARE @AuditDate DATETIME

DECLARE @SiteGroupID INT
DECLARE @SiteOnline DATETIME
DECLARE @SiteQuality BIT
CREATE TABLE #Sites (EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
CREATE TABLE #SitePumpCounts (Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
CREATE TABLE #SitePumpOffsets (EDISID INT NOT NULL, PumpOffset INT NOT NULL)

SELECT @SiteOnline = SiteOnline, @SiteQuality = Quality
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

IF @SiteQuality = 1
BEGIN
	SELECT	Pump + PumpOffset AS Pump,
			Products.Description AS Product,
			SUM(CASE WHEN DATEPART(DW, TradingDay) = 1 THEN Pints ELSE 0 END) AS QuantityMonday,
			SUM(CASE WHEN DATEPART(DW, TradingDay) = 2 THEN Pints ELSE 0 END) AS QuantityTuesday,
			SUM(CASE WHEN DATEPART(DW, TradingDay) = 3 THEN Pints ELSE 0 END) AS QuantityWednesday,
			SUM(CASE WHEN DATEPART(DW, TradingDay) = 4 THEN Pints ELSE 0 END) AS QuantityThursday,
			SUM(CASE WHEN DATEPART(DW, TradingDay) = 5 THEN Pints ELSE 0 END) AS QuantityFriday,
			SUM(CASE WHEN DATEPART(DW, TradingDay) = 6 THEN Pints ELSE 0 END) AS QuantitySaturday,
			SUM(CASE WHEN DATEPART(DW, TradingDay) = 7 THEN Pints ELSE 0 END) AS QuantitySunday,
			SUM(Pints) AS Quantity
	FROM DispenseActions
	JOIN Products ON Products.ID = DispenseActions.Product
	JOIN Sites ON Sites.EDISID = DispenseActions.EDISID
	JOIN #SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = DispenseActions.EDISID
	JOIN Locations ON Locations.ID = DispenseActions.Location
	WHERE DispenseActions.EDISID IN (SELECT EDISID FROM #Sites)
	AND TradingDay BETWEEN @From AND @To
	AND TradingDay >= @SiteOnline
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
	AND (REPLACE(Locations.[Description], '''', '') IN (SELECT LocationDescription FROM @LocationFilter))
	GROUP BY	Pump + PumpOffset,
				Products.Description
	ORDER BY	Pump + PumpOffset,
				Products.Description
END
ELSE
BEGIN
	SET @ShowLatestData = 0

	SELECT @ShowLatestData = CASE WHEN UPPER(Value) = 'TRUE' THEN 1 ELSE 0 END 
	FROM SiteProperties
	JOIN Properties ON Properties.[ID] = SiteProperties.PropertyID
	WHERE SiteProperties.EDISID = @EDISID AND Properties.[Name] = 'ShowLatestDataOnWeb'

	SELECT @AuditDate = DATEADD(day, 7, CAST(Configuration.PropertyValue AS DATETIME))
	FROM Configuration
	WHERE PropertyName = 'AuditDate'

	-- For DMS, we need to look at the DLData table.  Sorry, this should use trading days!
	-- Note that we ignore the liquid type requirements, and only show beer
	SELECT	Pump + PumpOffset AS Pump,
			Products.Description AS Product,
			SUM(CASE WHEN DATEPART(DW, MasterDates.Date) = 1 THEN Quantity ELSE 0 END) AS QuantityMonday,
			SUM(CASE WHEN DATEPART(DW, MasterDates.Date) = 2 THEN Quantity ELSE 0 END) AS QuantityTuesday,
			SUM(CASE WHEN DATEPART(DW, MasterDates.Date) = 3 THEN Quantity ELSE 0 END) AS QuantityWednesday,
			SUM(CASE WHEN DATEPART(DW, MasterDates.Date) = 4 THEN Quantity ELSE 0 END) AS QuantityThursday,
			SUM(CASE WHEN DATEPART(DW, MasterDates.Date) = 5 THEN Quantity ELSE 0 END) AS QuantityFriday,
			SUM(CASE WHEN DATEPART(DW, MasterDates.Date) = 6 THEN Quantity ELSE 0 END) AS QuantitySaturday,
			SUM(CASE WHEN DATEPART(DW, MasterDates.Date) = 7 THEN Quantity ELSE 0 END) AS QuantitySunday,
			SUM(Quantity) AS Quantity
	FROM DLData
	JOIN MasterDates ON MasterDates.ID = DLData.DownloadID
	JOIN Products ON Products.ID = DLData.Product
	JOIN Sites ON Sites.EDISID = MasterDates.EDISID
	JOIN #SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = MasterDates.EDISID
	WHERE MasterDates.EDISID IN (SELECT EDISID FROM #Sites)
	AND ((MasterDates.Date < @AuditDate) OR  @ShowLatestData = 1)
	AND MasterDates.Date BETWEEN @From AND @To
	AND MasterDates.Date >= @SiteOnline
	AND (Products.IsCask = 0 OR @IncludeCasks = 1)
	AND (Products.IsCask = 1 OR @IncludeKegs = 1)
	AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
	AND (
		(DATEPART(DW, MasterDates.Date) = 1 AND @IncludeMondayDispense = 1)
		OR (DATEPART(DW, MasterDates.Date) = 2 AND @IncludeTuesdayDispense = 1)
		OR (DATEPART(DW, MasterDates.Date) = 3 AND @IncludeWednesdayDispense = 1)
		OR (DATEPART(DW, MasterDates.Date) = 4 AND @IncludeThursdayDispense = 1)
		OR (DATEPART(DW, MasterDates.Date) = 5 AND @IncludeFridayDispense = 1)
		OR (DATEPART(DW, MasterDates.Date) = 6 AND @IncludeSaturdayDispense = 1)
		OR (DATEPART(DW, MasterDates.Date) = 7 AND @IncludeSundayDispense = 1)
	)
	GROUP BY	Pump + PumpOffset,
				Products.Description
	ORDER BY	Pump + PumpOffset,
				Products.Description
END

DROP TABLE #Sites
DROP TABLE #SitePumpCounts
DROP TABLE #SitePumpOffsets

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteDispenseTotalsLocationFilter] TO PUBLIC
    AS [dbo];

