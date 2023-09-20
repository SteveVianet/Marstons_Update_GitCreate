CREATE PROCEDURE [dbo].[GetEquipmentSubTypes]

AS

SELECT	[ID],
	[Description]
FROM dbo.EquipmentSubTypes
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetEquipmentSubTypes] TO PUBLIC
    AS [dbo];

