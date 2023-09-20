
CREATE PROCEDURE [dbo].[GetSiteLineCleaningEffectiveness]
(
	@EDISID	INT,
	@From	DATETIME,
	@To		DATETIME
)
AS
 
SET NOCOUNT ON

--Just cleaner
CREATE TABLE #Cleans (EDISID INT NOT NULL, PumpID INT NOT NULL, ProductID INT NOT NULL, 
					  [TradingDate] DATETIME NOT NULL, 
					  LiquidType INT NOT NULL, StartTime DATETIME NOT NULL, 
					  Pints FLOAT NOT NULL, Duration FLOAT NOT NULL,
					  LocationID INT NULL, 
					  MinCleaningTime DATETIME NULL, MaxCleaningTime DATETIME NULL)
								  
--Water/Beer-in-clean liquid types
CREATE TABLE #WaterBeerInClean (EDISID INT NOT NULL, PumpID INT NOT NULL, ProductID INT NOT NULL, 
				    			[TradingDate] DATETIME NOT NULL, 
								LiquidType INT NOT NULL, StartTime DATETIME NOT NULL, 
								Pints FLOAT NOT NULL, Duration FLOAT NOT NULL,
								LocationID INT NULL)

DECLARE @Cleans TABLE(EDISID INT NOT NULL, PumpID INT NOT NULL, 
					  Product VARCHAR(50) NOT NULL, Location VARCHAR(30) NOT NULL, 
					  [TradingDate] DATETIME NOT NULL, Volume FLOAT NOT NULL, 
					  SoakTimeMinsIncDuration FLOAT NOT NULL, 
					  MinCleaningTime DATETIME NOT NULL, MaxCleaningTime DATETIME NOT NULL)

DECLARE @Sites TABLE(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
DECLARE @SiteGroupID INT

DECLARE @SitePumpCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL PRIMARY KEY, PumpOffset INT NOT NULL)
 
DECLARE @AllSitePumps TABLE(EDISID INT NOT NULL, SitePump INT NOT NULL,
			    	 PumpID INT NOT NULL, LocationID INT NOT NULL, ProductID INT NOT NULL,
			    	 ValidFrom DATETIME NOT NULL, ValidTo DATETIME NOT NULL,
                            	    	 DaysBeforeAmber INT NOT NULL, DaysBeforeRed INT NOT NULL)

DECLARE @SiteOnline DATETIME
DECLARE @IsBQM BIT
 
SELECT @IsBQM = Quality, @SiteOnline = SiteOnline
FROM dbo.Sites
WHERE EDISID = @EDISID

-- Find out which EDISIDs are relevant (plough through SiteGroups)
INSERT INTO @Sites
(EDISID)
SELECT EDISID
FROM Sites
WHERE EDISID = @EDISID
 
SELECT @SiteGroupID = SiteGroupID
FROM SiteGroupSites
JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
WHERE TypeID = 1 AND EDISID = @EDISID
 
INSERT INTO @Sites (EDISID)
SELECT SiteGroupSites.EDISID
FROM SiteGroupSites
JOIN Sites ON Sites.EDISID = SiteGroupSites.EDISID
WHERE SiteGroupSites.SiteGroupID = @SiteGroupID AND SiteGroupSites.EDISID <> @EDISID
 
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

INSERT INTO @SitePumpOffsets (EDISID, PumpOffset)
SELECT MainCounts.EDISID, COALESCE(QuaternaryCounts.MaxPump+TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, 
SecondaryCounts.MaxPump, 0)
FROM @SitePumpCounts AS MainCounts
LEFT JOIN @SitePumpCounts AS SecondaryCounts ON SecondaryCounts.Counter+1 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS TertiaryCounts ON TertiaryCounts.Counter+2 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS QuaternaryCounts ON QuaternaryCounts.Counter+3 = MainCounts.Counter

INSERT INTO @AllSitePumps (EDISID, SitePump, PumpID, LocationID, ProductID, ValidFrom, ValidTo, DaysBeforeAmber, DaysBeforeRed)
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

INSERT INTO #Cleans
(EDISID, PumpID, ProductID, [TradingDate], LiquidType, StartTime, Pints, Duration)
SELECT DispenseActions.EDISID,
	   DispenseActions.Pump,
       DispenseActions.Product,
       TradingDay,
       DispenseActions.LiquidType,
       DispenseActions.StartTime,
       DispenseActions.Pints,
       DispenseActions.Duration
FROM DispenseActions
JOIN @AllSitePumps AS AllSitePumps
  ON DispenseActions.Pump = AllSitePumps.SitePump
 AND DispenseActions.EDISID = AllSitePumps.EDISID
WHERE TradingDay BETWEEN @From AND @To
AND DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) BETWEEN AllSitePumps.ValidFrom AND AllSitePumps.ValidTo
AND DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) >= @SiteOnline
AND DispenseActions.LiquidType = 3

INSERT INTO #WaterBeerInClean
(EDISID, PumpID, ProductID, [TradingDate], LiquidType, StartTime, Pints, Duration)
SELECT DispenseActions.EDISID,
	   DispenseActions.Pump,
       DispenseActions.Product,
       TradingDay,
       DispenseActions.LiquidType,
       DispenseActions.StartTime,
       DispenseActions.Pints,
       DispenseActions.Duration
