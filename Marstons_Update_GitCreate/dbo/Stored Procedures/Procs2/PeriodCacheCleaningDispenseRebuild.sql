CREATE PROCEDURE [dbo].[PeriodCacheCleaningDispenseRebuild]
(
      @FromDate		DATETIME,
      @ToDate		DATETIME,
      @EDISID		INT = NULL
)
AS

SET NOCOUNT ON;
SET DATEFIRST 1;

--Find secondary systems
IF OBJECT_ID('tempdb..#PrimaryEDIS') IS NOT NULL DROP TABLE #PrimaryEDIS;			--- RN addition
CREATE TABLE #PrimaryEDIS (ID SMALLINT IDENTITY(1,1) PRIMARY KEY, PrimaryEDISID INT NOT NULL, EDISID INT NOT NULL);   ----- DECLARE @PrimaryEDIS TABLE (PrimaryEDISID, EDISID) --- RN MOD ....indexed temp table with surrogate key 

--INSERT INTO @PrimaryEDIS(PrimaryEDISID,EDISID)
INSERT INTO #PrimaryEDIS(PrimaryEDISID,EDISID)
SELECT MAX(PrimaryEDISID) AS PrimaryEDISID, SiteGroupSites.EDISID
FROM(
	SELECT SiteGroupID, SiteGroupSites.EDISID AS PrimaryEDISID
	FROM SiteGroupSites 
	WHERE EXISTS (SELECT ID FROM SiteGroups WHERE TypeID = 1 AND ID = SiteGroupSites.SiteGroupID)    ----- WHERE SiteGroupID IN (SELECT ID FROM SiteGroups WHERE TypeID = 1)  --- RN MOD: EXIST is quicker
	AND IsPrimary = 1 AND (SiteGroupSites.EDISID = @EDISID OR @EDISID IS NULL)
	GROUP BY SiteGroupID, SiteGroupSites.EDISID
) AS PrimarySites
JOIN SiteGroupSites ON SiteGroupSites.SiteGroupID = PrimarySites.SiteGroupID
LEFT JOIN PumpSetup ON PumpSetup.EDISID = SiteGroupSites.EDISID
GROUP BY SiteGroupSites.EDISID;

-- Ensure the #PrimaryEDIS table also has all relevant single-cellar sites
INSERT INTO #PrimaryEDIS(PrimaryEDISID,EDISID)
--INSERT INTO #PrimaryEDIS(PrimaryEDISID,EDISID)
SELECT EDISID, EDISID
FROM Sites
WHERE NOT EXISTS (SELECT EDISID FROM #PrimaryEDIS AS PE WHERE PE.EDISID = Sites.EDISID)    ------- WHERE Sites.EDISID NOT IN (SELECT EDISID FROM #PrimaryEDIS)   --- RN MOD: EXIST is quicker
AND (Sites.EDISID = @EDISID OR @EDISID IS NULL);

-- Delete old stuff
DELETE
FROM PeriodCacheCleaningDispenseDaily
WHERE (Date BETWEEN @FromDate AND @ToDate)       ------ OR (@FromDate IS NULL AND @ToDate IS NULL))     --- RN: removed
AND (PeriodCacheCleaningDispenseDaily.EDISID = @EDISID OR @EDISID IS NULL);


IF OBJECT_ID('tempdb..#QualityDates') IS NOT NULL DROP TABLE #QualityDates;     --- RN addition
CREATE TABLE #QualityDates(ID INT IDENTITY(1,1) PRIMARY KEY, EDISID INT, [Date] DATETIME);     ----- CREATE TABLE #QualityDates(EDISID INT, [Date] DATE)  -- RN MOD ....indexed temp table with surrogate key     

INSERT INTO #QualityDates(EDISID,[Date]) 
SELECT EDISID, CalendarDate AS [Date]
FROM SiteQualityHistory
JOIN Calendar ON Calendar.CalendarDate BETWEEN QualityStart AND ISNULL(QualityEnd, CAST(GETDATE() AS DATE))
WHERE (EDISID = @EDISID OR @EDISID IS NULL);

