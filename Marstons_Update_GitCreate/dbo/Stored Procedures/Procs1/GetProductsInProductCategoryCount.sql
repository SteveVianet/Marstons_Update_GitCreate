CREATE PROCEDURE [dbo].[GetProductsInProductCategoryCount]
(
		@ProductCategoryID	INT
)

AS

SELECT Count(ID) as ProductCount
FROM dbo.Products
WHERE CategoryID = @ProductCategoryID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetProductsInProductCategoryCount] TO PUBLIC
    AS [dbo];

