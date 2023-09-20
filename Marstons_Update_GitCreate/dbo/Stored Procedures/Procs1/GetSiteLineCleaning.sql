CREATE PROCEDURE [dbo].[GetSiteLineCleaning] 

	@EDISID AS INT,
	@From AS DATETIME,
	@To AS DATETIME,
	@PumpID AS INT = NULL,
	@VolumeLimiter AS INT = 4

AS

SET NOCOUNT ON

CREATE TABLE #CombinedStacks (EDISID INT, [DateAndTime] DATETIME, TradingDateAndTime DATETIME, TradingDate DATETIME, Line INT, CleaningVol FLOAT DEFAULT 0, WaterVol FLOAT DEFAULT 0)
CREATE NONCLUSTERED INDEX IDX_EDISID ON #CombinedStacks (EDISID)
CREATE NONCLUSTERED INDEX IDX_DateTime ON #CombinedStacks ([DateAndTime])
DECLARE @Results TABLE(EDISID INT, TradingDate DATETIME, Line INT, CleaningVol FLOAT DEFAULT 0, WaterVol FLOAT DEFAULT 0)

DECLARE @TradingDayBeginsAt INT
SET @TradingDayBeginsAt = 5

DECLARE @SiteOnline DATETIME

DECLARE @Sites TABLE(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
DECLARE @SiteGroupID INT
DECLARE @SitePumpCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL PRIMARY KEY, PumpOffset INT NOT NULL)
DECLARE @AllSitePumps TABLE(PumpID INT NOT NULL, LocationID INT NOT NULL, ProductID INT NOT NULL)

-- Find site online
SELECT @SiteOnline = SiteOnline
FROM Sites
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
SELECT MainCounts.EDISID, COALESCE(QuaternaryCounts.MaxPump+TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, SecondaryCounts.MaxPump, 0)
FROM @SitePumpCounts AS MainCounts
LEFT JOIN @SitePumpCounts AS SecondaryCounts ON SecondaryCounts.Counter+1 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS TertiaryCounts ON TertiaryCounts.Counter+2 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS QuaternaryCounts ON QuaternaryCounts.Counter+3 = MainCounts.Counter

--SELECT * FROM @SitePumpOffsets

INSERT INTO @AllSitePumps (PumpID, LocationID, ProductID)
SELECT Pump+PumpOffset, LocationID, PumpSetup.ProductID
FROM PumpSetup
JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = PumpSetup.EDISID
JOIN Products ON Products.[ID] = PumpSetup.ProductID
LEFT JOIN SiteProductSpecifications ON Products.ID = SiteProductSpecifications.ProductID AND PumpSetup.EDISID = SiteProductSpecifications.EDISID
WHERE (ValidFrom <= @To)
AND (ISNULL(ValidTo, @To) >= @From)
AND (ISNULL(ValidTo, @To) >= @SiteOnline)
AND PumpSetup.InUse = 1

--SELECT * FROM @AllSitePumps

INSERT INTO #CombinedStacks (EDISID, [DateAndTime], TradingDateAndTime, TradingDate, Line, WaterVol)
SELECT	MasterDates.EDISID, 
		DATEADD(Hour, DATEPART(Hour, WaterStack.Time), MasterDates.[Date]), 
		DATEADD(Second, DATEPART(Second, WaterStack.Time), DATEADD(Minute, DATEPART(Minute, WaterStack.Time), DATEADD(Hour, DATEPART(Hour, WaterStack.Time), CAST(CONVERT(VARCHAR(10), DATEADD(hh,@TradingDayBeginsAt*-1,CONVERT(VARCHAR(19), DATEADD(ss, DATEPART(ss, WaterStack.Time), DATEADD(mi, DATEPART(mi, WaterStack.Time), DATEADD(hh, DATEPART(hh, WaterStack.Time), MasterDates.[Date]))), 20)), 12) AS DATETIME)))),
		CONVERT(VARCHAR(10), DATEADD(Second, DATEPART(Second, WaterStack.Time), DATEADD(Minute, DATEPART(Minute, WaterStack.Time), DATEADD(Hour, DATEPART(Hour, WaterStack.Time), CAST(CONVERT(VARCHAR(10), DATEADD(hh,@TradingDayBeginsAt*-1,CONVERT(VARCHAR(19), DATEADD(ss, DATEPART(ss, WaterStack.Time), DATEADD(mi, DATEPART(mi, WaterStack.Time), DATEADD(hh, DATEPART(hh, WaterStack.Time), MasterDates.[Date]))), 20)), 12) AS DATETIME)))), 120),
		WaterStack.Line, 
		WaterStack.Volume
