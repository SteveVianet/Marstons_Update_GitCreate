CREATE PROCEDURE [dbo].[DeleteProductCategory]
(
		@ProductCategoryID	INT
)

AS

DELETE 
FROM dbo.SiteProductCategoryTies 
where ProductCategoryID = @ProductCategoryID

DELETE
FROM dbo.ProductCategories
WHERE [ID] = @ProductCategoryID




GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteProductCategory] TO PUBLIC
    AS [dbo];

