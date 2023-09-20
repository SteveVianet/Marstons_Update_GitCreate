CREATE PROCEDURE dbo.GetProductGroups

AS

SELECT	[ID],
		[Description],
		TypeID
FROM dbo.ProductGroups
ORDER BY TypeID, [Description]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetProductGroups] TO PUBLIC
    AS [dbo];

