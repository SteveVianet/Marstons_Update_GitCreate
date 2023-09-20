
CREATE PROCEDURE [dbo].[GetOverdueLineCleaningDispensePump]
	@EDISID		INT,
	@FromDate	DATETIME,
	@ToDate		DATETIME
AS


/*
DECLARE @EDISID INT = 2062
DECLARE @FromDate	DATETIME = '2014-09-08 00:00:00.000'
DECLARE @ToDate		DATETIME = '2014-10-05 00:00:00.000'
*/


SET NOCOUNT ON;

DECLARE @ShowInUseLinesOnly BIT = 1

DECLARE @First AS INT
SET @First = 1
SET DATEFIRST @First

DECLARE @Sites TABLE(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
DECLARE @SitePumpCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL PRIMARY KEY, PumpOffset INT NOT NULL)
 
DECLARE @AllSitePumps TABLE(EDISID INT NOT NULL, SitePump INT NOT NULL,
			    	 PumpID INT NOT NULL, LocationID INT NOT NULL, ProductID INT NOT NULL,
			    	 ValidFrom DATETIME NOT NULL, ValidTo DATETIME NOT NULL,
               DaysBeforeAmber INT NOT NULL, DaysBeforeRed INT NOT NULL)

DECLARE @SiteGroupID INT
DECLARE @SiteOnline DATETIME
DECLARE @IsIDraught BIT

SELECT @IsIDraught = Quality, @SiteOnline = SiteOnline
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
WHERE (ValidFrom <= @ToDate)
AND (ISNULL(ValidTo, @ToDate) >= @FromDate)
AND (ISNULL(ValidTo, @ToDate) >= @SiteOnline)
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
	PumpSetup.Pump+PumpOffset, PumpSetup.LocationID, PumpSetup.ProductID,
	PumpSetup.ValidFrom,
	ISNULL(PumpSetup.ValidTo, @ToDate),
	COALESCE(SiteProductSpecifications.CleanDaysBeforeAmber, SiteSpecifications.CleanDaysBeforeAmber, Products.LineCleanDaysBeforeAmber),
	COALESCE(SiteProductSpecifications.CleanDaysBeforeRed, SiteSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed)
FROM PumpSetup
JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = PumpSetup.EDISID
JOIN Products ON Products.[ID] = PumpSetup.ProductID
LEFT JOIN SiteProductSpecifications ON SiteProductSpecifications.EDISID = PumpSetup.EDISID
				   AND SiteProductSpecifications.ProductID = PumpSetup.ProductID
LEFT JOIN SiteSpecifications ON Sites.EDISID = SiteSpecifications.EDISID
WHERE (ValidFrom <= @ToDate)
AND (ISNULL(ValidTo, @ToDate) >= @FromDate)
AND (ISNULL(ValidTo, @ToDate) >= @SiteOnline)
AND Products.IsWater = 0
AND (InUse = 1 OR @ShowInUseLinesOnly = 0)

--Merge secondary systems
DECLARE @PrimaryEDIS TABLE(PrimaryEDISID INT NOT NULL, EDISID INT NOT NULL)
INSERT INTO @PrimaryEDIS
SELECT MAX(PrimaryEDISID) AS PrimaryEDISID, SiteGroupSites.EDISID
FROM(
	SELECT SiteGroupID, SiteGroupSites.EDISID AS PrimaryEDISID
	FROM SiteGroupSites 
	WHERE SiteGroupID IN (SELECT ID FROM SiteGroups WHERE TypeID = 1)
	AND IsPrimary = 1
	GROUP BY SiteGroupID, SiteGroupSites.EDISID
) AS PrimarySites
JOIN SiteGroupSites ON SiteGroupSites.SiteGroupID = PrimarySites.SiteGroupID
LEFT JOIN PumpSetup ON PumpSetup.EDISID = SiteGroupSites.EDISID
GROUP BY SiteGroupSites.EDISID
ORDER BY PrimaryEDISID

--Find the earliest iDraught date for each site
CREATE TABLE #iDraughtStarts (EDISID INT, FirstPour DATE, LastPour DATE)
INSERT INTO #iDraughtStarts (EDISID, FirstPour, LastPour)
SELECT EDISID, QualityStart, ISNULL(QualityEnd, CAST(GETDATE() AS DATE))
FROM SiteQualityHistory
WHERE EDISID = @EDISID

--CREATE TABLE #iDraughtStarts (EDISID INT, FirstPour DATE, LastPour DATE)
--INSERT INTO #iDraughtStarts (EDISID, FirstPour, LastPour)
--SELECT	EDISID, 
--		MIN(CASE WHEN DATEPART(HOUR, CleaningStack.[Time]) < 5 THEN DATEADD(DAY, -1, [Date]) ELSE [Date] END),
--		MAX(CASE WHEN DATEPART(HOUR, CleaningStack.[Time]) < 5 THEN DATEADD(DAY, -1, [Date]) ELSE [Date] END)
--FROM CleaningStack
--JOIN MasterDates ON MasterDates.ID = CleaningStack.CleaningID
--WHERE EDISID = @EDISID
--GROUP BY EDISID

