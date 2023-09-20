CREATE PROCEDURE [dbo].[UpdateProductCategory]
(
	@ProductID		INT,
	@ProductCategoryID	INT
)

AS

UPDATE dbo.Products
SET	CategoryID = @ProductCategoryID
WHERE [ID] = @ProductID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateProductCategory] TO [ProductCreator]
    AS [dbo];

