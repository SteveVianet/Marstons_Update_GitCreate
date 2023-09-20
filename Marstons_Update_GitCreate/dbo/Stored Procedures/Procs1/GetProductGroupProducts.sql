CREATE PROCEDURE [dbo].[GetProductGroupProducts]
(
	@ProductGroupID	INT = NULL
)

AS

SELECT ProductID, Description, IsPrimary
FROM dbo.ProductGroupProducts
join Products on ProductGroupProducts.ProductID = Products.ID
WHERE ProductGroupID = @ProductGroupID
OR @ProductGroupID IS NULL
Order by IsPrimary desc
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetProductGroupProducts] TO PUBLIC
    AS [dbo];

