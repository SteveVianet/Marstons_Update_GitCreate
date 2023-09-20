
CREATE PROCEDURE [dbo].[GetWebSiteLineFlushes]
(
	@EDISID	INT,
	@From		DATETIME,
	@To		DATETIME,
	@WaterThreshold FLOAT
)
AS
 
SET NOCOUNT ON

--Just water
CREATE TABLE #Flushes (PumpID INT NOT NULL, ProductID INT NOT NULL, 
					   [TradingDate] DATETIME NOT NULL, 
					   LiquidType INT NOT NULL, StartTime DATETIME NOT NULL, 
					   Pints FLOAT NOT NULL, Duration FLOAT NOT NULL,
					   LocationID INT NULL, 
					   MinFlushTime DATETIME NULL, MaxFlushTime DATETIME NULL)

DECLARE @Sites TABLE(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
DECLARE @SiteGroupID INT

DECLARE @SitePumpCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL PRIMARY KEY, PumpOffset INT NOT NULL)
 
DECLARE @AllSitePumps TABLE(EDISID INT NOT NULL, SitePump INT NOT NULL,
			    			PumpID INT NOT NULL, LocationID INT NOT NULL, ProductID INT NOT NULL,
			    			ValidFrom DATETIME NOT NULL, ValidTo DATETIME NOT NULL,
                            DaysBeforeAmber INT NOT NULL, DaysBeforeRed INT NOT NULL)

DECLARE @Flushes TABLE(PumpID INT NOT NULL, 
				  	   Product VARCHAR(50) NOT NULL, Location VARCHAR(30) NOT NULL, 
					   [TradingDate] DATETIME NOT NULL, Volume FLOAT NOT NULL, 
					   SoakTimeMinsIncDuration FLOAT NOT NULL, 
					   MinFlushTime DATETIME NOT NULL, MaxFlushTime DATETIME NOT NULL)

DECLARE @SiteOnline DATETIME
DECLARE @IsBQM BIT
 
SELECT @IsBQM = Quality, @SiteOnline = SiteOnline
FROM dbo.Sites
WHERE EDISID = @EDISID

IF @IsBQM = 1
BEGIN
	SET @WaterThreshold = 0	
END

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

INSERT INTO #Flushes
(PumpID, ProductID, [TradingDate], LiquidType, StartTime, Pints, Duration)
SELECT AllSitePumps.PumpID,
       DispenseActions.Product,
       TradingDay,
       DispenseActions.LiquidType,
       DispenseActions.StartTime,
       DispenseActions.Pints,
       DispenseActions.Duration
FROM DispenseActions
JOIN @AllSitePumps AS AllSitePumps ON DispenseActions.Pump = AllSitePumps.SitePump AND DispenseActions.EDISID = AllSitePumps.EDISID
WHERE DispenseActions.LiquidType = 1
  AND TradingDay BETWEEN @From AND @To
  AND TradingDay BETWEEN AllSitePumps.ValidFrom AND AllSitePumps.ValidTo
  AND TradingDay >= @SiteOnline


UPDATE #Flushes
SET LocationID = AllSitePumps.LocationID
FROM #Flushes AS DispenseConditions, @AllSitePumps AS AllSitePumps
WHERE AllSitePumps.PumpID = DispenseConditions.PumpID
  AND AllSitePumps.ProductID = DispenseConditions.ProductID
  
UPDATE #Flushes
SET MinFlushTime = x.MinFlushTime,
	MaxFlushTime = x.MaxFlushTime
FROM #Flushes
	INNER JOIN 
	(	SELECT PumpID,
			   ProductID,
			   LocationID,
			   LiquidType,
			   TradingDate,
			   MIN(StartTime) AS MinFlushTime,
			   MAX(StartTime) AS MaxFlushTime
		FROM #Flushes
		GROUP BY PumpID, ProductID, LocationID, LiquidType, TradingDate
		HAVING LiquidType = 1
	) AS x
	ON  #Flushes.PumpID = x.PumpID
	AND #Flushes.ProductID = x.ProductID
	AND #Flushes.LocationID = x.LocationID
	AND #Flushes.TradingDate = x.TradingDate

--INSERT INTO @Flushes
--(PumpID, Product, Location, [TradingDate], Volume, SoakTimeMinsIncDuration, MinFlushTime, MaxFlushTime)

SELECT DispenseConditions.PumpID, 
	   Products.[Description] AS Product, 
	   Locations.[Description] AS Location, 
	   DispenseConditions.TradingDate AS [Date], 
       SUM(DispenseConditions.Pints) AS Volume,
       (DATEDIFF(ss, MIN(DispenseConditions.StartTime), MAX(DispenseConditions.StartTime))+SUM(DispenseConditions.Duration))/60 AS SoakTimeMinsIncDuration,
       MinFlushTime,
       MaxFlushTime
FROM #Flushes AS DispenseConditions
JOIN Products 
  ON Products.ID = DispenseConditions.ProductID
JOIN Locations 
  ON Locations.ID = DispenseConditions.LocationID
GROUP BY DispenseConditions.PumpID,
		 Products.[Description],
		 Locations.[Description],
		 DispenseConditions.TradingDate,
		 MinFlushTime,
		 MaxFlushTime
HAVING SUM(DispenseConditions.Pints) >= @WaterThreshold
ORDER BY DispenseConditions.[TradingDate],
		 DispenseConditions.PumpID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteLineFlushes] TO PUBLIC
    AS [dbo];

