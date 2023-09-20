
CREATE PROCEDURE [dbo].[GetWebSiteDispenseHourlyDMS]
(
	@EDISID			INT,
	@From			DATETIME,
	@To				DATETIME,
	@IncludeCasks	BIT,
	@IncludeKegs	BIT,
	@IncludeMetric	BIT,
	@IncludeMondayDispense BIT = 1,
	@IncludeTuesdayDispense BIT = 1,
	@IncludeWednesdayDispense BIT = 1,
	@IncludeThursdayDispense BIT = 1,
	@IncludeFridayDispense BIT = 1,
	@IncludeSaturdayDispense BIT = 1,
	@IncludeSundayDispense BIT = 1,
	@IncludeLiquidUnknown	BIT = 0,
	@IncludeLiquidWater		BIT = 1,
	@IncludeLiquidBeer		BIT = 1,
	@IncludeLiquidCleaner		BIT = 1,
	@IncludeLiquidInTransition	BIT = 1,
	@IncludeLiquidBeerInClean	BIT = 1
)
AS

SET NOCOUNT ON
SET DATEFIRST 1

DECLARE @TradingDispensed TABLE(EDISID INT NOT NULL,
					DateAndTime DATETIME NOT NULL,
					TradingDateAndTime DATETIME NOT NULL,
					Shift INT NOT NULL,
					Product VARCHAR(255) NOT NULL,
					IsCask BIT NOT NULL,
					LiquidType INT NOT NULL,
					Quantity FLOAT NOT NULL,
					SitePump INT NOT NULL,
					Pump INT NOT NULL,
					Drinks FLOAT NOT NULL)

DECLARE @TradingDayBeginsAt INT
SET @TradingDayBeginsAt = 5

DECLARE @ShowLatestData BIT
DECLARE @AuditDate DATETIME
DECLARE @ShowUptoAudited DATETIME

DECLARE @Sites TABLE(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
DECLARE @SiteGroupID INT
DECLARE @SitePumpCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL, PumpOffset INT NOT NULL)
DECLARE @SiteOnline DATETIME

SELECT @SiteOnline = SiteOnline
FROM dbo.Sites
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

-- Get dispense for period and bodge about into 'trading hours'
-- DateAndTime is the actual date and time
-- TradingDateAndTime is the actual time, but the date is the 'trading date'
-- Note that we grab an extra day (because we need the first few hours from it)
INSERT INTO @TradingDispensed
(EDISID,
[DateAndTime],
TradingDateAndTime,
Shift,
Product,
IsCask,
LiquidType,
Quantity,
SitePump,
Pump,
Drinks)

SELECT  MasterDates.EDISID,
	DATEADD(Hour, Shift-1, MasterDates.[Date]),
	DATEADD(Hour, Shift-1, (CASE WHEN Shift-1 < 5 THEN DATEADD(Day, -1, MasterDates.[Date]) ELSE MasterDates.[Date]	END) ),
	Shift,
	Products.Description,
	Products.IsCask,
	2,
	Quantity,
	Pump,
	Pump + PumpOffset,
	Quantity
FROM DLData
JOIN MasterDates ON MasterDates.[ID] = DLData.DownloadID
JOIN Products ON Products.[ID] = DLData.Product
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = MasterDates.EDISID
JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = MasterDates.EDISID
WHERE MasterDates.[Date] BETWEEN @From AND DATEADD(dd,1,@To)
AND MasterDates.[Date] >= @SiteOnline
AND (Products.IsCask = 0 OR @IncludeCasks = 1)
AND (Products.IsCask = 1 OR @IncludeKegs = 1)
AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
AND MasterDates.Date >= @SiteOnline

-- Delete the first few hours from the first day, as that is the previous 'trading day'
DELETE
FROM @TradingDispensed
WHERE DateAndTime < DATEADD(hh,@TradingDayBeginsAt,@From)

---- Delete the first few hours from the 'last+1' day, as that is the next 'trading day'
DELETE
FROM @TradingDispensed
WHERE DateAndTime >= DATEADD(hh,@TradingDayBeginsAt,DATEADD(dd,1,@To))

SET @ShowLatestData = 0

SELECT @ShowLatestData = CASE WHEN UPPER(Value) = 'TRUE' THEN 1 ELSE 0 END 
FROM SiteProperties
JOIN Properties ON Properties.[ID] = SiteProperties.PropertyID
WHERE SiteProperties.EDISID = @EDISID AND Properties.[Name] = 'ShowLatestDataOnWeb'

