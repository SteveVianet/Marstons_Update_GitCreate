CREATE PROCEDURE [dbo].[GetWebSiteLowVolumeReport]
(
	@EDISID			INT,
	@From			DATETIME,
	@To				DATETIME,
	@IncludeCasks	BIT,
	@IncludeKegs	BIT,
	@IncludeMetric	BIT
)
AS

SET NOCOUNT ON
SET DATEFIRST 1

DECLARE @LowVolumeThreshold  FLOAT

DECLARE @Sites TABLE(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY) DECLARE @SiteGroupID INT DECLARE @PrimaryProducts TABLE(ProductID INT NOT NULL, PrimaryProductID INT NOT NULL) DECLARE @SiteOnline DATETIME
CREATE TABLE #SitePumpCounts (Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
CREATE TABLE #SitePumpOffsets (EDISID INT NOT NULL, PumpOffset INT NOT NULL)

SELECT @SiteOnline = SiteOnline
FROM dbo.Sites
WHERE EDISID = @EDISID

-- Find out which EDISIDs are relevant (plough through SiteGroups) 
INSERT INTO @Sites (EDISID)
SELECT @EDISID AS EDISID

SELECT @SiteGroupID = SiteGroupID
FROM SiteGroupSites
JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID WHERE TypeID = 1 AND EDISID = @EDISID

INSERT INTO @Sites (EDISID)
SELECT EDISID
FROM SiteGroupSites
WHERE SiteGroupID = @SiteGroupID AND EDISID <> @EDISID

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
SELECT MainCounts.EDISID, COALESCE(QuaternaryCounts.MaxPump+TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, SecondaryCounts.MaxPump, 0)
FROM #SitePumpCounts AS MainCounts
LEFT JOIN #SitePumpCounts AS SecondaryCounts ON SecondaryCounts.Counter+1 = MainCounts.Counter
LEFT JOIN #SitePumpCounts AS TertiaryCounts ON TertiaryCounts.Counter+2 = MainCounts.Counter
LEFT JOIN #SitePumpCounts AS QuaternaryCounts ON QuaternaryCounts.Counter+3 = MainCounts.Counter

--Read the 
SELECT	@LowVolumeThreshold = EDISDBs.LowVolumeThreshold
FROM [EDISSQL1\SQL1].ServiceLogger.dbo.EDISDatabases AS EDISDBs
JOIN Configuration 
  ON Configuration.PropertyName = 'Service Owner ID'
WHERE EDISDBs.Name = DB_NAME()
  AND EDISDBs.ID = Configuration.PropertyValue

;WITH WeeklyDispense AS (
SELECT	PeriodCacheTradingDispense.EDISID,
		DATEADD(dw, -DATEPART(dw, PeriodCacheTradingDispense.TradingDay) + 1, PeriodCacheTradingDispense.TradingDay) AS TradingDate,
		PeriodCacheTradingDispense.Pump + PumpOffset AS Pump,
		Products.[Description] AS Product,
		ProductCategories.[Description] AS ProductCategory,
		Locations.[Description] AS Location,
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
JOIN #SitePumpOffsets AS SitePumpOffsets 
  ON SitePumpOffsets.EDISID = PeriodCacheTradingDispense.EDISID
JOIN PumpSetup 
  ON PumpSetup.EDISID = Sites.EDISID
 AND PumpSetup.Pump = PeriodCacheTradingDispense.Pump
 AND PumpSetup.ValidTo IS NULL AND PumpSetup.InUse = 1
WHERE PeriodCacheTradingDispense.TradingDay BETWEEN @From AND @To
  AND Products.IncludeInLowVolume = 1
  AND (Products.IsCask = 0 OR @IncludeCasks = 1)
  AND (Products.IsCask = 1 OR @IncludeKegs = 1)
  AND (Products.IsMetric = 0 OR @IncludeMetric = 1) 
GROUP BY	PeriodCacheTradingDispense.EDISID,
			DATEADD(dw, -DATEPART(dw, PeriodCacheTradingDispense.TradingDay) + 1, PeriodCacheTradingDispense.TradingDay),
			PeriodCacheTradingDispense.Pump + PumpOffset,
			Products.[Description],
			ProductCategories.[Description],
			Locations.[Description]
)
SELECT	EDISDBs.ID AS [DBID],
		WeeklyDispense.EDISID,
		SiteDetails.SiteID,
		SiteDetails.Name,
		BDMUser.UserName AS BDMName,
		RMUser.UserName AS RMName,
		WeeklyDispense.Pump,
		WeeklyDispense.Product,
		WeeklyDispense.ProductCategory,
		AVG(WeeklyDispense.WeeklyVolume) AS AverageWeeklyVolume,
		SUM(WeeklyDispense.WeeklyVolume) AS TotalWeeklyVolume,
		AVG(WeeklyDispense.WeeklyWastedVolume) AS AverageWastedVolume,
		SUM(WeeklyDispense.WeeklyWastedVolume) AS TotalWastedVolume
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

DROP TABLE #SitePumpCounts
DROP TABLE #SitePumpOffsets

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteLowVolumeReport] TO PUBLIC
    AS [dbo];

