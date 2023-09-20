CREATE PROCEDURE [dbo].[GetWebSiteLineCleaningSetup]
(
	@EDISID		INT,
	@From		DATETIME,
	@To			DATETIME,
	@ShowInUseLinesOnly BIT = 1
)
AS

--DECLARE	@EDISID		INT = 808
----DECLARE	@From		DATETIME = '2016-10-03 00:00'
--DECLARE	@From		DATETIME = '2016-10-10 00:00'
--DECLARE	@To			DATETIME = '2016-11-06 00:00'
--DECLARE	@ShowInUseLinesOnly BIT = 1
 
SET NOCOUNT ON

DECLARE @WaterThreshold	FLOAT = 4
DECLARE @TradingDayBeginsAt INT = 5

DECLARE @Sites TABLE(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
DECLARE @SitePumpCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL PRIMARY KEY, PumpOffset INT NOT NULL)
DECLARE @PreviousCleans TABLE(EDISID INT NOT NULL, Pump INT NOT NULL, ProductID INT NOT NULL, LocationID INT NOT NULL, MaxCleaned DATETIME NOT NULL)
 
DECLARE @AllSitePumps TABLE(EDISID INT NOT NULL, SitePump INT NOT NULL,
			    	 PumpID INT NOT NULL, LocationID INT NOT NULL, ProductID INT NOT NULL,
			    	 ValidFrom DATETIME NOT NULL, ValidTo DATETIME NOT NULL,
                     DaysBeforeAmber INT NOT NULL, DaysBeforeRed INT NOT NULL,  
					 PreviousClean DATETIME NOT NULL, PreviousPumpClean DATETIME NOT NULL)

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


IF @IsIDraught = 1
BEGIN
	--PRINT 'iDraught'

	INSERT INTO @PreviousCleans
	(EDISID, Pump, ProductID, LocationID, MaxCleaned)
	SELECT MasterDates.EDISID,
		 PumpSetup.Pump,
		 PumpSetup.ProductID,
		 PumpSetup.LocationID,
		 MAX(CASE WHEN DATEPART(HOUR, CleaningStack.[Time]) < 5 THEN DATEADD(DAY, -1, MasterDates.[Date]) ELSE MasterDates.[Date] END)
	FROM CleaningStack
	JOIN MasterDates ON MasterDates.ID = CleaningStack.CleaningID
	JOIN PumpSetup ON MasterDates.EDISID = PumpSetup.EDISID
			AND CleaningStack.Line = PumpSetup.Pump
					 AND MasterDates.[Date] >= PumpSetup.ValidFrom
			AND (MasterDates.[Date] <= PumpSetup.ValidTo OR PumpSetup.ValidTo IS NULL)
	WHERE MasterDates.EDISID IN (SELECT EDISID FROM @Sites)
	AND MasterDates.[Date] <= @From
	AND MasterDates.[Date] >= @SiteOnline
	GROUP BY MasterDates.EDISID,
		PumpSetup.Pump,
		PumpSetup.ProductID,
		PumpSetup.LocationID
END
ELSE
BEGIN
	--PRINT 'BMS'
	/* Rewritten to more closely match the logic in GetWebSiteLineCleaningDispense */
	
	CREATE TABLE #TradingDispensed (EDISID INT NOT NULL, [DateAndTime] DATETIME NOT NULL, TradingDateAndTime DATETIME NOT NULL, ProductID INT NOT NULL, LocationID INT NOT NULL, Quantity FLOAT NOT NULL, SitePump INT NOT NULL, Pump INT NOT NULL)

	INSERT INTO #TradingDispensed
	(EDISID, [DateAndTime], TradingDateAndTime, ProductID, LocationID, Quantity, SitePump, Pump)
	SELECT MasterDates.EDISID,
		 CONVERT(VARCHAR(19), DATEADD(ss, DATEPART(ss, WaterStack.[Time]), DATEADD(mi, DATEPART(mi, WaterStack.[Time]), DATEADD(hh, DATEPART(hh, WaterStack.[Time]), MasterDates.[Date]))), 20),
		 DATEADD(Hour, DATEPART(Hour, WaterStack.[Time]), CASE WHEN DATEPART(Hour, WaterStack.[Time]) < 5 THEN DATEADD(Day, -1, MasterDates.[Date]) ELSE MasterDates.[Date] END) AS [TradingDateAndTime],
		 PumpSetup.ProductID,
		 PumpSetup.LocationID,
		 Volume,
		 Line,
		 Line + PumpOffset
	FROM WaterStack
	JOIN MasterDates ON MasterDates.[ID] = WaterStack.WaterID
	JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = MasterDates.EDISID
	JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = MasterDates.EDISID
	JOIN PumpSetup ON (PumpSetup.EDISID = MasterDates.EDISID
	      		AND PumpSetup.Pump = WaterStack.Line
	      		AND MasterDates.[Date] BETWEEN PumpSetup.ValidFrom AND ISNULL(PumpSetup.ValidTo, @To))
	JOIN Products ON Products.[ID] = PumpSetup.ProductID
	WHERE 
		MasterDates.[Date] <= @From
	AND MasterDates.[Date] >= @SiteOnline
	AND Products.IsWater = 0
	AND InUse = 1
	
	-- Delete the first few hours from the first day, as that is the previous 'trading day'
	DELETE
	FROM #TradingDispensed
	WHERE DateAndTime < DATEADD(hh,@TradingDayBeginsAt,@SiteOnline)
	
	-- Delete the last few hours from the 'last+1' day, as that is the next 'trading day'
	DELETE
	FROM #TradingDispensed
	WHERE DateAndTime >= DATEADD(hh,@TradingDayBeginsAt,DATEADD(dd,1,@From))
	
	INSERT INTO @PreviousCleans
		(EDISID, Pump, ProductID, LocationID, MaxCleaned)
	SELECT
		EDISID,
		Pump,
		ProductID,
		LocationID,
		MAX(TradingDay)
	FROM (
		SELECT
			EDISID,
			Pump,
			ProductID,
			LocationID,
			CAST(TradingDateAndTime AS DATE) AS [TradingDay],
			SUM(Quantity) AS [Quantity]
		FROM #TradingDispensed
		GROUP BY 
			EDISID,
			Pump,
			ProductID,
			LocationID,
			CAST(TradingDateAndTime AS DATE)
		HAVING SUM(Quantity) > @WaterThreshold
	) AS PotentialCleans
	GROUP BY 
			EDISID,
			Pump,
			ProductID,
			LocationID

	DROP TABLE #TradingDispensed