-- Get iDraught cleans (from CleaningStack)
CREATE TABLE #LineCleans (ID INT IDENTITY(1,1) PRIMARY KEY, EDISID INT, Pump INT, ProductID INT, LocationID INT, [Date] DATE);     --- RN MOD ....indexed with  with surrogate key

DECLARE @ShowInUseLinesOnly AS INT = 1;

INSERT INTO #LineCleans(EDISID,Pump,ProductID,LocationID,[Date])
SELECT MasterDates.EDISID,
	PumpSetup.Pump,
	PumpSetup.ProductID,
	PumpSetup.LocationID,
	CONVERT(DATE,MasterDates.[Date])
FROM CleaningStack
JOIN MasterDates ON MasterDates.ID = CleaningStack.CleaningID
JOIN Sites ON Sites.EDISID = MasterDates.EDISID
JOIN PumpSetup ON MasterDates.EDISID = PumpSetup.EDISID
	AND CleaningStack.Line = PumpSetup.Pump
	AND MasterDates.[Date] >= PumpSetup.ValidFrom
	AND (MasterDates.[Date] <= PumpSetup.ValidTo OR PumpSetup.ValidTo IS NULL)
	AND (EXISTS (SELECT EDISID FROM #PrimaryEDIS AS P WHERE P.EDISID = PumpSetup.EDISID) OR @EDISID IS NULL)    --- RN MOD: EXISTS is faster.	   -----AND (PumpSetup.EDISID IN (SELECT EDISID FROM #PrimaryEDIS) OR @EDISID IS NULL)
JOIN #PrimaryEDIS AS PrimaryEDIS ON PrimaryEDIS.EDISID = MasterDates.EDISID
LEFT JOIN SiteProductSpecifications AS Specs ON (PumpSetup.ProductID = Specs.ProductID AND PumpSetup.EDISID = Specs.EDISID)
JOIN Products ON Products.[ID] = PumpSetup.ProductID
WHERE MasterDates.Date BETWEEN CAST(DATEADD(DAY, -(ISNULL(Specs.CleanDaysBeforeRed, Products.LineCleanDaysBeforeAmber)), @FromDate) AS DATETIME) AND @ToDate
GROUP BY
	MasterDates.EDISID,
	PumpSetup.Pump,
	PumpSetup.ProductID,
	PumpSetup.LocationID,
	MasterDates.[Date]

-- Get BMS cleans (from WaterStack where volume >=4 pints)
-- Note that an iDraught site may previously have been BMS!!!
INSERT INTO #LineCleans(EDISID,Pump,ProductID,LocationID,[Date])
SELECT MasterDates.EDISID,
	PumpSetup.Pump,
	PumpSetup.ProductID,
	PumpSetup.LocationID,
	CONVERT(DATE,MasterDates.[Date])
FROM WaterStack
JOIN MasterDates ON MasterDates.ID = WaterStack.WaterID
JOIN #PrimaryEDIS AS PrimaryEDIS ON PrimaryEDIS.EDISID = MasterDates.EDISID
JOIN Sites ON Sites.EDISID = MasterDates.EDISID
JOIN PumpSetup ON MasterDates.EDISID = PumpSetup.EDISID
	AND WaterStack.Line = PumpSetup.Pump
	AND MasterDates.[Date] >= PumpSetup.ValidFrom
	AND (MasterDates.[Date] <= PumpSetup.ValidTo OR PumpSetup.ValidTo IS NULL)
	AND (EXISTS (SELECT EDISID FROM #PrimaryEDIS AS P WHERE P.EDISID = PumpSetup.EDISID) OR @EDISID IS NULL)     --- RN MOD: EXISTS is faster. -------AND (PumpSetup.EDISID IN (SELECT EDISID FROM #PrimaryEDIS) OR @EDISID IS NULL)  
LEFT JOIN SiteProductSpecifications AS Specs ON (PumpSetup.ProductID = Specs.ProductID AND PumpSetup.EDISID = Specs.EDISID)
JOIN Products ON Products.[ID] = PumpSetup.ProductID
LEFT JOIN #QualityDates AS iDraughtTime ON iDraughtTime.EDISID = MasterDates.EDISID 
	AND iDraughtTime.[Date] = MasterDates.[Date]
WHERE MasterDates.Date BETWEEN CAST(DATEADD(DAY, -(ISNULL(Specs.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed)), @FromDate) AS DATETIME) AND @ToDate
	--AND ( (MasterDates.Date < iDraughtTime.FirstPour) OR (MasterDates.Date > iDraughtTime.LastPour) OR (iDraughtTime.FirstPour IS NULL AND iDraughtTime.LastPour IS NULL) )
	AND iDraughtTime.[Date] IS NULL
GROUP BY 
	MasterDates.EDISID,
      PumpSetup.Pump,
      PumpSetup.ProductID,
      PumpSetup.LocationID,
      MasterDates.[Date]
HAVING SUM(WaterStack.Volume) >= 4
OPTION (RECOMPILE)   --- RN addition: -- forces a plan recompile of this statement based on the update stats (on both temp tables and db tables that will naturally syncronously happen following bulk inserts/deletes).
;

-- Now we have all the line cleans
-- Note that PeriodCacheTradingDispense is NOT grouped up for multi-cellar!
-- #LineCleans EDISID is the real EDISID

--BUILD SPEED TABLE
INSERT INTO PeriodCacheCleaningDispenseDaily (EDISID, Date, CategoryID, TotalDispense, CleanDispense, DueCleanDispense, OverdueCleanDispense)
SELECT PrimaryEDIS.PrimaryEDISID,
	Date,
	CategoryID,
	SUM(Total),
	SUM(CleanQuantity),
	SUM(InToleranceQuantity),
	SUM(DirtyQuantity)
FROM (
	SELECT  EDISID,
			TradingDay AS Date,
			CategoryID, 
			SUM(Volume) AS Total,
			SUM(CASE WHEN DATEDIFF(DAY, CleanDate, TradingDay) < DaysBeforeAmber THEN Volume ELSE 0 END) AS CleanQuantity, 
			SUM(CASE WHEN DATEDIFF(DAY, CleanDate, TradingDay) BETWEEN DaysBeforeAmber AND DaysBeforeRed - 1 THEN Volume ELSE 0 END) AS InToleranceQuantity,
			SUM(CASE WHEN DATEDIFF(DAY, CleanDate, TradingDay) >= DaysBeforeRed OR CleanDate IS NULL THEN Volume ELSE 0 END) AS DirtyQuantity
	FROM (
		SELECT   PeriodCacheTradingDispense.EDISID,
				 PeriodCacheTradingDispense.TradingDay,
				 Products.CategoryID,
				 COALESCE(SiteProductSpecifications.CleanDaysBeforeAmber, SiteSpecifications.CleanDaysBeforeAmber, Products.LineCleanDaysBeforeAmber) AS DaysBeforeAmber,
				 COALESCE(SiteProductSpecifications.CleanDaysBeforeRed, SiteSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed) AS DaysBeforeRed,
				 PeriodCacheTradingDispense.Volume,
				 MAX(LineCleans.[Date]) AS CleanDate
		FROM PeriodCacheTradingDispense
		JOIN Products ON Products.[ID] = PeriodCacheTradingDispense.ProductID
		JOIN ProductCategories ON ProductCategories.ID = Products.CategoryID
		LEFT JOIN #LineCleans AS LineCleans ON LineCleans.EDISID = PeriodCacheTradingDispense.EDISID
															  AND LineCleans.[Date] <= PeriodCacheTradingDispense.TradingDay
															  AND LineCleans.Pump = PeriodCacheTradingDispense.Pump
															  AND LineCleans.ProductID = PeriodCacheTradingDispense.ProductID
															  AND LineCleans.LocationID = PeriodCacheTradingDispense.LocationID
		LEFT JOIN SiteProductSpecifications ON (PeriodCacheTradingDispense.ProductID = SiteProductSpecifications.ProductID AND PeriodCacheTradingDispense.EDISID = SiteProductSpecifications.EDISID)
		LEFT JOIN SiteSpecifications ON PeriodCacheTradingDispense.EDISID = SiteSpecifications.EDISID
		JOIN Sites ON Sites.EDISID = PeriodCacheTradingDispense.EDISID 
		WHERE(TradingDay BETWEEN DATEADD(dd, DATEPART(dw, 7-@FromDate)-1, @FromDate) AND DATEADD(dd, 7-DATEPART(dw, @ToDate), @ToDate))   
		-----WHERE (DATEADD(dd, -DATEPART(dw, TradingDay) + 1, TradingDay) BETWEEN @FromDate AND @ToDate) ---OR (@FromDate IS NULL AND @ToDate IS NULL))   --- RN removed & MOD: "IS NULL" parts not need. WHERE clause change to be SARG.
			AND (EXISTS (SELECT EDISID FROM #PrimaryEDIS AS P WHERE P.EDISID = Sites.EDISID) OR @EDISID IS NULL)   --- RN MOD: EXIST is quicker 	----AND (Sites.EDISID IN (SELECT EDISID FROM #PrimaryEDIS) OR @EDISID IS NULL)   
			AND Products.IsMetric = 0
			AND ProductCategories.IncludeInLineCleaning = 1
		GROUP BY PeriodCacheTradingDispense.EDISID,
				 PeriodCacheTradingDispense.TradingDay,
				 Products.CategoryID,
				 COALESCE(SiteProductSpecifications.CleanDaysBeforeAmber, SiteSpecifications.CleanDaysBeforeAmber, Products.LineCleanDaysBeforeAmber),
				 COALESCE(SiteProductSpecifications.CleanDaysBeforeRed, SiteSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed),
				 PeriodCacheTradingDispense.Volume
	) AS Dispense
	JOIN ProductCategories ON ProductCategories.ID = Dispense.CategoryID
	GROUP BY EDISID, TradingDay, CategoryID
) AS MultiCellar
JOIN #PrimaryEDIS AS PrimaryEDIS ON PrimaryEDIS.EDISID = MultiCellar.EDISID
--WHERE PrimaryEDIS.PrimaryEDISID IN (32,33) AND PrimaryEDIS.EDISID IN (32,33) AND CategoryID = 19
GROUP BY	PrimaryEDIS.PrimaryEDISID,
			Date,
			CategoryID
---ORDER BY Date    ---RN removed - not required
OPTION (RECOMPILE)   --RN addition: -- force a recompile following bulk inserts/deletes
;

DROP TABLE #PrimaryEDIS;
DROP TABLE #LineCleans;
DROP TABLE #QualityDates;

DELETE 
FROM PeriodCacheCleaningDispense
WHERE (Date BETWEEN @FromDate AND @ToDate)   ---OR (@FromDate IS NULL AND @ToDate IS NULL))   ---RN removed
	AND (PeriodCacheCleaningDispense.EDISID = @EDISID OR @EDISID IS NULL)

INSERT INTO PeriodCacheCleaningDispense (EDISID, Date, CategoryID, TotalDispense, CleanDispense, DueCleanDispense, OverdueCleanDispense)
SELECT	EDISID,
		DATEADD(dd, -DATEPART(dw, [Date]) + 1, [Date]),
		CategoryID,
		SUM(TotalDispense),
		SUM(CleanDispense),
		SUM(DueCleanDispense),
		SUM(OverdueCleanDispense)
FROM PeriodCacheCleaningDispenseDaily
WHERE([Date] BETWEEN DATEADD(dd, DATEPART(dw, 7-@FromDate)-1, @FromDate) AND DATEADD(dd, 7-DATEPART(dw, @ToDate), @ToDate))   --- RN removed & MOD: "IS NULL" parts not need. WHERE clause change to be SARG.       --- (DATEADD(dd, -DATEPART(dw, [Date]) + 1, [Date]) BETWEEN @FromDate AND @ToDate)  ---OR (@FromDate IS NULL AND @ToDate IS NULL))   
GROUP BY EDISID,
		DATEADD(dd, -DATEPART(dw, [Date]) + 1, [Date]),
		CategoryID;

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[PeriodCacheCleaningDispenseRebuild] TO PUBLIC
    AS [dbo];

