
CREATE PROCEDURE [dbo].[GetWebSiteLineCleaningEffectiveness]
(
	@EDISID	INT,
	@From	DATETIME,
	@To		DATETIME
)
AS

SET NOCOUNT ON

--Just cleaner
DECLARE @Cleans TABLE(EDISID INT NOT NULL, SitePumpID INT NOT NULL, PumpID INT NOT NULL, ProductID INT NOT NULL, 
					  [TradingDate] DATETIME NOT NULL, 
					  LiquidType INT NOT NULL, StartTime DATETIME NOT NULL, 
					  Pints FLOAT NOT NULL, Duration FLOAT NOT NULL,
					  LocationID INT NULL, MinCleaningTime DATETIME NULL, 
					  MaxCleaningTime DATETIME NULL, CleaningCashValue MONEY NOT NULL)
								  
--Water/Beer-in-clean liquid types
CREATE TABLE #WaterBeerInClean (EDISID INT NOT NULL, SitePumpID INT NOT NULL, PumpID INT NOT NULL, ProductID INT NOT NULL, 
				    			[TradingDate] DATETIME NOT NULL, 
								LiquidType INT NOT NULL, StartTime DATETIME NOT NULL, 
								Pints FLOAT NOT NULL, Duration FLOAT NOT NULL,
								LocationID INT NULL)

CREATE TABLE #CleanSumamry   (PumpID INT NOT NULL, 
							  Product VARCHAR(50) NOT NULL, Location VARCHAR(30) NOT NULL, 
							  [TradingDate] DATETIME NOT NULL, Volume FLOAT NOT NULL, 
							  SoakTimeMinsIncDuration FLOAT NOT NULL, 
							  MinCleaningTime DATETIME NOT NULL, MaxCleaningTime DATETIME NOT NULL,
							  Distributor VARCHAR(100) NOT NULL, DistributorShortName VARCHAR(5) NOT NULL,
							  CleaningCashValue MONEY NOT NULL)

DECLARE @Sites TABLE(EDISID INT NOT NULL, CleaningCashValue MONEY NOT NULL, CellarID INT NOT NULL IDENTITY)
DECLARE @SiteGroupID INT

CREATE TABLE #SitePumpCounts (Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
CREATE TABLE #SitePumpOffsets (EDISID INT NOT NULL PRIMARY KEY, PumpOffset INT NOT NULL)
 
CREATE TABLE #AllSitePumps (EDISID INT NOT NULL, SitePump INT NOT NULL,
			    	 PumpID INT NOT NULL, LocationID INT NOT NULL, ProductID INT NOT NULL,
			    	 ValidFrom DATETIME NOT NULL, ValidTo DATETIME NOT NULL,
                     DaysBeforeAmber INT NOT NULL, DaysBeforeRed INT NOT NULL, CleaningCashValue MONEY NOT NULL)

DECLARE @SiteOnline DATETIME
DECLARE @IsBQM BIT
 
SELECT @IsBQM = Quality, @SiteOnline = SiteOnline
FROM dbo.Sites
WHERE EDISID = @EDISID

-- Find out which EDISIDs are relevant (plough through SiteGroups)
INSERT INTO @Sites
(EDISID, CleaningCashValue)
SELECT EDISID, CleaningCashValue
FROM Sites
JOIN Owners ON Owners.ID = Sites.OwnerID
WHERE EDISID = @EDISID
 
SELECT @SiteGroupID = SiteGroupID
FROM SiteGroupSites
JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
WHERE TypeID = 1 AND EDISID = @EDISID
 
INSERT INTO @Sites (EDISID, CleaningCashValue)
SELECT SiteGroupSites.EDISID, CleaningCashValue
FROM SiteGroupSites
JOIN Sites ON Sites.EDISID = SiteGroupSites.EDISID
JOIN Owners ON Owners.ID = Sites.OwnerID
WHERE SiteGroupSites.SiteGroupID = @SiteGroupID AND SiteGroupSites.EDISID <> @EDISID
 
-- Get pumps for secondary sites (note that 1st EDISID IN @Sites is primary site)
INSERT INTO #SitePumpCounts (EDISID, MaxPump)
SELECT PumpSetup.EDISID, MAX(Pump)
FROM PumpSetup
JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
WHERE (ValidFrom <= @To)
AND (ISNULL(ValidTo, @To) >= @From)
AND (ISNULL(ValidTo, @To) >= @SiteOnline)
GROUP BY PumpSetup.EDISID, Sites.CellarID
ORDER BY CellarID

INSERT INTO #SitePumpOffsets (EDISID, PumpOffset)
SELECT MainCounts.EDISID, COALESCE(QuaternaryCounts.MaxPump+TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, 
SecondaryCounts.MaxPump, 0)
FROM #SitePumpCounts AS MainCounts
LEFT JOIN #SitePumpCounts AS SecondaryCounts ON SecondaryCounts.Counter+1 = MainCounts.Counter
LEFT JOIN #SitePumpCounts AS TertiaryCounts ON TertiaryCounts.Counter+2 = MainCounts.Counter
LEFT JOIN #SitePumpCounts AS QuaternaryCounts ON QuaternaryCounts.Counter+3 = MainCounts.Counter

