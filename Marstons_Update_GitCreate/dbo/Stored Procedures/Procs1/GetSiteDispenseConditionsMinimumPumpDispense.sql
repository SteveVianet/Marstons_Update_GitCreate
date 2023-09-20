CREATE PROCEDURE dbo.[GetSiteDispenseConditionsMinimumPumpDispense]
(
	@EDISID			INTEGER,
	@From				DATETIME,
	@To				DATETIME,
	@Pints				INTEGER,
	@ShowBelowPintsThreshold	BIT
)
AS

SET NOCOUNT ON

DECLARE @Sites TABLE(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
DECLARE @SiteGroupID INT
DECLARE @SitePumpCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL, PumpOffset INT NOT NULL)
DECLARE @SiteOnline DATETIME

SELECT @SiteOnline = SiteOnline
FROM dbo.Sites
WHERE EDISID = @EDISID

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

SELECT 	Pump + PumpOffset AS Pump,
	SUM(CASE LiquidType WHEN 2 THEN Pints ELSE 0 END) AS Quantity,
	SUM(CASE LiquidType WHEN 5 THEN Pints ELSE 0 END) AS QuantityInClean,
	SUM(CASE LiquidType WHEN 3 THEN Pints ELSE 0 END) AS Cleaner
FROM DispenseActions
JOIN Products ON Products.[ID] = DispenseActions.Product
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = DispenseActions.EDISID
JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = DispenseActions.EDISID
WHERE DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) BETWEEN @From AND @To
AND Products.IsMetric = 0
GROUP BY Pump + PumpOffset
HAVING (SUM(Pints) < @Pints AND SUM(Pints) > 1 AND @ShowBelowPintsThreshold = 1) OR (SUM(Pints) > @Pints AND @ShowBelowPintsThreshold = 0)
ORDER BY Pump + PumpOffset

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteDispenseConditionsMinimumPumpDispense] TO PUBLIC
    AS [dbo];

