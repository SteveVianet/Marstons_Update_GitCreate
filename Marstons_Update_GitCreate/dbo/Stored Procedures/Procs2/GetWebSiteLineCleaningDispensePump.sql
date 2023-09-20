
CREATE PROCEDURE [dbo].[GetWebSiteLineCleaningDispensePump]
	@EDISID		INT,
	@FromDate	DATETIME,
	@ToDate		DATETIME,
	@ShowInUseLinesOnly BIT = 1
AS

/*
DECLARE	@EDISID		INT = 2062
DECLARE @FromDate	DATETIME = '2014-09-08 00:00:00.000'
DECLARE	@ToDate		DATETIME = '2014-10-05 00:00:00.000'
DECLARE	@ShowInUseLinesOnly BIT = 1
*/

DECLARE		@InternalEDISID		INT = @EDISID
DECLARE		@InternalFromDate	DATETIME = @FromDate
DECLARE		@InternalToDate		DATETIME = @ToDate
DECLARE		@InternalShowInUseLinesOnly BIT = @ShowInUseLinesOnly

SET NOCOUNT ON;

DECLARE @First AS INT
SET @First = 1
SET DATEFIRST @First

CREATE TABLE #TradingDispense(EDISID INT, TradingDay DATETIME, ProductID INT, Pump INT, LocationID INT, Volume FLOAT)
CREATE TABLE #LineCleans (EDISID INT, Pump INT, ProductID INT, LocationID INT, [Date] DATETIME)

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
WHERE EDISID = @InternalEDISID

-- Find out which EDISIDs are relevant (plough through SiteGroups)
INSERT INTO @Sites
(EDISID)
SELECT EDISID
FROM Sites
WHERE EDISID = @InternalEDISID
 
SELECT @SiteGroupID = SiteGroupID
FROM SiteGroupSites
JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
WHERE TypeID = 1 AND EDISID = @InternalEDISID
 
INSERT INTO @Sites (EDISID)
SELECT SiteGroupSites.EDISID
FROM SiteGroupSites
JOIN Sites ON Sites.EDISID = SiteGroupSites.EDISID
WHERE SiteGroupSites.SiteGroupID = @SiteGroupID AND SiteGroupSites.EDISID <> @InternalEDISID

-- Get pumps for secondary sites (note that 1st EDISID IN @Sites is primary site)
INSERT INTO @SitePumpCounts (EDISID, MaxPump)
SELECT PumpSetup.EDISID, MAX(Pump)
FROM PumpSetup
JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
WHERE (ValidFrom <= @InternalToDate)
AND (ISNULL(ValidTo, @InternalToDate) >= @InternalFromDate)
AND (ISNULL(ValidTo, @InternalToDate) >= @SiteOnline)
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
	ISNULL(PumpSetup.ValidTo, @InternalToDate),
	COALESCE(SiteProductSpecifications.CleanDaysBeforeAmber, SiteSpecifications.CleanDaysBeforeAmber, Products.LineCleanDaysBeforeAmber),
	COALESCE(SiteProductSpecifications.CleanDaysBeforeRed, SiteSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed)
FROM PumpSetup
JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = PumpSetup.EDISID
JOIN Products ON Products.[ID] = PumpSetup.ProductID
LEFT JOIN SiteProductSpecifications ON SiteProductSpecifications.EDISID = PumpSetup.EDISID
				   AND SiteProductSpecifications.ProductID = PumpSetup.ProductID
LEFT JOIN SiteSpecifications ON Sites.EDISID = SiteSpecifications.EDISID
WHERE (ValidFrom <= @InternalToDate)
AND (ISNULL(ValidTo, @InternalToDate) >= @InternalFromDate)
AND (ISNULL(ValidTo, @InternalToDate) >= @SiteOnline)
AND Products.IsWater = 0
AND (InUse = 1 OR @InternalShowInUseLinesOnly = 0)