FROM DispenseActions
JOIN @AllSitePumps AS AllSitePumps
  ON DispenseActions.Pump = AllSitePumps.SitePump
 AND DispenseActions.EDISID = AllSitePumps.EDISID
WHERE TradingDay BETWEEN @From AND  @To
AND DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) BETWEEN AllSitePumps.ValidFrom AND AllSitePumps.ValidTo
AND DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) >= @SiteOnline
AND DispenseActions.LiquidType IN (1, 5)


UPDATE #Cleans
SET LocationID = AllSitePumps.LocationID
FROM #Cleans AS DispenseConditions, @AllSitePumps AS AllSitePumps
WHERE AllSitePumps.PumpID = DispenseConditions.PumpID
  AND AllSitePumps.ProductID = DispenseConditions.ProductID
  AND AllSitePumps.EDISID = DispenseConditions.EDISID

UPDATE #WaterBeerInClean
SET LocationID = AllSitePumps.LocationID
FROM #WaterBeerInClean AS DispenseConditions, @AllSitePumps AS AllSitePumps
WHERE AllSitePumps.PumpID = DispenseConditions.PumpID
  AND AllSitePumps.ProductID = DispenseConditions.ProductID
  AND AllSitePumps.EDISID = DispenseConditions.EDISID

UPDATE #Cleans
SET MinCleaningTime = x.MinCleaningTime,
	MaxCleaningTime = x.MaxCleaningTime
FROM #Cleans
	INNER JOIN 
	(	SELECT EDISID,
			   PumpID,
			   ProductID,
			   LocationID,
			   LiquidType,
			   TradingDate,
			   MIN(StartTime) AS MinCleaningTime,
			   MAX(StartTime) AS MaxCleaningTime
		FROM #Cleans
		GROUP BY EDISID, PumpID, ProductID, LocationID, LiquidType, TradingDate
		HAVING LiquidType = 3
	) AS x
	ON  #Cleans.PumpID = x.PumpID
	AND #Cleans.EDISID = x.EDISID
	AND #Cleans.ProductID = x.ProductID
	AND #Cleans.LocationID = x.LocationID
	AND #Cleans.TradingDate = x.TradingDate

INSERT INTO @Cleans
(EDISID, PumpID, Product, Location, [TradingDate], Volume, SoakTimeMinsIncDuration, MinCleaningTime, MaxCleaningTime)
SELECT DispenseConditions.EDISID,
	   DispenseConditions.PumpID AS Pump, 
	   Products.[Description] AS Product, 
	   Locations.[Description] AS Location, 
	   DispenseConditions.TradingDate AS [Date], 
       SUM(DispenseConditions.Pints) AS Volume,
       (DATEDIFF(ss, MIN(DispenseConditions.StartTime), MAX(DispenseConditions.StartTime))+SUM(DispenseConditions.Duration))/60 AS SoakTimeMinsIncDuration,
       MinCleaningTime,
       MaxCleaningTime
FROM #Cleans AS DispenseConditions
JOIN Products 
  ON Products.ID = DispenseConditions.ProductID
JOIN Locations 
  ON Locations.ID = DispenseConditions.LocationID
GROUP BY DispenseConditions.EDISID,
		 DispenseConditions.PumpID,
		 Products.[Description],
		 Locations.[Description],
		 DispenseConditions.TradingDate,
		 MinCleaningTime,
		 MaxCleaningTime
ORDER BY DispenseConditions.PumpID, 
		 DispenseConditions.[TradingDate]

SELECT Cleans.EDISID,
	   Cleans.PumpID,
       Cleans.Product,
       Cleans.Location,
       Cleans.[TradingDate] AS [Date],
       Cleans.Volume,
       Cleans.SoakTimeMinsIncDuration,
       Cleans.MinCleaningTime,
       Cleans.MaxCleaningTime,
       ISNULL(SUM(CASE WHEN DispenseConditions.LiquidType = 1 AND DispenseConditions.StartTime < Cleans.MinCleaningTime THEN DispenseConditions.Pints END), 0) 
       AS WaterBefore,
       ISNULL(SUM(CASE WHEN DispenseConditions.LiquidType = 1 AND DispenseConditions.StartTime > Cleans.MaxCleaningTime THEN DispenseConditions.Pints END), 0) 
       AS WaterAfter,
       ISNULL(SUM(CASE WHEN DispenseConditions.LiquidType = 5 AND DispenseConditions.StartTime BETWEEN DATEADD(Hour, -2, Cleans.MinCleaningTime) AND DATEADD(Hour, 2, Cleans.MaxCleaningTime) THEN DispenseConditions.Pints END), 0) 
       AS BeerInClean
FROM @Cleans AS Cleans
JOIN #WaterBeerInClean AS DispenseConditions 
  ON DispenseConditions.TradingDate = Cleans.[TradingDate]
 AND DispenseConditions.PumpID = Cleans.PumpID
GROUP BY Cleans.EDISID,
			 Cleans.PumpID,
       Cleans.Product,
       Cleans.Location,
       Cleans.[TradingDate],
       Cleans.Volume,
       Cleans.SoakTimeMinsIncDuration,
       Cleans.MinCleaningTime,
       Cleans.MaxCleaningTime
ORDER BY Cleans.[TradingDate], Cleans.PumpID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteLineCleaningEffectiveness] TO PUBLIC
    AS [dbo];