-- Get iDraught cleans (from CleaningStack)
CREATE TABLE #LineCleans (EDISID INT, Pump INT, ProductID INT, LocationID INT, [Date] DATETIME)
INSERT INTO #LineCleans
SELECT ISNULL(PrimaryEDIS.PrimaryEDISID, MasterDates.EDISID),
	PumpSetup.Pump,
	PumpSetup.ProductID,
	PumpSetup.LocationID,
	MasterDates.[Date]
FROM CleaningStack
JOIN MasterDates ON MasterDates.ID = CleaningStack.CleaningID
JOIN Sites ON Sites.EDISID = MasterDates.EDISID
JOIN PumpSetup ON MasterDates.EDISID = PumpSetup.EDISID
	AND CleaningStack.Line = PumpSetup.Pump
	AND MasterDates.[Date] >= PumpSetup.ValidFrom
	AND (MasterDates.[Date] <= PumpSetup.ValidTo OR PumpSetup.ValidTo IS NULL)
	AND PumpSetup.EDISID = @EDISID
LEFT JOIN @PrimaryEDIS AS PrimaryEDIS ON PrimaryEDIS.EDISID = MasterDates.EDISID
LEFT JOIN SiteProductSpecifications AS Specs ON (PumpSetup.ProductID = Specs.ProductID AND PumpSetup.EDISID = Specs.EDISID)
LEFT JOIN SiteSpecifications ON SiteSpecifications.EDISID = Sites.EDISID
JOIN Products ON Products.[ID] = PumpSetup.ProductID
WHERE MasterDates.Date BETWEEN CAST(DATEADD(DAY, -(COALESCE(Specs.CleanDaysBeforeRed, SiteSpecifications.CleanDaysBeforeAmber, Products.LineCleanDaysBeforeAmber)), @FromDate) AS DATE) AND @ToDate
	AND (MasterDates.EDISID = @EDISID OR @EDISID IS NULL)
GROUP BY ISNULL(PrimaryEDIS.PrimaryEDISID, MasterDates.EDISID),
	PumpSetup.Pump,
	PumpSetup.ProductID,
	PumpSetup.LocationID,
	MasterDates.[Date]

-- Get BMS cleans (from WaterStack where volume >=4 pints)
-- Note that an iDraught site may previously have been BMS!!!
-- See how we join back to the iDraught cleans and exclude them, so we don't double-count
INSERT INTO #LineCleans
SELECT ISNULL(PrimaryEDIS.PrimaryEDISID, MasterDates.EDISID),
	PumpSetup.Pump,
	PumpSetup.ProductID,
	PumpSetup.LocationID,
	MasterDates.[Date]
FROM WaterStack
JOIN MasterDates ON MasterDates.ID = WaterStack.WaterID
LEFT JOIN @PrimaryEDIS AS PrimaryEDIS ON PrimaryEDIS.EDISID = MasterDates.EDISID
JOIN Sites ON Sites.EDISID = MasterDates.EDISID
JOIN PumpSetup ON MasterDates.EDISID = PumpSetup.EDISID
	AND WaterStack.Line = PumpSetup.Pump
	AND MasterDates.[Date] >= PumpSetup.ValidFrom
	AND (MasterDates.[Date] <= PumpSetup.ValidTo OR PumpSetup.ValidTo IS NULL)
	AND PumpSetup.EDISID = @EDISID
--LEFT JOIN #iDraughtStarts AS iDraughtTime ON iDraughtTime.EDISID = MasterDates.EDISID
LEFT JOIN SiteProductSpecifications AS Specs ON (PumpSetup.ProductID = Specs.ProductID AND PumpSetup.EDISID = Specs.EDISID)
LEFT JOIN SiteSpecifications ON SiteSpecifications.EDISID = Sites.EDISID
JOIN Products ON Products.[ID] = PumpSetup.ProductID
WHERE MasterDates.Date BETWEEN CAST(DATEADD(DAY, -(COALESCE(Specs.CleanDaysBeforeRed, SiteSpecifications.CleanDaysBeforeAmber,  Products.LineCleanDaysBeforeRed)), @FromDate) AS DATE) AND @ToDate
	AND (MasterDates.EDISID = @EDISID OR @EDISID IS NULL)
	AND MasterDates.[Date] NOT IN
	(
		SELECT CalendarDate
		FROM #iDraughtStarts AS iDraughtTimes
		JOIN Calendar ON Calendar.CalendarDate BETWEEN FirstPour AND LastPour
	)
GROUP BY ISNULL(PrimaryEDIS.PrimaryEDISID, MasterDates.EDISID),
      PumpSetup.Pump,
      PumpSetup.ProductID,
      PumpSetup.LocationID,
      MasterDates.[Date]