--Merge secondary systems
DECLARE @PrimaryEDIS TABLE(PrimaryEDISID INT NOT NULL, EDISID INT NOT NULL)
INSERT INTO @PrimaryEDIS
SELECT MAX(PrimaryEDISID) AS PrimaryEDISID, SiteGroupSites.EDISID
FROM(
	SELECT SiteGroupID, SiteGroupSites.EDISID AS PrimaryEDISID
	FROM SiteGroupSites 
	WHERE SiteGroupID IN (SELECT ID FROM SiteGroups WHERE TypeID = 1)
	AND EDISID IN (SELECT EDISID FROM @Sites)
	AND IsPrimary = 1
	GROUP BY SiteGroupID, SiteGroupSites.EDISID
) AS PrimarySites
JOIN SiteGroupSites ON SiteGroupSites.SiteGroupID = PrimarySites.SiteGroupID
LEFT JOIN PumpSetup ON PumpSetup.EDISID = SiteGroupSites.EDISID
GROUP BY SiteGroupSites.EDISID
ORDER BY PrimaryEDISID


-- Massive issue here:
-- It's too slow trying to get the iD data separate from BMS to cope with cross-over
-- So we don't bother.
-- We have a bit of a nasty simplification here (for now)


-- Get iDraught cleans (from CleaningStack)
IF @IsIDraught = 1
BEGIN
	
	INSERT INTO #LineCleans
	SELECT ISNULL(PrimaryEDIS.PrimaryEDISID, MasterDates.EDISID),
		PumpSetup.PumpID,
		PumpSetup.ProductID,
		PumpSetup.LocationID,
		MasterDates.[Date]
	FROM CleaningStack
	JOIN MasterDates ON MasterDates.ID = CleaningStack.CleaningID
	JOIN @Sites AS Sites ON Sites.EDISID = MasterDates.EDISID
	JOIN @AllSitePumps AS PumpSetup ON MasterDates.EDISID = PumpSetup.EDISID
		AND CleaningStack.Line = PumpSetup.SitePump
		AND MasterDates.[Date] >= PumpSetup.ValidFrom
		AND (MasterDates.[Date] <= PumpSetup.ValidTo OR PumpSetup.ValidTo IS NULL)
		AND ((PumpSetup.EDISID = Sites.EDISID) OR @InternalEDISID IS NULL)
	LEFT JOIN @PrimaryEDIS AS PrimaryEDIS ON PrimaryEDIS.EDISID = MasterDates.EDISID
	LEFT JOIN SiteProductSpecifications AS Specs ON (PumpSetup.ProductID = Specs.ProductID AND PumpSetup.EDISID = Specs.EDISID)
    LEFT JOIN SiteSpecifications ON SiteSpecifications.EDISID = Sites.EDISID
	JOIN Products ON Products.[ID] = PumpSetup.ProductID
	WHERE (MasterDates.Date BETWEEN CAST(DATEADD(DAY, -(COALESCE(Specs.CleanDaysBeforeRed, SiteSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed)), @InternalFromDate) AS DATE) AND @InternalToDate)
	GROUP BY ISNULL(PrimaryEDIS.PrimaryEDISID, MasterDates.EDISID),
		PumpSetup.PumpID,
		PumpSetup.ProductID,
		PumpSetup.LocationID,
		MasterDates.[Date]
END

--SELECT * FROM #LineCleans

--DECLARE @PourFrom DATETIME
--SELECT @PourFrom = DATEADD(Day,-MAX(DaysBeforeAmber), @InternalFromDate) FROM @AllSitePumps

-- Get BMS cleans (from WaterStack where volume >=4 pints)
-- Note that an iDraught site may previously have been BMS!!!
-- See how we join back to the iDraught cleans and exclude them, so we don't double-count

