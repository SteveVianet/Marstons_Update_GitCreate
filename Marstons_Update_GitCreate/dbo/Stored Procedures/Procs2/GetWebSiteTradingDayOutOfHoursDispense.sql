
CREATE PROCEDURE [dbo].[GetWebSiteTradingDayOutOfHoursDispense]
(
	@EDISID				INT,
	@TradingDate		DATETIME,
	@ShowInUseLinesOnly BIT = 1
)
AS

SET NOCOUNT ON;

DECLARE @First AS INT
SET @First = 1
SET DATEFIRST @First

CREATE TABLE #SiteTradingShifts(EDISID INT, ShiftStartTime DATETIME, ShiftEndTime DATETIME)

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
DECLARE @OwnerID INT
DECLARE @PrimaryEDISID INT

SELECT @IsIDraught = Quality, @SiteOnline = SiteOnline, @OwnerID = OwnerID
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
 
IF @SiteGroupID IS NOT NULL
BEGIN
	SELECT @PrimaryEDISID = EDISID
	FROM SiteGroupSites
	WHERE SiteGroupSites.IsPrimary = 1
	AND SiteGroupID = @SiteGroupID
END
ELSE
BEGIN
	SET @PrimaryEDISID = @EDISID
END

-- Get pumps for secondary sites (note that 1st EDISID IN @Sites is primary site)
INSERT INTO @SitePumpCounts (EDISID, MaxPump)
SELECT PumpSetup.EDISID, MAX(Pump)
FROM PumpSetup
JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
WHERE (ValidFrom <= @TradingDate)
AND (ISNULL(ValidTo, @TradingDate) >= @TradingDate)
AND (ISNULL(ValidTo, @TradingDate) >= @SiteOnline)
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
	ISNULL(PumpSetup.ValidTo, @TradingDate),
	COALESCE(SiteProductSpecifications.CleanDaysBeforeAmber, SiteSpecifications.CleanDaysBeforeAmber, Products.LineCleanDaysBeforeAmber),
	COALESCE(SiteProductSpecifications.CleanDaysBeforeRed, SiteSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed)
FROM PumpSetup
JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = PumpSetup.EDISID
JOIN Products ON Products.[ID] = PumpSetup.ProductID
LEFT JOIN SiteProductSpecifications ON SiteProductSpecifications.EDISID = PumpSetup.EDISID
				   AND SiteProductSpecifications.ProductID = PumpSetup.ProductID
LEFT JOIN SiteSpecifications ON Sites.EDISID = SiteSpecifications.EDISID
WHERE (ValidFrom <= @TradingDate)
AND (ISNULL(ValidTo, @TradingDate) >= @TradingDate)
AND (ISNULL(ValidTo, @TradingDate) >= @SiteOnline)
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

INSERT INTO #SiteTradingShifts
SELECT	Sites.EDISID, 
		@TradingDate + CAST(COALESCE(SiteTradingShifts.ShiftStartTime, OwnerTradingShifts.ShiftStartTime) AS TIME) AS ShiftStartTime,
		DATEADD(MINUTE, COALESCE(SiteTradingShifts.ShiftDurationMinutes, OwnerTradingShifts.ShiftDurationMinutes), @TradingDate + CAST(COALESCE(SiteTradingShifts.ShiftStartTime, OwnerTradingShifts.ShiftStartTime) AS TIME)) AS ShiftEndTime
FROM Sites
JOIN OwnerTradingShifts ON OwnerTradingShifts.OwnerID = Sites.OwnerID AND DATEPART(DW, @TradingDate) = OwnerTradingShifts.[DayOfWeek]
LEFT JOIN SiteTradingShifts ON SiteTradingShifts.EDISID = Sites.EDISID AND DATEPART(DW, @TradingDate) = SiteTradingShifts.[DayOfWeek]
WHERE Sites.EDISID = @PrimaryEDISID
GROUP BY Sites.EDISID, 
		@TradingDate + CAST(COALESCE(SiteTradingShifts.ShiftStartTime, OwnerTradingShifts.ShiftStartTime) AS TIME),
		DATEADD(MINUTE, COALESCE(SiteTradingShifts.ShiftDurationMinutes, OwnerTradingShifts.ShiftDurationMinutes), @TradingDate + CAST(COALESCE(SiteTradingShifts.ShiftStartTime, OwnerTradingShifts.ShiftStartTime) AS TIME))
		
SELECT	DispenseActions.EDISID, 
		DispenseActions.TradingDay,
		Products.[Description] AS Product,
		AllSitePumps.PumpID AS Pump,
		DispenseActions.Location,	
		SUM(CASE WHEN DispenseActions.LiquidType = 2 THEN DispenseActions.Pints ELSE 0 END) AS Volume,
		SUM(CASE WHEN DispenseActions.LiquidType = 1 THEN DispenseActions.Pints ELSE 0 END) AS WaterVolume,
		SUM(CASE WHEN DispenseActions.LiquidType = 3 THEN DispenseActions.Pints ELSE 0 END) AS CleaningVolume
FROM DispenseActions
JOIN Sites ON Sites.EDISID = DispenseActions.EDISID
JOIN Products ON Products.ID = DispenseActions.Product
JOIN @AllSitePumps AS AllSitePumps ON AllSitePumps.EDISID = Sites.EDISID AND AllSitePumps.SitePump = DispenseActions.Pump
LEFT JOIN #SiteTradingShifts AS SiteTradingShifts ON SiteTradingShifts.EDISID = @PrimaryEDISID
												 AND (DispenseActions.StartTime BETWEEN SiteTradingShifts.ShiftStartTime AND SiteTradingShifts.ShiftEndTime)
WHERE (Sites.EDISID IN (SELECT EDISID FROM @Sites))
	AND LiquidType IN (1, 2, 3)
	AND TradingDay = @TradingDate
	AND SiteTradingShifts.EDISID IS NULL
GROUP BY	DispenseActions.EDISID,
			DispenseActions.TradingDay,
			AllSitePumps.PumpID,
			DispenseActions.Location,
			Products.[Description]
HAVING (SUM(CASE WHEN DispenseActions.LiquidType = 1 THEN DispenseActions.Pints ELSE 0 END) 
	  + SUM(CASE WHEN DispenseActions.LiquidType = 3 THEN DispenseActions.Pints ELSE 0 END)) = 0

DROP TABLE #SiteTradingShifts

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteTradingDayOutOfHoursDispense] TO PUBLIC
    AS [dbo];

