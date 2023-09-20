

CREATE PROCEDURE [dbo].[GetDistinctEquipmentTypes]
(
	@EDISID		INT
)

AS

SET NOCOUNT ON;

SELECT DISTINCT t.ID, t.[Description], i.AlarmStartTime, i.AlarmEndTime, i.[Description] as [ItemDescription]
FROM EquipmentItems i
INNER JOIN EquipmentTypes t ON t.ID = i.EquipmentTypeID
WHERE EDISID = @EDISID



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDistinctEquipmentTypes] TO PUBLIC
    AS [dbo];

