CREATE PROCEDURE [dbo].[GetProductAliasDescriptions]
AS

SELECT	ProductID,
		[Description],
		Alias
FROM Products
JOIN ProductAlias ON ProductAlias.ProductID = Products.ID
ORDER BY ProductID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetProductAliasDescriptions] TO PUBLIC
    AS [dbo];

