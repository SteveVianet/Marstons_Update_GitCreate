
CREATE PROCEDURE dbo.DeleteProductGroupProduct
(
	@ProductID		INT,
	@ProductGroupID	INT
)

AS

DELETE FROM dbo.ProductGroupProducts
WHERE ProductID = @ProductID
AND ProductGroupID = @ProductGroupID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteProductGroupProduct] TO PUBLIC
    AS [dbo];

