CREATE PROCEDURE [dbo].[GetWebSiteEquipmentItems]
(
	@EDISID			INT,
	@EquipmentTypeID		INT,
	@EquipmentSubTypeID	INT
)

AS

SET NOCOUNT ON

DECLARE @Sites TABLE(EDISID INT NOT NULL)
DECLARE @SiteGroupID INT
DECLARE @SiteInputCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxInput INT NOT NULL)
DECLARE @SiteInputOffsets TABLE(EDISID INT NOT NULL, InputOffset INT NOT NULL)
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
SELECT  EquipmentItems.InputID + InputOffset AS InputID,
		EquipmentTypes.ID AS EquipmentTypeID,
	    EquipmentTypes.[Description] AS EquipmentType,
	    EquipmentTypes.EquipmentSubTypeID,
	    EquipmentSubTypes.[Description] AS EquipmentSubType,
	    Locations.[Description] AS Location,
	    LTRIM(RTRIM(EquipmentItems.[Description])) AS EquipmentItemName
FROM EquipmentItems 
JOIN EquipmentTypes ON EquipmentTypes.ID = EquipmentItems.EquipmentTypeID
JOIN @SiteInputOffsets AS SiteInputOffsets ON SiteInputOffsets.EDISID = EquipmentItems.EDISID
JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = EquipmentItems.EDISID
JOIN EquipmentSubTypes ON EquipmentSubTypes.ID = EquipmentTypes.EquipmentSubTypeID
JOIN Locations ON Locations.ID = EquipmentItems.LocationID
WHERE (EquipmentItems.EquipmentTypeID = @EquipmentTypeID OR @EquipmentTypeID IS Null)
AND (EquipmentTypes.EquipmentSubTypeID = @EquipmentSubTypeID OR @EquipmentSubTypeID IS Null)
AND InUse = 1
GROUP BY EquipmentItems.InputID + InputOffset,
		 EquipmentItems.EquipmentTypeID,
EquipmentTypes.ID,
		 EquipmentTypes.[Description],
		 EquipmentTypes.EquipmentSubTypeID,
		 EquipmentSubTypes.[Description],
		 Locations.[Description],
		 LTRIM(RTRIM(EquipmentItems.[Description]))
ORDER BY EquipmentTypes.EquipmentSubTypeID, EquipmentTypes.ID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteEquipmentItems] TO PUBLIC
    AS [dbo];