INSERT INTO #AllSitePumps (EDISID, SitePump, PumpID, LocationID, ProductID, ValidFrom, ValidTo, DaysBeforeAmber, DaysBeforeRed, CleaningCashValue)
SELECT	PumpSetup.EDISID, PumpSetup.Pump,
	PumpSetup.Pump+PumpOffset, LocationID, PumpSetup.ProductID,
	PumpSetup.ValidFrom,
	ISNULL(PumpSetup.ValidTo, @To),
	COALESCE(SiteProductSpecifications.CleanDaysBeforeAmber, SiteSpecifications.CleanDaysBeforeAmber, Products.LineCleanDaysBeforeAmber),
	COALESCE(SiteProductSpecifications.CleanDaysBeforeRed, SiteSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed),
	Sites.CleaningCashValue
FROM PumpSetup
JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
JOIN #SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = PumpSetup.EDISID
JOIN Products ON Products.[ID] = PumpSetup.ProductID
LEFT JOIN SiteProductSpecifications ON SiteProductSpecifications.EDISID = PumpSetup.EDISID
				   AND SiteProductSpecifications.ProductID = PumpSetup.ProductID
LEFT JOIN SiteSpecifications ON Sites.EDISID = SiteSpecifications.EDISID
WHERE (ValidFrom <= @To)
AND (ISNULL(ValidTo, @To) >= @From)
AND (ISNULL(ValidTo, @To) >= @SiteOnline)

INSERT INTO @Cleans
(EDISID, SitePumpID, PumpID, ProductID, [TradingDate], LiquidType, StartTime, Pints, Duration, CleaningCashValue)
SELECT AllSitePumps.EDISID,
	   DispenseActions.Pump,
	   AllSitePumps.PumpID,
       DispenseActions.Product,
       TradingDay,
       DispenseActions.LiquidType,
       DispenseActions.StartTime,
       DispenseActions.Pints,
       DispenseActions.Duration,
       AllSitePumps.CleaningCashValue
FROM DispenseActions
JOIN #AllSitePumps AS AllSitePumps ON DispenseActions.Pump = AllSitePumps.SitePump AND DispenseActions.EDISID = AllSitePumps.EDISID
WHERE TradingDay BETWEEN @From AND @To
AND TradingDay BETWEEN AllSitePumps.ValidFrom AND AllSitePumps.ValidTo
AND TradingDay >= @SiteOnline
AND DispenseActions.LiquidType = 3

INSERT INTO #WaterBeerInClean
(EDISID, SitePumpID, PumpID, ProductID, [TradingDate], LiquidType, StartTime, Pints, Duration)
SELECT AllSitePumps.EDISID,
	   DispenseActions.Pump,
	   AllSitePumps.PumpID,
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

UPDATE @Cleans
SET LocationID = AllSitePumps.LocationID
FROM @Cleans AS DispenseConditions, #AllSitePumps AS AllSitePumps
WHERE AllSitePumps.SitePump = DispenseConditions.SitePumpID
	AND AllSitePumps.ProductID = DispenseConditions.ProductID
	AND AllSitePumps.EDISID = DispenseConditions.EDISID

UPDATE #WaterBeerInClean
SET LocationID = AllSitePumps.LocationID
FROM #WaterBeerInClean AS DispenseConditions, #AllSitePumps AS AllSitePumps
WHERE AllSitePumps.SitePump = DispenseConditions.SitePumpID
	AND AllSitePumps.ProductID = DispenseConditions.ProductID
	AND AllSitePumps.EDISID = DispenseConditions.EDISID
	
UPDATE @Cleans
SET MinCleaningTime = x.MinCleaningTime,
	MaxCleaningTime = x.MaxCleaningTime
FROM @Cleans AS Cleans
	INNER JOIN 
	(	SELECT EDISID,
			   SitePumpID,
			   ProductID,
			   LocationID,
			   LiquidType,
			   TradingDate,
			   MIN(StartTime) AS MinCleaningTime,
			   MAX(StartTime) AS MaxCleaningTime
		FROM @Cleans
		GROUP BY EDISID, SitePumpID, ProductID, LocationID, LiquidType, TradingDate
		HAVING LiquidType = 3
	) AS x
	ON  Cleans.EDISID = x.EDISID
	AND Cleans.SitePumpID = x.SitePumpID
	AND Cleans.ProductID = x.ProductID
	AND Cleans.LocationID = x.LocationID
	AND Cleans.TradingDate = x.TradingDate
	
