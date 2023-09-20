CREATE PROCEDURE [dbo].[GetWebSiteDispenseTotalsByProductLocationFilter]
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
	@IncludeLiquidWater				BIT = 1,
	@IncludeLiquidBeer				BIT = 1,
	@IncludeLiquidCleaner			BIT = 1,
	@IncludeLiquidInTransition		BIT = 1,
	@IncludeLiquidBeerInClean		BIT = 1,
	@LocationFilter					LocationFilter READONLY
)
AS

SET NOCOUNT ON
SET DATEFIRST 1

DECLARE @ShowLatestData BIT
DECLARE @AuditDate DATETIME

CREATE TABLE #Sites (EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
DECLARE @SiteGroupID INT
DECLARE @SiteOnline DATETIME
DECLARE @SiteQuality BIT

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

IF @SiteQuality = 1
BEGIN
	SELECT	Products.Description AS Product,
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
	GROUP BY Products.Description
	ORDER BY Products.Description
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
	SELECT	Products.Description AS Product,
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
	GROUP BY Products.Description
	ORDER BY Products.Description
END

DROP TABLE #Sites

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteDispenseTotalsByProductLocationFilter] TO PUBLIC
    AS [dbo];