FROM WaterStack
JOIN MasterDates ON MasterDates.ID = WaterStack.WaterID
WHERE MasterDates.EDISID IN (SELECT EDISID FROM @Sites)
--AND Volume > @VolumeLimiter
AND MasterDates.[Date] BETWEEN @From AND DATEADD(dd,1,@To)
AND MasterDates.[Date] >= @SiteOnline

INSERT INTO #CombinedStacks (EDISID, [DateAndTime], TradingDateAndTime, TradingDate, Line, CleaningVol)
SELECT	MasterDates.EDISID,
		DATEADD(Hour, DATEPART(Hour, CleaningStack.Time), MasterDates.[Date]), 
		DATEADD(Second, DATEPART(Second, CleaningStack.Time), DATEADD(Minute, DATEPART(Minute, CleaningStack.Time), DATEADD(Hour, DATEPART(Hour, CleaningStack.Time), CAST(CONVERT(VARCHAR(10), DATEADD(hh,@TradingDayBeginsAt*-1,CONVERT(VARCHAR(19), DATEADD(ss, DATEPART(ss, CleaningStack.Time), DATEADD(mi, DATEPART(mi, CleaningStack.Time), DATEADD(hh, DATEPART(hh, CleaningStack.Time), MasterDates.[Date]))), 20)), 12) AS DATETIME)))),
		CONVERT(VARCHAR(10), DATEADD(Second, DATEPART(Second, CleaningStack.Time), DATEADD(Minute, DATEPART(Minute, CleaningStack.Time), DATEADD(Hour, DATEPART(Hour, CleaningStack.Time), CAST(CONVERT(VARCHAR(10), DATEADD(hh,@TradingDayBeginsAt*-1,CONVERT(VARCHAR(19), DATEADD(ss, DATEPART(ss, CleaningStack.Time), DATEADD(mi, DATEPART(mi, CleaningStack.Time), DATEADD(hh, DATEPART(hh, CleaningStack.Time), MasterDates.[Date]))), 20)), 12) AS DATETIME)))), 120),
		CleaningStack.Line, 
		CleaningStack.Volume
FROM CleaningStack
JOIN MasterDates ON MasterDates.ID = CleaningStack.CleaningID
WHERE MasterDates.EDISID IN (SELECT EDISID FROM @Sites)
AND MasterDates.[Date] BETWEEN @From AND DATEADD(dd,1,@To)
AND MasterDates.[Date] >= @SiteOnline

--SELECT * FROM #CombinedStacks

-- Delete the first few hours from the first day, as that is the previous 'trading day'
DELETE
FROM #CombinedStacks
WHERE [DateAndTime] < DATEADD(hh,@TradingDayBeginsAt,@From)

-- Delete the last few hours from the 'last+1' day, as that is the next 'trading day'
DELETE
FROM #CombinedStacks
WHERE [DateAndTime] >= DATEADD(hh,@TradingDayBeginsAt,DATEADD(dd,1,@To))

--SELECT * FROM #CombinedStacks

--SELECT EDISID, Line FROM #CombinedStacks
--WHERE EDISID = @EDISID
--GROUP BY EDISID, Line

INSERT INTO @Results (EDISID, TradingDate, Line, CleaningVol, WaterVol)
SELECT #CombinedStacks.EDISID, TradingDate, Line + PumpOffset,
	SUM(CleaningVol) AS CleaningVol,
	SUM(WaterVol) AS WaterVol
FROM #CombinedStacks
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = #CombinedStacks.EDISID
JOIN @AllSitePumps AS AllSitePumps ON AllSitePumps.PumpID = #CombinedStacks.Line + PumpOffset
GROUP BY #CombinedStacks.EDISID, TradingDate, Line + PumpOffset
HAVING SUM(CleaningVol) > 0
OR SUM(WaterVol) >= @VolumeLimiter

--INSERT INTO @Results (EDISID, TradingDate, Line, CleaningVol, WaterVol)
--SELECT #CombinedStacks.EDISID, TradingDate, Line + PumpOffset,
--	SUM(CleaningVol) AS CleaningVol,
--	SUM(WaterVol) AS WaterVol
--FROM #CombinedStacks
--JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = #CombinedStacks.EDISID
--GROUP BY #CombinedStacks.EDISID, TradingDate, Line + PumpOffset
--HAVING SUM(WaterVol) = 0

DROP TABLE #CombinedStacks

IF @PumpID IS NOT NULL
BEGIN
  DELETE FROM @Results WHERE Line <> @PumpID
END

SELECT EDISID, TradingDate, Line, CleaningVol, WaterVol FROM @Results


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteLineCleaning] TO PUBLIC
    AS [dbo];

