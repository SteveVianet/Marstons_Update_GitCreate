CREATE PROCEDURE [dbo].[AddServiceIssueEquipment]
(
	@CallID					INT = 0,
	@InputID				INT = 0,
	@ExcludeAllEquipment	BIT = 0,
	@StartDate				DATETIME,
	@CallReasonTypeID		INT
)
AS

SET NOCOUNT ON

DECLARE @EquipmentSubTypeID INT
DECLARE @EDISID INT
DECLARE @PrimaryEDISID INT

SELECT @EDISID = EDISID
FROM Calls
WHERE ID = @CallID

SELECT @PrimaryEDISID = MAX(PrimaryEDISID)
FROM(
	SELECT SiteGroupID, SiteGroupSites.EDISID AS PrimaryEDISID
	FROM SiteGroupSites 
	WHERE SiteGroupID IN (SELECT ID FROM SiteGroups WHERE TypeID = 1)
	AND IsPrimary = 1
	GROUP BY SiteGroupID, SiteGroupSites.EDISID
) AS PrimarySites
JOIN SiteGroupSites ON SiteGroupSites.SiteGroupID = PrimarySites.SiteGroupID
WHERE SiteGroupSites.EDISID = @EDISID
GROUP BY SiteGroupSites.EDISID

SELECT @EquipmentSubTypeID = EquipmentSubTypeID
FROM EquipmentItems
JOIN EquipmentTypes ON EquipmentTypes.ID = EquipmentItems.EquipmentTypeID
WHERE InputID = @InputID

INSERT INTO dbo.ServiceIssuesEquipment
(EDISID, CallID, InputID, DateFrom, DateTo, RealEDISID, CallReasonTypeID)
SELECT	ISNULL(@PrimaryEDISID, @EDISID) AS EDISID,
		@CallID AS CallID,
		EquipmentItems.InputID,
		@StartDate AS DateFrom,
		NULL AS DateTo,
		@EDISID AS RealEDISID,
		@CallReasonTypeID AS CallReasonTypeID
FROM EquipmentItems
JOIN EquipmentTypes ON EquipmentTypes.ID = EquipmentItems.EquipmentTypeID
LEFT JOIN ServiceIssuesEquipment AS CurrentIssues ON CurrentIssues.EDISID = @EDISID
												 AND CurrentIssues.CallID = @CallID
												 AND CurrentIssues.InputID = EquipmentItems.InputID
WHERE EquipmentItems.EDISID = @EDISID
AND (EquipmentItems.InputID = @InputID OR (@ExcludeAllEquipment = 1 AND EquipmentSubTypeID = @EquipmentSubTypeID))

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddServiceIssueEquipment] TO PUBLIC
    AS [dbo];

