CREATE PROCEDURE [dbo].[GetWebSiteEquipmentUsed]
(
	@EDISID			INT,
	@From				DATETIME,
	@To				DATETIME
)

AS

SET NOCOUNT ON

DECLARE @Sites TABLE(EDISID INT NOT NULL)
DECLARE @SiteGroupID INT
DECLARE @SiteInputCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxInput INT NOT NULL)
DECLARE @SiteInputOffsets TABLE(EDISID INT NOT NULL, InputOffset INT NOT NULL)
DECLARE @SiteOnline DATETIME

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
INSERT INTO @SiteInputCounts (EDISID, MaxInput)
SELECT EquipmentItems.EDISID, MAX(InputID)
FROM EquipmentItems
JOIN @Sites AS Sites ON Sites.EDISID = EquipmentItems.EDISID
GROUP BY EquipmentItems.EDISID

INSERT INTO @SiteInputOffsets (EDISID, InputOffset)
SELECT MainCounts.EDISID, ISNULL(SecondaryCounts.MaxInput, 0)
FROM @SiteInputCounts AS MainCounts
LEFT JOIN @SiteInputCounts AS SecondaryCounts ON SecondaryCounts.Counter+1 = MainCounts.Counter

-- Get desired equipment logs
-- RW: Dec 2011, added EqItems so we can exclude deleted items
SELECT EquipmentTypes.ID, EquipmentTypes.[Description], COUNT(EquipmentReadings.EquipmentTypeID) AS [Count]
FROM EquipmentReadings
JOIN EquipmentTypes ON EquipmentTypes.ID = EquipmentReadings.EquipmentTypeID
JOIN @SiteInputOffsets AS SiteInputOffsets ON SiteInputOffsets.EDISID = EquipmentReadings.EDISID
JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = EquipmentReadings.EDISID
JOIN EquipmentItems ON (EquipmentItems.EDISID = EquipmentReadings.EDISID AND EquipmentItems.InputID = EquipmentReadings.InputID)
WHERE TradingDate BETWEEN @From AND DATEADD(second, -1, DATEADD(day, 1, @To))
AND TradingDate >= @SiteOnline
AND EquipmentItems.InUse = 1
GROUP BY EquipmentTypes.ID, EquipmentTypes.[Description]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteEquipmentUsed] TO PUBLIC
    AS [dbo];