SELECT @AuditDate = DATEADD(day, 7, CAST(Configuration.PropertyValue AS DATETIME))
FROM Configuration
WHERE PropertyName = 'AuditDate'

SELECT
		CAST(STR(DATEPART(year,DateAndTime),4) + '-' + STR(DATEPART(month,DateAndTime),LEN(DATEPART(month,DateAndTime))) + '-' + STR(DATEPART(day,DateAndTime),LEN(DATEPART(day,DateAndTime))) + ' ' + STR(DATEPART(hour,DateAndTime),LEN(DATEPART(hour,DateAndTime))) + ':' + STR((DATEPART(minute, DateAndTime)/60)*60,LEN(DATEPART(minute,DateAndTime))) + ':00' AS DATETIME) AS DateAndTime,
  		CAST(STR(DATEPART(year,TradingDateAndTime),4) + '-' + STR(DATEPART(month,TradingDateAndTime),LEN(DATEPART(month,TradingDateAndTime))) + '-' + STR(DATEPART(day,TradingDateAndTime),LEN(DATEPART(day,TradingDateAndTime))) + ' ' + STR(DATEPART(hour,TradingDateAndTime),LEN(DATEPART(hour,TradingDateAndTime))) + ':' + STR((DATEPART(minute, TradingDateAndTime)/60)*60,LEN(DATEPART(minute,TradingDateAndTime))) + ':00' AS DATETIME) AS TradingDateAndTime,
  		DATEPART(WEEKDAY, TradingDateAndTime) AS [WeekDay],
		Shift,
		Pump,
		Product, 
		IsCask,
		0 AS QuantityUnknown,
		0 AS QuantityWater,
		SUM(Quantity) AS QuantityBeer,
		0 AS QuantityCleaner,
		0 AS QuantityInTransition,
		0 AS QuantityBeerInClean,
		SUM(Quantity) AS Quantity,
		SUM(Drinks) AS Drinks,
		'' AS Location
FROM @TradingDispensed AS TradingDispensed
WHERE ((TradingDateAndTime < @AuditDate) OR  @ShowLatestData = 1)
AND ((DATEPART(DW, TradingDateAndTime) = 1 AND @IncludeMondayDispense = 1)
OR (DATEPART(DW, TradingDateAndTime) = 2 AND @IncludeTuesdayDispense = 1)
OR (DATEPART(DW, TradingDateAndTime) = 3 AND @IncludeWednesdayDispense = 1)
OR (DATEPART(DW, TradingDateAndTime) = 4 AND @IncludeThursdayDispense = 1)
OR (DATEPART(DW, TradingDateAndTime) = 5 AND @IncludeFridayDispense = 1)
OR (DATEPART(DW, TradingDateAndTime) = 6 AND @IncludeSaturdayDispense = 1)
OR (DATEPART(DW, TradingDateAndTime) = 7 AND @IncludeSundayDispense = 1))
GROUP BY	CAST(STR(DATEPART(year,DateAndTime),4) + '-' + STR(DATEPART(month,DateAndTime),LEN(DATEPART(month,DateAndTime))) + '-' + STR(DATEPART(day,DateAndTime),LEN(DATEPART(day,DateAndTime))) + ' ' + STR(DATEPART(hour,DateAndTime),LEN(DATEPART(hour,DateAndTime))) + ':' + STR((DATEPART(minute, DateAndTime)/60)*60,LEN(DATEPART(minute,DateAndTime))) + ':00' AS DATETIME),
			CAST(STR(DATEPART(year,TradingDateAndTime),4) + '-' + STR(DATEPART(month,TradingDateAndTime),LEN(DATEPART(month,TradingDateAndTime))) + '-' + STR(DATEPART(day,TradingDateAndTime),LEN(DATEPART(day,TradingDateAndTime))) + ' ' + STR(DATEPART(hour,TradingDateAndTime),LEN(DATEPART(hour,TradingDateAndTime))) + ':' + STR((DATEPART(minute, TradingDateAndTime)/60)*60,LEN(DATEPART(minute,TradingDateAndTime))) + ':00' AS DATETIME),
			DATEPART(WEEKDAY, TradingDateAndTime),
			Shift,
			Pump,
			Product,
			IsCask

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteDispenseHourlyDMS] TO PUBLIC
    AS [dbo];