IF @IsIDraught = 0
BEGIN
	INSERT INTO #LineCleans
	SELECT ISNULL(PrimaryEDIS.PrimaryEDISID, MasterDates.EDISID),
		  PumpSetup.PumpID,
		  PumpSetup.ProductID,
		  PumpSetup.LocationID,
		  MasterDates.[Date]
	FROM WaterStack
	JOIN MasterDates ON MasterDates.ID = WaterStack.WaterID
	LEFT JOIN @PrimaryEDIS AS PrimaryEDIS ON PrimaryEDIS.EDISID = MasterDates.EDISID
	JOIN @Sites AS Sites ON Sites.EDISID = MasterDates.EDISID
	JOIN @AllSitePumps AS PumpSetup ON MasterDates.EDISID = PumpSetup.EDISID
		  AND WaterStack.Line = PumpSetup.SitePump
		  AND MasterDates.[Date] >= PumpSetup.ValidFrom
		  AND (MasterDates.[Date] <= PumpSetup.ValidTo OR PumpSetup.ValidTo IS NULL)
		  AND (PumpSetup.EDISID = Sites.EDISID OR @InternalEDISID IS NULL)
	LEFT JOIN SiteProductSpecifications AS Specs ON (PumpSetup.ProductID = Specs.ProductID AND PumpSetup.EDISID = Specs.EDISID)
    LEFT JOIN SiteSpecifications ON SiteSpecifications.EDISID = Sites.EDISID
	JOIN Products ON Products.[ID] = PumpSetup.ProductID
	/*
	LEFT JOIN (
		SELECT EDISID, MIN(TradingDay) AS FirstPour, MAX(TradingDay) AS LastPour
		FROM DispenseActions
		WHERE EDISID = @InternalEDISID
		AND TradingDay BETWEEN @PourFrom AND @InternalToDate
		GROUP BY EDISID
	) AS iDraughtTime ON iDraughtTime.EDISID = MasterDates.EDISID
	*/
	WHERE (MasterDates.Date BETWEEN CAST(DATEADD(DAY, -(COALESCE(Specs.CleanDaysBeforeRed, SiteSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed)), @InternalFromDate) AS DATE) AND @InternalToDate)
	/*
		  AND ( (MasterDates.Date < iDraughtTime.FirstPour)
		   OR (MasterDates.Date > iDraughtTime.LastPour) 
		   OR (iDraughtTime.FirstPour IS NULL AND iDraughtTime.LastPour IS NULL) )
	*/
			/*
		  AND (
			  not (MasterDates.Date BETWEEN iDraughtTime.FirstPour AND iDraughtTime.LastPour)
				OR (iDraughtTime.FirstPour IS NULL AND iDraughtTime.LastPour IS NULL)
		  )*/
	GROUP BY 
		  ISNULL(PrimaryEDIS.PrimaryEDISID, MasterDates.EDISID),
		  PumpSetup.PumpID,
		  PumpSetup.ProductID,
		  PumpSetup.LocationID,
		  MasterDates.[Date]
	HAVING SUM(WaterStack.Volume) >= 4
END

--SELECT * FROM #LineCleans

-- Added for Exception code in Data Import Service. If less than a week, get data straight from DispenseActions as possibility
-- of missing data in the cache tables otherwise due to constant refreshing
IF DATEDIFF(WEEK, @InternalFromDate, @InternalToDate) < 1
BEGIN
	INSERT INTO #TradingDispense
	SELECT	ISNULL(PrimaryEDIS.PrimaryEDISID, DispenseActions.EDISID), 
			DispenseActions.TradingDay,
			PumpSetup.ProductID,
			PumpSetup.PumpID,
			PumpSetup.LocationID,	
			SUM(DispenseActions.Pints) AS Volume
	FROM DispenseActions
	JOIN @Sites AS Sites ON Sites.EDISID = DispenseActions.EDISID
	LEFT JOIN @PrimaryEDIS AS PrimaryEDIS ON PrimaryEDIS.EDISID = DispenseActions.EDISID
	JOIN @AllSitePumps AS PumpSetup ON Sites.EDISID = PumpSetup.EDISID
								  AND DispenseActions.Pump = PumpSetup.SitePump
								  AND TradingDay >= PumpSetup.ValidFrom
								  AND (TradingDay <= PumpSetup.ValidTo OR PumpSetup.ValidTo IS NULL)
								  AND (PumpSetup.EDISID = Sites.EDISID OR @InternalEDISID IS NULL)
	  WHERE LiquidType = 2
	  AND ((TradingDay BETWEEN @InternalFromDate AND @InternalToDate) OR (@InternalFromDate IS NULL AND @InternalToDate IS NULL))
	GROUP BY	ISNULL(PrimaryEDIS.PrimaryEDISID, DispenseActions.EDISID),
				DispenseActions.TradingDay,
				PumpSetup.ProductID,
				PumpSetup.PumpID,
				PumpSetup.LocationID

