---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE UpdateProductImage
(
	@ProductID	INT,
	@ImageID	INT
)

AS

UPDATE dbo.Products
SET ImageID = @ImageID
WHERE [ID] = @ProductID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateProductImage] TO PUBLIC
    AS [dbo];

