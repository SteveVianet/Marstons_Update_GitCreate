CREATE PROCEDURE [dbo].[GetEquipmentItemsForCalibrator]
(
	@EDISID				INT,
	@OnlyInUse			BIT = 1
)
AS

SET NOCOUNT ON

SELECT	EquipmentItems.[ID],
		0 AS SlaveID,
	   	0 AS IsDigital,
		InputID,
		LocationID,
		EquipmentTypeID,		--EquipmentSubTypes.ID AS EquipmentSubTypeID,
		EquipmentTypes.[Description],
		InUse,
		Locations.Description AS LocationDescription, 
		EquipmentTypes.Description AS EquipmentTypeDescription,
        EquipmentTypes.EquipmentSubTypeID
FROM EquipmentItems
JOIN EquipmentTypes ON EquipmentTypes.[ID] = EquipmentItems.EquipmentTypeID
JOIN Locations ON Locations.ID = EquipmentItems.LocationID
JOIN Sites ON Sites.EDISID = EquipmentItems.EDISID
WHERE EquipmentItems.EDISID = @EDISID
AND (InUse = 1 OR @OnlyInUse = 0)
ORDER BY EquipmentItems.InputID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetEquipmentItemsForCalibrator] TO PUBLIC
    AS [dbo];

