CREATE PROCEDURE [dbo].[DeleteProductAlias]
(
	@ProductID	INT = null,
	@Alias		VARCHAR(50)
)

AS

DELETE FROM dbo.ProductAlias
WHERE (@ProductID is null or ProductID = @ProductID)
AND Alias = @Alias



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteProductAlias] TO PUBLIC
    AS [dbo];

