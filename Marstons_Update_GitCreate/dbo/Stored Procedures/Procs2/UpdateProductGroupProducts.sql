CREATE PROCEDURE [dbo].[UpdateProductGroupProducts]
(
	@ProductGroupID INTEGER,
	@ProductID INTEGER,
	@IsPrimary BIT 
)

AS

UPDATE	dbo.ProductGroupProducts
set IsPrimary = @IsPrimary
Where ProductGroupID = @ProductGroupID AND ProductID = @ProductID

IF @IsPrimary = 1
BEGIN
UPDATE	dbo.ProductGroupProducts
set IsPrimary = 0
Where ProductGroupID = @ProductGroupID AND ProductID <> @ProductID
END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateProductGroupProducts] TO PUBLIC
    AS [dbo];

