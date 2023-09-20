CREATE PROCEDURE [dbo].[GetSiteLineCleaningDispense]
(
	@EDISID		INT,
	@From			DATETIME,
	@To			DATETIME,
	@WaterThreshold	FLOAT, 
	@IncludeNIU BIT = 0
)
AS
 
SET NOCOUNT ON

DECLARE @Sites TABLE(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
DECLARE @SitePumpCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL PRIMARY KEY, PumpOffset INT NOT NULL)
DECLARE @TradingDispensed TABLE(EDISID INT NOT NULL, [DateAndTime] DATETIME NOT NULL, TradingDateAndTime DATETIME NOT NULL, Product VARCHAR(50) NOT NULL, Quantity FLOAT NOT NULL, SitePump INT NOT NULL, Pump INT NOT NULL, LiquidType INT NOT NULL)

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
DECLARE @EDISID2 INT
DECLARE @EDISID3 INT
DECLARE @EDISID4 INT

SET @EDISID2 = -1
SET @EDISID3 = -1
SET @EDISID4 = -1


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
SELECT MainCounts.EDISID, COALESCE(QuaternaryCounts.MaxPump+TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, SecondaryCounts.MaxPump, 0)
FROM @SitePumpCounts AS MainCounts
LEFT JOIN @SitePumpCounts AS SecondaryCounts ON SecondaryCounts.Counter+1 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS TertiaryCounts ON TertiaryCounts.Counter+2 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS QuaternaryCounts ON QuaternaryCounts.Counter+3 = MainCounts.Counter


--This and the 4 near identical INSERTS are highly retarded but is the only way I could get the query to run in <5-20 seconds
--DMG: This code fails as soon as more than 2 cellars are involved. We can't set variables reliably when working with multiple rows.
/*
SELECT @EDISID2 = CASE CellarID WHEN 2 THEN EDISID ELSE -1 END,
	@EDISID3 = CASE CellarID WHEN 2 THEN EDISID ELSE -1 END,
	@EDISID4 = CASE CellarID WHEN 2 THEN EDISID ELSE -1 END
FROM @Sites
*/

SELECT @EDISID2 = ISNULL(EDISID, -1)
FROM @Sites
WHERE CellarID = 2

SELECT @EDISID3 = ISNULL(EDISID, -1)
FROM @Sites
WHERE CellarID = 3

SELECT @EDISID4 = ISNULL(EDISID, -1)
FROM @Sites
WHERE CellarID = 4

IF @IsBQM = 1
BEGIN
	SET @WaterThreshold = 0		-- this is DMS nonsense, so we disable it here

	INSERT INTO @TradingDispensed
	(EDISID, [DateAndTime], TradingDateAndTime, Product, Quantity, SitePump, Pump, LiquidType)
	SELECT  Actions.EDISID,
		StartTime,
		CAST(DATEADD(dd, 0, DATEDIFF(dd, 0, TradingDay)) + CONVERT(VARCHAR(10), StartTime, 108) AS DATETIME) AS TradingDateAndTime,
		Products.Description,
		Pints,
		Pump,
		Pump + PumpOffset,
		LiquidType
	FROM 
		(SELECT DispenseActions.EDISID, StartTime, TradingDay, Pints, Pump, LiquidType, Product 
		FROM DispenseActions 
		WHERE (TradingDay BETWEEN @From AND @To) 
		AND LiquidType IN (@CleanerLiquidType, @WaterLiquidType)
		AND EDISID = @EDISID
	) AS Actions
	JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = Actions.EDISID
	JOIN Products ON Products.[ID] = Actions.Product

	INSERT INTO @TradingDispensed
	(EDISID, [DateAndTime], TradingDateAndTime, Product, Quantity, SitePump, Pump, LiquidType)
	SELECT  Actions.EDISID,
		StartTime,
		CAST(DATEADD(dd, 0, DATEDIFF(dd, 0, TradingDay)) + CONVERT(VARCHAR(10), StartTime, 108) AS DATETIME) AS TradingDateAndTime,
		Products.Description,
		Pints,
		Pump,
		Pump + PumpOffset,
		LiquidType
	FROM 
		(SELECT DispenseActions.EDISID, StartTime, TradingDay, Pints, Pump, LiquidType, Product 
		FROM DispenseActions 
		WHERE (TradingDay BETWEEN @From AND @To) 
		AND LiquidType IN (@CleanerLiquidType, @WaterLiquidType)
		AND EDISID = @EDISID2
	) AS Actions
	JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = Actions.EDISID
	JOIN Products ON Products.[ID] = Actions.Product

	INSERT INTO @TradingDispensed
	(EDISID, [DateAndTime], TradingDateAndTime, Product, Quantity, SitePump, Pump, LiquidType)
	SELECT  Actions.EDISID,
		StartTime,
		CAST(DATEADD(dd, 0, DATEDIFF(dd, 0, TradingDay)) + CONVERT(VARCHAR(10), StartTime, 108) AS DATETIME) AS TradingDateAndTime,
		Products.Description,
		Pints,
		Pump,
		Pump + PumpOffset,
		LiquidType
	FROM 
		(SELECT DispenseActions.EDISID, StartTime, TradingDay, Pints, Pump, LiquidType, Product 
		FROM DispenseActions 
		WHERE (TradingDay BETWEEN @From AND @To) 
		AND LiquidType IN (@CleanerLiquidType, @WaterLiquidType)
		AND EDISID = @EDISID3
	) AS Actions
	JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = Actions.EDISID
	JOIN Products ON Products.[ID] = Actions.Product

	INSERT INTO @TradingDispensed
	(EDISID, [DateAndTime], TradingDateAndTime, Product, Quantity, SitePump, Pump, LiquidType)
	SELECT  Actions.EDISID,
		StartTime,
		CAST(DATEADD(dd, 0, DATEDIFF(dd, 0, TradingDay)) + CONVERT(VARCHAR(10), StartTime, 108) AS DATETIME) AS TradingDateAndTime,
		Products.Description,
		Pints,
		Pump,
		Pump + PumpOffset,
		LiquidType
	FROM 
		(SELECT DispenseActions.EDISID, StartTime, TradingDay, Pints, Pump, LiquidType, Product 
		FROM DispenseActions 
		WHERE (TradingDay BETWEEN @From AND @To) 
		AND LiquidType IN (@CleanerLiquidType, @WaterLiquidType)
		AND EDISID = @EDISID4
	) AS Actions
	JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = Actions.EDISID
	JOIN Products ON Products.[ID] = Actions.Product

