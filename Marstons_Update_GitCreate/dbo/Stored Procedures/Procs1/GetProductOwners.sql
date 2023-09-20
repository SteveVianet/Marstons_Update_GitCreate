CREATE PROCEDURE [dbo].[GetProductOwners]

AS

SELECT	[ID],
	[Name]
FROM dbo.ProductOwners
ORDER BY [Name]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetProductOwners] TO PUBLIC
    AS [dbo];

