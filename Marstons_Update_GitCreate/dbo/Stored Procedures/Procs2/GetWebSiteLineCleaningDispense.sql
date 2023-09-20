CREATE PROCEDURE [dbo].[GetWebSiteLineCleaningDispense]
(
	@EDISID		INT,
	@From			DATETIME,
	@To			DATETIME,
	@WaterThreshold	FLOAT
)
AS

SET NOCOUNT ON

CREATE TABLE #Sites (EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
CREATE TABLE #SitePumpCounts (Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
CREATE TABLE #SitePumpOffsets (EDISID INT NOT NULL PRIMARY KEY, PumpOffset INT NOT NULL)

DECLARE @TradingDayBeginsAt INT
SET @TradingDayBeginsAt = 5

DECLARE @CleanerLiquidType INT
SET @CleanerLiquidType = 3

DECLARE @WaterLiquidType INT
SET @WaterLiquidType = 1

DECLARE @SiteGroupID INT
DECLARE @DateCount DATETIME
DECLARE @SiteOnline DATETIME
DECLARE @IsBQM BIT

SELECT @IsBQM = Quality, @SiteOnline = SiteOnline
FROM dbo.Sites
WHERE EDISID = @EDISID

-- Find out which EDISIDs are relevant (plough through SiteGroups)
INSERT INTO #Sites
(EDISID)
SELECT EDISID
FROM Sites
WHERE EDISID = @EDISID
 
SELECT @SiteGroupID = SiteGroupID
FROM SiteGroupSites
JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
WHERE TypeID = 1 AND EDISID = @EDISID
 
INSERT INTO #Sites (EDISID)
SELECT SiteGroupSites.EDISID
FROM SiteGroupSites
JOIN Sites ON Sites.EDISID = SiteGroupSites.EDISID
WHERE SiteGroupSites.SiteGroupID = @SiteGroupID AND SiteGroupSites.EDISID <> @EDISID
 
-- Get pumps for secondary sites (note that 1st EDISID IN #Sites is primary site)
INSERT INTO #SitePumpCounts (EDISID, MaxPump)
SELECT PumpSetup.EDISID, MAX(Pump)
FROM PumpSetup
JOIN #Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
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

IF @IsBQM = 1
BEGIN
	SET @WaterThreshold = 0		-- this is DMS nonsense, so we disable it here

	SELECT TradingDay AS [Date],
		   Pump + PumpOffset AS SitePump,
		   Products.[Description] AS Product,
		   ISNULL(SUM(CASE WHEN LiquidType = @CleanerLiquidType THEN DispenseActions.Pints END), 0) AS CleaningTotal,
		   ISNULL(SUM(CASE WHEN LiquidType = @WaterLiquidType THEN DispenseActions.Pints END), 0) AS WaterTotal
	FROM DispenseActions
	JOIN Products ON Products.[ID] = DispenseActions.Product
	JOIN #SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = DispenseActions.EDISID
	WHERE TradingDay BETWEEN @From AND @To
	AND TradingDay >= @SiteOnline
	AND DispenseActions.EDISID IN (SELECT EDISID FROM #Sites)
	AND LiquidType IN (@CleanerLiquidType,@WaterLiquidType)		
	GROUP BY TradingDay,
			  Pump + PumpOffset,
			  Products.[Description]
	HAVING ( SUM(CASE WHEN LiquidType = @CleanerLiquidType THEN DispenseActions.Pints END) > @WaterThreshold )
	OR ( SUM(CASE WHEN LiquidType = @WaterLiquidType THEN DispenseActions.Pints END) > @WaterThreshold )
	ORDER BY TradingDay, 
		 SitePump
	
	
END
ELSE
BEGIN

	CREATE TABLE #TradingDispensed (EDISID INT NOT NULL, [DateAndTime] DATETIME NOT NULL, TradingDateAndTime DATETIME NOT NULL, Product VARCHAR(50) NOT NULL, Quantity FLOAT NOT NULL, SitePump INT NOT NULL, Pump INT NOT NULL, LiquidType INT NOT NULL)

	INSERT INTO #TradingDispensed
	(EDISID, [DateAndTime], TradingDateAndTime, Product, Quantity, SitePump, Pump, LiquidType)
	SELECT MasterDates.EDISID,
		 CONVERT(VARCHAR(19), DATEADD(ss, DATEPART(ss, WaterStack.[Time]), DATEADD(mi, DATEPART(mi, WaterStack.[Time]), DATEADD(hh, DATEPART(hh, WaterStack.[Time]), MasterDates.[Date]))), 20),
		 DATEADD(Hour, DATEPART(Hour, WaterStack.[Time]), CASE WHEN DATEPART(Hour, WaterStack.[Time]) < 5 THEN DATEADD(Day, -1, MasterDates.[Date]) ELSE MasterDates.[Date] END) AS [TradingDateAndTime],
		 Products.Description,
		 Volume,
		 Line,
		 Line + PumpOffset,
		 @CleanerLiquidType
	FROM WaterStack
	JOIN MasterDates ON MasterDates.[ID] = WaterStack.WaterID
	JOIN #SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = MasterDates.EDISID
	JOIN #Sites AS RelevantSites ON RelevantSites.EDISID = MasterDates.EDISID
	JOIN PumpSetup ON (PumpSetup.EDISID = MasterDates.EDISID
	      		AND PumpSetup.Pump = WaterStack.Line
	      		AND MasterDates.[Date] BETWEEN PumpSetup.ValidFrom AND ISNULL(PumpSetup.ValidTo, @To))
	JOIN Products ON Products.[ID] = PumpSetup.ProductID
	WHERE MasterDates.[Date] BETWEEN @From AND DATEADD(dd,1,@To)
	AND MasterDates.[Date] >= @SiteOnline
	AND Products.IsWater = 0
	AND InUse = 1

	-- Delete the first few hours from the first day, as that is the previous 'trading day'
	DELETE
	FROM #TradingDispensed
	WHERE DateAndTime < DATEADD(hh,@TradingDayBeginsAt,@From)
	
	-- Delete the last few hours from the 'last+1' day, as that is the next 'trading day'
	DELETE
	FROM #TradingDispensed
	WHERE DateAndTime >= DATEADD(hh,@TradingDayBeginsAt,DATEADD(dd,1,@To))

	SELECT CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, TradingDateAndTime))) AS [Date],
		   Pump AS SitePump,
		   Product,
		   ISNULL(SUM(CASE WHEN LiquidType = @CleanerLiquidType THEN Quantity END), 0) AS CleaningTotal,
		   ISNULL(SUM(CASE WHEN LiquidType = @WaterLiquidType THEN Quantity END), 0) AS WaterTotal
	FROM #TradingDispensed
	GROUP BY CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, TradingDateAndTime))),
			  Pump,
			  Product
	HAVING ( SUM(CASE WHEN LiquidType = @CleanerLiquidType THEN Quantity END) > @WaterThreshold )
	OR ( SUM(CASE WHEN LiquidType = @WaterLiquidType THEN Quantity END) > @WaterThreshold )
	ORDER BY CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, TradingDateAndTime))), 
		 Pump

	DROP TABLE #TradingDispensed

END

DROP TABLE #Sites
DROP TABLE #SitePumpCounts
DROP TABLE #SitePumpOffsets
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteLineCleaningDispense] TO PUBLIC
    AS [dbo];

