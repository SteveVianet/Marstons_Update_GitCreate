CREATE PROCEDURE [dbo].[GetEquipmentTypes]

AS

SELECT	[ID],
	[Description],
	EquipmentSubTypeID,
	DefaultSpecification,
	DefaultTolerance,
	DefaultAlarmThreshold,
	DefaultLowSpecification,
	DefaultHighSpecification,
	DefaultLowAlarmThreshold,
	DefaultHighAlarmThreshold,
	CanRaiseAlarm
FROM dbo.EquipmentTypes

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetEquipmentTypes] TO PUBLIC
    AS [dbo];

