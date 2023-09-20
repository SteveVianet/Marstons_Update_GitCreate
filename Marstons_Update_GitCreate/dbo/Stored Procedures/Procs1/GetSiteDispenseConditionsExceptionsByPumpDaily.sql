CREATE PROCEDURE [dbo].[GetSiteDispenseConditionsExceptionsByPumpDaily]
(
	@EDISID	INTEGER,
	@From		DATETIME,
	@To		DATETIME
)
AS

SET NOCOUNT ON

DECLARE @Sites TABLE(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
DECLARE @SitePumpCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL PRIMARY KEY, PumpOffset INT NOT NULL)

DECLARE @SiteGroupID INT
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

-- TODO: SitePumps/PumpOffsets stuff...
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

SELECT	[Date],
		Pump,
		Products.[Description],
		 ProductID,
		CASE 	WHEN ( (MaxTemp > 50 OR MinTemp < -5) AND (MinCond < 50 OR MaxCond > 65000) AND (MinCond IS NOT NULL) ) THEN 't&c'
			WHEN (MaxTemp > 50 OR MinTemp < -5) THEN 't'
			ELSE '&'
		END AS [ErrorState]
FROM (
	SELECT TradingDay AS [Date],
	       DispenseActions.Pump + PumpOffset AS Pump,
	       DispenseActions.Product AS ProductID,
		MIN(AverageTemperature) AS MinTemp,
		MAX(AverageTemperature) AS MaxTemp,
		MIN(AverageConductivity) AS MinCond,
		MAX(AverageConductivity) AS MaxCond
	FROM DispenseActions
	JOIN @Sites AS Sites ON Sites.EDISID = DispenseActions.EDISID
	JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = DispenseActions.EDISID
	WHERE TradingDay BETWEEN @From AND @To
	AND (
		(AverageTemperature > 50)
		OR (AverageTemperature < -5)
		OR (AverageConductivity > 65000)
		OR (AverageConductivity < 50)
	)
	GROUP BY TradingDay, 
		       DispenseActions.Pump + PumpOffset, 
		       DispenseActions.Product
) AS BadDrinks
JOIN Products ON Products.ID = BadDrinks.ProductID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteDispenseConditionsExceptionsByPumpDaily] TO PUBLIC
    AS [dbo];

