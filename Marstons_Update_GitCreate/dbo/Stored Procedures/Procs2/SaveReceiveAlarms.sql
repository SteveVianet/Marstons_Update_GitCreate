
CREATE PROCEDURE SaveReceiveAlarms
(
	@EDISID				INT,
	@EquipmentTypeID	INT,
	@AlarmStartTime		TIME(0),
	@AlarmEndTime		TIME(0)
)

AS

SET NOCOUNT ON;

UPDATE EquipmentItems
SET AlarmStartTime = @AlarmStartTime, AlarmEndTime = @AlarmEndTime
WHERE EDISID = @EDISID
	AND EquipmentTypeID = @EquipmentTypeID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SaveReceiveAlarms] TO PUBLIC
    AS [dbo];

