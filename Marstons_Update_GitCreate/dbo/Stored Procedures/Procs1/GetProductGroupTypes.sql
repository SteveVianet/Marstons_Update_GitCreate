
CREATE PROCEDURE dbo.GetProductGroupTypes

AS

SELECT	[ID],
	[Description],
	OverrideProduct
FROM dbo.ProductGroupTypes

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetProductGroupTypes] TO PUBLIC
    AS [dbo];

