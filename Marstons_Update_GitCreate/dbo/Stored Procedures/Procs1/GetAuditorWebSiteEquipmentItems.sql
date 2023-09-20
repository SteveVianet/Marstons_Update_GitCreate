CREATE PROCEDURE [dbo].[GetAuditorWebSiteEquipmentItems]

(
	@EDISID INT
	
)

AS
BEGIN

SELECT	EquipmentItems.ID,
		InputID,
		Locations.[Description] AS LocationDescription,
		EquipmentTypes.[Description] AS TypeDescription,
		ISNULL(ValueLowSpecification, EquipmentTypes.DefaultLowSpecification) AS ValueLowSpecification,
		ISNULL(ValueHighSpecification, EquipmentTypes.DefaultHighSpecification) AS ValueHighSpecification,
		ISNULL(LowAlarmThreshold, EquipmentTypes.DefaultLowAlarmThreshold) AS LowAlarmThreshold,
		ISNULL(HighAlarmThreshold, EquipmentTypes.DefaultHighAlarmThreshold) AS HighAlarmThreshold,
		EquipmentItems.[Description],
		AlarmStartTime,
		AlarmEndTime,
		AlarmStatus
FROM EquipmentItems
JOIN EquipmentTypes ON EquipmentTypes.ID = EquipmentItems.EquipmentTypeID
JOIN Locations ON Locations.ID = EquipmentItems.LocationID
WHERE EquipmentItems.EDISID = @EDISID

END