END
ELSE
BEGIN
	INSERT INTO @TradingDispensed
	(EDISID, [DateAndTime], TradingDateAndTime, Product, Quantity, SitePump, Pump, LiquidType)
	SELECT MD.EDISID,
		 CONVERT(VARCHAR(19), DATEADD(ss, DATEPART(ss, WaterStack.[Time]), DATEADD(mi, DATEPART(mi, WaterStack.[Time]), DATEADD(hh, DATEPART(hh, WaterStack.[Time]), MD.[Date]))), 20),
		 DATEADD(Hour, DATEPART(Hour, WaterStack.[Time]), CASE WHEN DATEPART(Hour, WaterStack.[Time]) < 5 THEN DATEADD(Day, -1, MD.[Date]) ELSE MD.[Date] END) AS [TradingDateAndTime],
		 Products.Description,
		 Volume,
		 Line,
		 Line + PumpOffset,
		 @CleanerLiquidType
	FROM WaterStack
	JOIN (SELECT ID, EDISID, [Date] FROM MasterDates WHERE [Date] BETWEEN @From AND DATEADD(dd,1,@To)) AS MD ON MD.[ID] = WaterStack.WaterID
	JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = MD.EDISID
	JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = MD.EDISID
	JOIN PumpSetup ON (PumpSetup.EDISID = MD.EDISID
	      		AND PumpSetup.Pump = WaterStack.Line
	      		AND MD.[Date] BETWEEN PumpSetup.ValidFrom AND ISNULL(PumpSetup.ValidTo, @To))
	JOIN Products ON Products.[ID] = PumpSetup.ProductID
	WHERE MD.[Date] BETWEEN @From AND DATEADD(dd,1,@To)
	AND Products.IsWater = 0
	AND ((InUse = 1) OR (@IncludeNIU = 1))


	-- Delete the first few hours from the first day, as that is the previous 'trading day'
	DELETE
	FROM @TradingDispensed
	WHERE DateAndTime < DATEADD(hh,@TradingDayBeginsAt,@From)
	
	-- Delete the first few hours from the 'last+1' day, as that is the next 'trading day'
	DELETE
	FROM @TradingDispensed
	WHERE DateAndTime >= DATEADD(hh,@TradingDayBeginsAt,DATEADD(dd,1,@To))

END

SELECT CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, TradingDateAndTime))) AS [Date],
       Pump AS SitePump,
       Product,
       ISNULL(SUM(CASE WHEN LiquidType = @CleanerLiquidType THEN Quantity END), 0) AS CleaningTotal,
       ISNULL(SUM(CASE WHEN LiquidType = @WaterLiquidType THEN Quantity END), 0) AS WaterTotal
FROM @TradingDispensed AS TradingDispensed
JOIN Sites ON Sites.EDISID = TradingDispensed.EDISID
GROUP BY CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, TradingDateAndTime))),
	      Pump,
	      Product,
	      Sites.Quality
HAVING ( SUM(CASE WHEN LiquidType = @CleanerLiquidType THEN Quantity END) > @WaterThreshold )
OR ( SUM(CASE WHEN LiquidType = @WaterLiquidType THEN Quantity END) > @WaterThreshold )

ORDER BY CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, TradingDateAndTime))), 
	 Pump

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteLineCleaningDispense] TO PUBLIC
    AS [dbo];