HAVING SUM(WaterStack.Volume) >= 4

SELECT Pump, 
	  SUM(Volume) AS TotalDispense,
	  SUM(CASE WHEN DATEDIFF(DAY, CleanDate, TradingDay) < DaysBeforeAmber THEN Volume ELSE 0 END) AS CleanDispense, 
	  SUM(CASE WHEN DATEDIFF(DAY, CleanDate, TradingDay) BETWEEN DaysBeforeAmber AND DaysBeforeRed - 1 THEN Volume ELSE 0 END) AS DueCleanDispense,
	  SUM(CASE WHEN DATEDIFF(DAY, CleanDate, TradingDay) >= DaysBeforeRed OR CleanDate IS NULL THEN Volume ELSE 0 END) AS OverdueCleanDispense,
	  DaysBeforeAmber AS CleaningAmberPercentTarget,
	  DaysBeforeRed AS CleaningRedPercentTarget
FROM (
		SELECT ISNULL(PrimaryEDIS.PrimaryEDISID, PeriodCacheTradingDispense.EDISID) AS EDISID,
			   PeriodCacheTradingDispense.TradingDay,
			   PeriodCacheTradingDispense.ProductID,
			   PeriodCacheTradingDispense.Pump,
			   COALESCE(SiteProductSpecifications.CleanDaysBeforeAmber, SiteSpecifications.CleanDaysBeforeAmber, Products.LineCleanDaysBeforeAmber) AS DaysBeforeAmber,
			   COALESCE(SiteProductSpecifications.CleanDaysBeforeRed, SiteSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed) AS DaysBeforeRed,
			   PeriodCacheTradingDispense.Volume,
			   MAX(LineCleans.[Date]) AS CleanDate
		FROM PeriodCacheTradingDispense	
		JOIN Products ON Products.[ID] = PeriodCacheTradingDispense.ProductID
		JOIN ProductCategories ON ProductCategories.ID = Products.CategoryID
			AND ProductCategories.IncludeInLineCleaning = 1
		LEFT JOIN @PrimaryEDIS AS PrimaryEDIS ON PrimaryEDIS.EDISID = PeriodCacheTradingDispense.EDISID
		LEFT JOIN #LineCleans AS LineCleans ON LineCleans.EDISID = PeriodCacheTradingDispense.EDISID
											AND LineCleans.[Date] <= PeriodCacheTradingDispense.TradingDay
											AND LineCleans.Pump = PeriodCacheTradingDispense.Pump
											AND LineCleans.ProductID = PeriodCacheTradingDispense.ProductID
											AND LineCleans.LocationID = PeriodCacheTradingDispense.LocationID
		LEFT JOIN SiteProductSpecifications ON (PeriodCacheTradingDispense.ProductID = SiteProductSpecifications.ProductID AND PeriodCacheTradingDispense.EDISID = SiteProductSpecifications.EDISID)
		LEFT JOIN SiteSpecifications ON PeriodCacheTradingDispense.EDISID = SiteSpecifications.EDISID
		JOIN Sites ON Sites.EDISID = PeriodCacheTradingDispense.EDISID
		INNER JOIN Owners ON Sites.OwnerID = Owners.ID
		--LEFT JOIN #iDraughtStarts AS iDraughtStarted ON iDraughtStarted.EDISID = Sites.EDISID
		JOIN @AllSitePumps AS AllSitePumps ON AllSitePumps.EDISID = Sites.EDISID
			AND AllSitePumps.PumpID = PeriodCacheTradingDispense.Pump
		WHERE ((DATEADD(dd, -DATEPART(dw, TradingDay) + 1, TradingDay) BETWEEN @FromDate AND @ToDate) OR (@FromDate IS NULL AND @ToDate IS NULL))
		AND Sites.EDISID = @EDISID
		AND Products.IsMetric = 0
		GROUP BY ISNULL(PrimaryEDIS.PrimaryEDISID, PeriodCacheTradingDispense.EDISID),
			   PeriodCacheTradingDispense.TradingDay,
			   PeriodCacheTradingDispense.ProductID,
			   PeriodCacheTradingDispense.Pump,
			   COALESCE(SiteProductSpecifications.CleanDaysBeforeAmber, SiteSpecifications.CleanDaysBeforeAmber, Products.LineCleanDaysBeforeAmber),
			   COALESCE(SiteProductSpecifications.CleanDaysBeforeRed, SiteSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed),
			   PeriodCacheTradingDispense.Volume,
			   Owners.CleaningAmberPercentTarget,
			   Owners.CleaningRedPercentTarget
) AS Dispense
GROUP BY Pump, DaysBeforeAmber, DaysBeforeRed
ORDER BY Pump

DROP TABLE #LineCleans
DROP TABLE #iDraughtStarts



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetOverdueLineCleaningDispensePump] TO PUBLIC
    AS [dbo];

