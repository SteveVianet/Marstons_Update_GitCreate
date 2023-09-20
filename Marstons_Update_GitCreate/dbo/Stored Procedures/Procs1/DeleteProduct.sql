---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE DeleteProduct
(
	@ProductID	INT
)

AS

DELETE FROM dbo.Products
WHERE [ID] = @ProductID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteProduct] TO [ProductDestroyer]
    AS [dbo];