-- Extra update to add the number of seconds onto the MaxCleaningTime to include those seconds too
UPDATE @Cleans
SET MaxCleaningTime = DATEADD(SECOND, x.Duration, x.StartTime)
FROM @Cleans AS Cleans
	INNER JOIN 
	(	SELECT EDISID,
			   SitePumpID,
			   ProductID,
			   LocationID,
			   LiquidType,
			   TradingDate,
			   StartTime,
			   Duration
		FROM @Cleans
		GROUP BY EDISID, SitePumpID, ProductID, LocationID, LiquidType, TradingDate, StartTime, Duration
		HAVING LiquidType = 3
	) AS x
	ON  Cleans.EDISID = x.EDISID
	AND Cleans.SitePumpID = x.SitePumpID
	AND Cleans.ProductID = x.ProductID
	AND Cleans.LocationID = x.LocationID
	AND Cleans.TradingDate = x.TradingDate
	AND Cleans.MaxCleaningTime = x.StartTime
	
INSERT INTO #CleanSumamry
(PumpID, Product, Location, [TradingDate], Volume, SoakTimeMinsIncDuration, MinCleaningTime, MaxCleaningTime, Distributor, DistributorShortName, CleaningCashValue)
SELECT Cleans.PumpID AS Pump, 
	   Products.[Description] AS Product, 
	   Locations.[Description] AS Location, 
	   Cleans.TradingDate AS [Date], 
       SUM(Cleans.Pints) AS Volume,
       --(DATEDIFF(ss, MIN(Cleans.StartTime), MAX(Cleans.StartTime))+SUM(Cleans.Duration))/60 AS SoakTimeMinsIncDuration,
	   (DATEDIFF(ss, MinCleaningTime, MaxCleaningTime))/60.0 AS SoakTimeMinsIncDuration,
       MinCleaningTime,
       MaxCleaningTime,
       ProductDistributors.[Description],
       ProductDistributors.ShortName,
       Cleans.CleaningCashValue
FROM @Cleans AS Cleans
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
		 ProductDistributors.[Description],
		 Cleans.CleaningCashValue
ORDER BY Cleans.PumpID, 
		 Cleans.[TradingDate]

SELECT CleanSummary.PumpID AS Pump,
       CleanSummary.Product,
       CleanSummary.Location,
       CleanSummary.Distributor,
       CleanSummary.DistributorShortName,
       CleanSummary.[TradingDate] AS [Date],
       CleanSummary.MinCleaningTime,
       ISNULL(SUM(CASE WHEN WaterBeerInClean.LiquidType = 1 AND WaterBeerInClean.StartTime < CleanSummary.MinCleaningTime THEN WaterBeerInClean.Pints END), 0) 
       AS WaterBefore,
       CleanSummary.Volume,
       CleanSummary.SoakTimeMinsIncDuration,
       ISNULL(SUM(CASE WHEN WaterBeerInClean.LiquidType = 1 AND WaterBeerInClean.StartTime > CleanSummary.MaxCleaningTime THEN WaterBeerInClean.Pints END), 0) 
       AS WaterAfter,
       CleanSummary.MaxCleaningTime,
       ISNULL(SUM(CASE WHEN WaterBeerInClean.LiquidType = 5 AND WaterBeerInClean.StartTime BETWEEN DATEADD(Hour, -2, CleanSummary.MinCleaningTime) AND DATEADD(Hour, 2, CleanSummary.MaxCleaningTime) THEN WaterBeerInClean.Pints END), 0) 
       AS BeerInClean,
       CleaningCashValue AS ProductCleaningCashValue,
       ROUND(ISNULL(SUM(CASE WHEN WaterBeerInClean.LiquidType = 5 AND WaterBeerInClean.StartTime BETWEEN DATEADD(Hour, -2, CleanSummary.MinCleaningTime) AND DATEADD(Hour, 2, CleanSummary.MaxCleaningTime) THEN WaterBeerInClean.Pints END), 0) * CleanSummary.CleaningCashValue, 2) AS CleaningCashValue
FROM #CleanSumamry AS CleanSummary
LEFT JOIN #WaterBeerInClean AS WaterBeerInClean ON WaterBeerInClean.TradingDate = CleanSummary.[TradingDate] AND WaterBeerInClean.PumpID = CleanSummary.PumpID
GROUP BY CleanSummary.PumpID,
       CleanSummary.Product,
       CleanSummary.Location,
       CleanSummary.[TradingDate],
       CleanSummary.Volume,
       CleanSummary.SoakTimeMinsIncDuration,
       CleanSummary.MinCleaningTime,
       CleanSummary.MaxCleaningTime,
       CleanSummary.Distributor,
       CleanSummary.DistributorShortName,
       CleanSummary.CleaningCashValue
ORDER BY CleanSummary.PumpID, CleanSummary.[TradingDate]

DROP TABLE #WaterBeerInClean
DROP TABLE #CleanSumamry
DROP TABLE #SitePumpCounts
DROP TABLE #SitePumpOffsets
DROP TABLE #AllSitePumps

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteLineCleaningEffectiveness] TO PUBLIC
    AS [dbo];

