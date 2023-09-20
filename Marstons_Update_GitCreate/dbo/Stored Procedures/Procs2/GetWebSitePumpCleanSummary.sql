
CREATE PROCEDURE [dbo].[GetWebSitePumpCleanSummary]
(
	@EDISID			INT,
	@From				DATETIME,
	@To				DATETIME,
	@IncludeCasks			BIT,
	@IncludeKegs			BIT,
	@IncludeMetric			BIT
)
AS

SET NOCOUNT ON

DECLARE @Sites TABLE(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
DECLARE @SiteGroupID INT
DECLARE @SitePumpCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL, PumpOffset INT NOT NULL)
DECLARE @AllSitePumps TABLE(PumpID INT NOT NULL, LocationID INT NOT NULL, ProductID INT NOT NULL,
				      DaysBeforeAmber INT NOT NULL, DaysBeforeRed INT NOT NULL,
				      ValidFrom DATETIME NOT NULL, ValidTo DATETIME NOT NULL,
				      EDISID INT NOT NULL, RealPumpID INT NOT NULL, 
				      LastClean DATETIME, Dirty BIT DEFAULT 1,
				      DispenseFrom DATETIME)
DECLARE @SiteOnline DATETIME
DECLARE @MaxDaysBackForClean	INT
DECLARE @CheckForCleansFrom DATETIME

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

--SELECT * FROM @Sites

-- Get pumps for secondary sites (note that 1st EDISID IN @Sites is primary site)
INSERT INTO @SitePumpCounts (EDISID, MaxPump)
SELECT PumpSetup.EDISID, MAX(Pump)
FROM PumpSetup
JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
WHERE (ValidFrom <= @To)
AND (ISNULL(ValidTo, @To) >= @From)
AND (ISNULL(ValidTo, @To) >= @SiteOnline)
GROUP BY PumpSetup.EDISID, Sites.CellarID
ORDER BY CellarID

--SELECT * FROM @SitePumpCounts

INSERT INTO @SitePumpOffsets (EDISID, PumpOffset)
SELECT MainCounts.EDISID, COALESCE(QuaternaryCounts.MaxPump+TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, 
SecondaryCounts.MaxPump, 0)
FROM @SitePumpCounts AS MainCounts
LEFT JOIN @SitePumpCounts AS SecondaryCounts ON SecondaryCounts.Counter+1 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS TertiaryCounts ON TertiaryCounts.Counter+2 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS QuaternaryCounts ON QuaternaryCounts.Counter+3 = MainCounts.Counter

--SELECT * FROM @SitePumpOffsets

INSERT INTO @AllSitePumps (PumpID, LocationID, ProductID, DaysBeforeAmber, DaysBeforeRed, ValidFrom, ValidTo, EDISID, RealPumpID)
SELECT Pump+PumpOffset, LocationID, PumpSetup.ProductID,
	COALESCE(SiteProductSpecifications.CleanDaysBeforeAmber, SiteSpecifications.CleanDaysBeforeAmber, Products.LineCleanDaysBeforeAmber),
	COALESCE(SiteProductSpecifications.CleanDaysBeforeRed, SiteSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed),
	ValidFrom,
	ISNULL(ValidTo, @To),
	Sites.EDISID,
	PumpSetup.Pump
FROM PumpSetup
JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = PumpSetup.EDISID
JOIN Products ON Products.[ID] = PumpSetup.ProductID
LEFT JOIN SiteProductSpecifications ON Products.ID = SiteProductSpecifications.ProductID AND PumpSetup.EDISID = SiteProductSpecifications.EDISID
LEFT JOIN SiteSpecifications ON Sites.EDISID = SiteSpecifications.EDISID
WHERE (ValidFrom <= @To)
AND (ISNULL(ValidTo, @To) >= @From)
AND (ISNULL(ValidTo, @To) >= @SiteOnline)
AND Products.IsWater = 0
AND (Products.IsCask = 0 OR @IncludeCasks = 1)
AND (Products.IsCask = 1 OR @IncludeKegs = 1)
AND (Products.IsMetric = 0 OR @IncludeMetric = 1)

SELECT @MaxDaysBackForClean = MAX(DaysBeforeRed) FROM @AllSitePumps
SET @CheckForCleansFrom = DATEADD(Day, -@MaxDaysBackForClean, @From)

-- Find date each pump was last cleaned
UPDATE @AllSitePumps
SET LastClean = LastPumpCleans.LastCleaned,
	Dirty = (CASE WHEN DATEADD([Day], DaysBeforeRed, LastPumpCleans.LastCleaned) < DATEADD([Day], 1, @To) THEN 1 ELSE 0 END),
	DispenseFrom = CASE WHEN DATEADD([Day], DaysBeforeRed, LastPumpCleans.LastCleaned) > @From THEN DATEADD([Day], DaysBeforeRed, LastPumpCleans.LastCleaned) ELSE @From END
FROM (
	SELECT  AllSitePumps.PumpID,
		MAX(DispenseActions.TradingDay) AS LastCleaned
	FROM DispenseActions
	JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = DispenseActions.EDISID
	JOIN @AllSitePumps AS AllSitePumps ON AllSitePumps.PumpID = DispenseActions.Pump + PumpOffset
					     AND AllSitePumps.ProductID = DispenseActions.Product
					     AND AllSitePumps.LocationID = DispenseActions.Location

	WHERE DispenseActions.EDISID IN (SELECT EDISID FROM @Sites)
	--AND TradingDay BETWEEN @CheckForCleansFrom AND @To
	AND TradingDay >= @SiteOnline
	AND LiquidType = 3
	GROUP BY AllSitePumps.PumpID
) AS LastPumpCleans
INNER JOIN @AllSitePumps AS AllSitePumps ON LastPumpCleans.PumpID = AllSitePumps.PumpID

UPDATE @AllSitePumps SET DispenseFrom = @From WHERE DispenseFrom IS NULL

--SELECT * FROM @AllSitePumps

SELECT AllSitePumps.PumpID AS Pump,
	Products.Description AS Product,
	Locations.Description AS Location,
	SUM(DirtyDispense.Quantity) AS Quantity,
	AllSitePumps.LastClean,
	DaysBeforeAmber,
	DaysBeforeRed
FROM @AllSitePumps AS AllSitePumps
JOIN Locations ON (Locations.ID = AllSitePumps.LocationID)
JOIN Products ON (Products.ID = AllSitePumps.ProductID)
LEFT JOIN (
	SELECT	EDISID,
			Pump,
			Product,
			Location,
			TradingDay,
			SUM(Pints) AS Quantity
	FROM DispenseActions
	WHERE DispenseActions.EDISID IN (SELECT EDISID FROM @Sites)
	AND TradingDay BETWEEN @From AND @To
	AND TradingDay >= @SiteOnline
	AND (LiquidType = 2)
	GROUP BY EDISID, Pump, TradingDay, Product, Location
) AS DirtyDispense ON (DirtyDispense.EDISID = AllSitePumps.EDISID
						AND DirtyDispense.Pump = AllSitePumps.RealPumpID
						AND DirtyDispense.TradingDay BETWEEN AllSitePumps.DispenseFrom AND @To
						AND DirtyDispense.Product = AllSitePumps.ProductID
					    AND DirtyDispense.Location = AllSitePumps.LocationID)
WHERE Dirty = 1
GROUP BY AllSitePumps.PumpID, Products.Description, Locations.Description, LastClean, DaysBeforeAmber, DaysBeforeRed
HAVING SUM(DirtyDispense.Quantity) > 3

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSitePumpCleanSummary] TO PUBLIC
    AS [dbo];

