---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE UpdateProductIcon
(
	@ProductID	INT,
	@IconID		INT
)

AS

UPDATE dbo.Products
SET IconID = @IconID
WHERE [ID] = @ProductID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateProductIcon] TO PUBLIC
    AS [dbo];

