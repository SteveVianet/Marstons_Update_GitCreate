

CREATE PROCEDURE [dbo].[GetWebUserLowThroughputOverview]
(
	@UserID	INT,
	@From	DATETIME,
	@To		DATETIME,
	@Weekly BIT = 0,
	@IncludeDMS BIT = 1
)
AS

DECLARE @IsAllSitesVisible   BIT
DECLARE @EDISDatabaseID		 INT
DECLARE @TotalPumps			 INT
DECLARE @ThroughputLowValue  FLOAT

DECLARE @RelevantSites TABLE (EDISID INT NOT NULL, IsIDraught BIT)

SET DATEFIRST 1
SET NOCOUNT ON

SELECT @EDISDatabaseID = CAST(PropertyValue AS INT)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

SELECT @IsAllSitesVisible = UserTypes.AllSitesVisible
FROM Users
JOIN UserTypes ON UserTypes.ID = Users.UserType
WHERE Users.ID = @UserID

IF @IsAllSitesVisible = 0
BEGIN
	INSERT INTO @RelevantSites
	 (EDISID)
	SELECT UserSites.EDISID
	FROM UserSites
	JOIN Sites ON Sites.EDISID = UserSites.EDISID
	WHERE UserID = @UserID
	  AND Sites.Hidden = 0
	  AND ((@IncludeDMS = 1) OR (Sites.Quality = 1))
END
ELSE
BEGIN
	INSERT INTO @RelevantSites
	 (EDISID)
	SELECT EDISID
	FROM Sites
	WHERE Hidden = 0
	  AND ((@IncludeDMS = 1) OR (Sites.Quality = 1))
END

SELECT @ThroughputLowValue = MAX(Owners.ThroughputLowValue)
FROM @RelevantSites AS RS
JOIN Sites ON Sites.EDISID = RS.EDISID
JOIN Owners ON Owners.ID = Sites.OwnerID

SELECT @TotalPumps = COUNT(PumpSetup.Pump)
FROM PumpSetup
JOIN @RelevantSites AS Sites
 ON Sites.EDISID = PumpSetup.EDISID
WHERE PumpSetup.InUse = 1 
 AND PumpSetup.ValidTo IS NULL

;WITH WeeklyLines AS (
	--This groups the Volume for each pump on a site into weeksly totals
	SELECT 
		CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, PeriodCacheTradingDispense.TradingDay), 0) AS DATE) AS WeekCommencing,
		PeriodCacheTradingDispense.EDISID, 
		PeriodCacheTradingDispense.Pump, 
		SUM(Volume) AS Volume
	FROM PeriodCacheTradingDispense
	JOIN @RelevantSites AS Sites
		ON Sites.EDISID = PeriodCacheTradingDispense.EDISID
	JOIN PumpSetup 
	  ON PumpSetup.EDISID = Sites.EDISID
	 AND PumpSetup.Pump = PeriodCacheTradingDispense.Pump
	 AND PumpSetup.ProductID = PeriodCacheTradingDispense.ProductID
	 AND PumpSetup.InUse = 1 
	 AND PumpSetup.ValidTo IS NULL
	JOIN Products 
		ON Products.ID = PeriodCacheTradingDispense.ProductID
	JOIN ProductCategories
	  ON ProductCategories.ID = Products.CategoryID
	WHERE	Products.IncludeInLowVolume = 1
	AND		Products.IsMetric = 0
	AND		ProductCategories.IncludeInEstateReporting = 1
	GROUP BY 
		CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, PeriodCacheTradingDispense.TradingDay), 0) AS DATE),
		PeriodCacheTradingDispense.EDISID, 
		PeriodCacheTradingDispense.Pump
	HAVING 
		CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, PeriodCacheTradingDispense.TradingDay), 0) AS DATE) BETWEEN @From AND @To)
,SiteLowThroughputLines AS (
	--This selects each pump for a site determined to be low throughput, while also changing the date into one which will match the end select statement (may be month or week depending in @Weekly)
	SELECT 
		CASE @Weekly WHEN 1 THEN CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, WeekCommencing), 0) AS DATE) ELSE CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WeekCommencing), 0) AS DATE) END AS WeekCommencing,
		EDISID, 
		Pump
	FROM WeeklyLines
	GROUP BY WeekCommencing, EDISID, Pump
	HAVING AVG(Volume) < @ThroughputLowValue)
,LowThroughput AS (
	--This counts the number of low throughput pumps per week/month (period depends on previous statement)
	SELECT 
		WeekCommencing,
		COUNT(DISTINCT(EDISID + ' ' + Pump)) AS LowLines
	FROM SiteLowThroughputLines
	GROUP BY WeekCommencing)
SELECT	
	CASE @Weekly WHEN 1 THEN CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, PeriodCacheTradingDispense.TradingDay), 0) AS DATE) ELSE CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, PeriodCacheTradingDispense.TradingDay), 0) AS DATE) END AS WeekCommencing,
	Users.UserName,
	SUM(PeriodCacheTradingDispense.Volume) AS WeeklyVolume,
	SUM(PeriodCacheTradingDispense.WastedVolume) AS WeeklyWastedVolume,
	AVG(LowThroughput.LowLines) AS LowThroughputLines,
	@TotalPumps AS TotalLines,
	AVG(LowThroughput.LowLines) / CAST(@TotalPumps AS FLOAT) AS LowThroughputPercent
FROM PeriodCacheTradingDispense
JOIN @RelevantSites AS Sites
  ON Sites.EDISID = PeriodCacheTradingDispense.EDISID
JOIN PumpSetup 
  ON PumpSetup.EDISID = Sites.EDISID
 AND PumpSetup.Pump = PeriodCacheTradingDispense.Pump
 AND PumpSetup.ProductID = PeriodCacheTradingDispense.ProductID
 AND PumpSetup.InUse = 1 
 AND PumpSetup.ValidTo IS NULL
JOIN Products
  ON Products.ID = PeriodCacheTradingDispense.ProductID
 AND Products.IncludeInLowVolume = 1
 AND Products.IsMetric = 0
JOIN ProductCategories
  ON ProductCategories.ID = Products.CategoryID 
 AND ProductCategories.IncludeInEstateReporting = 1
JOIN LowThroughput
  ON LowThroughput.WeekCommencing = CASE @Weekly WHEN 1 THEN CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, PeriodCacheTradingDispense.TradingDay), 0) AS DATE) ELSE CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, PeriodCacheTradingDispense.TradingDay), 0) AS DATE) END
JOIN Users ON Users.ID = @UserID
GROUP BY
	CASE @Weekly WHEN 1 THEN CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, PeriodCacheTradingDispense.TradingDay), 0) AS DATE) ELSE CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, PeriodCacheTradingDispense.TradingDay), 0) AS DATE) END,
	Users.UserName
HAVING 
	CASE @Weekly WHEN 1 THEN CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, PeriodCacheTradingDispense.TradingDay), 0) AS DATE) ELSE CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, PeriodCacheTradingDispense.TradingDay), 0) AS DATE) END BETWEEN @From AND @To
ORDER BY 
	CASE @Weekly WHEN 1 THEN CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, PeriodCacheTradingDispense.TradingDay), 0) AS DATE) ELSE CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, PeriodCacheTradingDispense.TradingDay), 0) AS DATE) END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserLowThroughputOverview] TO PUBLIC
    AS [dbo];