END
ELSE
BEGIN
	INSERT INTO #TradingDispense
	SELECT ISNULL(PrimaryEDIS.PrimaryEDISID, PeriodCacheTradingDispense.EDISID),
		   PeriodCacheTradingDispense.TradingDay,
		   PumpSetup.ProductID,
		   PumpSetup.PumpID,
		   PumpSetup.LocationID,
		   SUM(PeriodCacheTradingDispense.Volume) AS Volume
	FROM PeriodCacheTradingDispense
	JOIN @Sites AS Sites ON Sites.EDISID = PeriodCacheTradingDispense.EDISID
	LEFT JOIN @PrimaryEDIS AS PrimaryEDIS ON PrimaryEDIS.EDISID = PeriodCacheTradingDispense.EDISID
	JOIN @AllSitePumps AS PumpSetup ON Sites.EDISID = PumpSetup.EDISID
								  AND PeriodCacheTradingDispense.Pump = PumpSetup.SitePump
								  AND TradingDay >= PumpSetup.ValidFrom
								  AND (TradingDay <= PumpSetup.ValidTo OR PumpSetup.ValidTo IS NULL)
								  AND (PumpSetup.EDISID = Sites.EDISID OR @InternalEDISID IS NULL)
	WHERE ((TradingDay BETWEEN @InternalFromDate AND @InternalToDate) OR (@InternalFromDate IS NULL AND @InternalToDate IS NULL))
	AND PeriodCacheTradingDispense.EDISID IN (SELECT EDISID FROM @Sites)
	GROUP BY ISNULL(PrimaryEDIS.PrimaryEDISID, PeriodCacheTradingDispense.EDISID),
		   PeriodCacheTradingDispense.TradingDay,
		   PumpSetup.ProductID,
		   PumpSetup.PumpID,
		   PumpSetup.LocationID

END


SELECT Pump,
	  Product,
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
			   Products.[Description] AS Product,
			   PeriodCacheTradingDispense.Pump,
			   COALESCE(SiteProductSpecifications.CleanDaysBeforeAmber, SiteSpecifications.CleanDaysBeforeAmber, Products.LineCleanDaysBeforeAmber) AS DaysBeforeAmber,
			   COALESCE(SiteProductSpecifications.CleanDaysBeforeRed, SiteSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed) AS DaysBeforeRed,
			   PeriodCacheTradingDispense.Volume,
			   MAX(LineCleans.[Date]) AS CleanDate
		FROM #TradingDispense AS PeriodCacheTradingDispense	
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
		JOIN Sites ON Sites.EDISID = PeriodCacheTradingDispense.EDISID
        LEFT JOIN SiteSpecifications ON Sites.EDISID = SiteSpecifications.EDISID
		INNER JOIN Owners ON Sites.OwnerID = Owners.ID
		JOIN @AllSitePumps AS AllSitePumps ON --AllSitePumps.EDISID = Sites.EDISID AND
			 AllSitePumps.PumpID = PeriodCacheTradingDispense.Pump
		WHERE ((TradingDay BETWEEN @InternalFromDate AND @InternalToDate) OR (@InternalFromDate IS NULL AND @InternalToDate IS NULL))
			AND Sites.EDISID IN (SELECT EDISID FROM @Sites)
			AND Products.IsMetric = 0
			AND PeriodCacheTradingDispense.TradingDay >= Sites.SiteOnline
		GROUP BY ISNULL(PrimaryEDIS.PrimaryEDISID, PeriodCacheTradingDispense.EDISID),
			   PeriodCacheTradingDispense.TradingDay,
			   PeriodCacheTradingDispense.ProductID,
			   Products.[Description],
			   PeriodCacheTradingDispense.Pump,
			   COALESCE(SiteProductSpecifications.CleanDaysBeforeAmber, SiteSpecifications.CleanDaysBeforeAmber, Products.LineCleanDaysBeforeAmber),
			   COALESCE(SiteProductSpecifications.CleanDaysBeforeRed, SiteSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed),
			   PeriodCacheTradingDispense.Volume,
			   Owners.CleaningAmberPercentTarget,
			   Owners.CleaningRedPercentTarget
) AS Dispense
GROUP BY Pump, Product, DaysBeforeAmber, DaysBeforeRed
ORDER BY Pump

DROP TABLE #LineCleans
DROP TABLE #TradingDispense



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteLineCleaningDispensePump] TO PUBLIC
    AS [dbo];