END

INSERT INTO @AllSitePumps (EDISID, SitePump, PumpID, LocationID, ProductID, ValidFrom, ValidTo, DaysBeforeAmber, DaysBeforeRed, PreviousClean, PreviousPumpClean)
SELECT	PumpSetup.EDISID, PumpSetup.Pump,
	PumpSetup.Pump+PumpOffset, PumpSetup.LocationID, PumpSetup.ProductID,
	PumpSetup.ValidFrom,
	ISNULL(PumpSetup.ValidTo, @To),
	COALESCE(SiteProductSpecifications.CleanDaysBeforeAmber, SiteSpecifications.CleanDaysBeforeAmber, Products.LineCleanDaysBeforeAmber),
	COALESCE(SiteProductSpecifications.CleanDaysBeforeRed, SiteSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed),
	ISNULL(PreviousCleans.MaxCleaned, 0) AS PreviousClean,
	ISNULL(PreviousPumpCleans.MaxCleaned, 0) AS PreviousPumpClean
FROM PumpSetup
JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = PumpSetup.EDISID
JOIN Products ON Products.[ID] = PumpSetup.ProductID
LEFT JOIN SiteProductSpecifications ON SiteProductSpecifications.EDISID = PumpSetup.EDISID
				   AND SiteProductSpecifications.ProductID = PumpSetup.ProductID
LEFT JOIN SiteSpecifications ON Sites.EDISID = SiteSpecifications.EDISID
LEFT JOIN @PreviousCleans AS PreviousCleans ON PreviousCleans.EDISID = PumpSetup.EDISID 
        					          AND PreviousCleans.Pump = PumpSetup.Pump 
					          AND PreviousCleans.ProductID = PumpSetup.ProductID
					          AND PreviousCleans.LocationID = PumpSetup.LocationID
LEFT JOIN 
(
	SELECT EDISID, Pump, MAX(MaxCleaned) AS MaxCleaned
	FROM @PreviousCleans
	GROUP BY EDISID, Pump 
) AS PreviousPumpCleans ON PreviousPumpCleans.EDISID = PumpSetup.EDISID 
        										AND PreviousPumpCleans.Pump = PumpSetup.Pump 
WHERE (ValidFrom <= @To)
AND (ISNULL(ValidTo, @To) >= @From)
AND (ISNULL(ValidTo, @To) >= @SiteOnline)
AND Products.IsWater = 0
AND (InUse = 1 OR @ShowInUseLinesOnly = 0)

SELECT	PumpSetup.EDISID,
		PumpSetup.PumpID AS Pump,
		Products.[Description] AS Product, 
        PumpSetup.LocationID, 
		Locations.[Description] AS Location,
		ProductDistributors.ShortName AS Distributor,
		CASE WHEN PumpSetup.ValidFrom < @SiteOnline THEN @SiteOnline ELSE PumpSetup.ValidFrom END AS ValidFrom,
		CASE WHEN ISNULL(PumpSetup.ValidTo, @To) < @SiteOnline THEN @SiteOnline ELSE ISNULL(PumpSetup.ValidTo, @To) END AS ValidTo,
		PumpSetup.DaysBeforeAmber,
		PumpSetup.DaysBeforeRed,
		PumpSetup.PreviousClean,
		PumpSetup.PreviousPumpClean,
		Products.IsMetric,
		PumpSetup.SitePump AS RealPumpID
FROM @AllSitePumps AS PumpSetup
JOIN Products ON Products.[ID] = PumpSetup.ProductID
JOIN ProductDistributors ON ProductDistributors.[ID] = Products.DistributorID
JOIN Locations ON Locations.[ID] = PumpSetup.LocationID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteLineCleaningSetup] TO PUBLIC
    AS [dbo];

