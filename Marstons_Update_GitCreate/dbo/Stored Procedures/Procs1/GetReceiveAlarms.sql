
CREATE PROCEDURE GetReceiveAlarms
(
	@EDISID		INT
)

AS

SET NOCOUNT ON;

SELECT i.EquipmentTypeID, i.AlarmStartTime, i.AlarmEndTime
FROM EquipmentItems i
WHERE EDISID = @EDISID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetReceiveAlarms] TO PUBLIC
    AS [dbo];

