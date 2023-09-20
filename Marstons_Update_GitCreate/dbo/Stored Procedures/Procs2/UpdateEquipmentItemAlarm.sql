CREATE PROCEDURE [dbo].[UpdateEquipmentItemAlarm]
(
	@ID						INT,
	@LastAlarmingReading	DATETIME,
	@LastAlarmingValue		FLOAT = NULL
)
AS

UPDATE dbo.EquipmentItems
SET	LastAlarmingReading = @LastAlarmingReading,
	LastAlarmingValue = @LastAlarmingValue
WHERE [ID] = @ID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateEquipmentItemAlarm] TO PUBLIC
    AS [dbo];

