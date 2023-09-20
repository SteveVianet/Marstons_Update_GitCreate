CREATE PROCEDURE [dbo].[GetProductsInProductDistributorCount]
(
		@DistributorID	INT
)

AS

SELECT Count(ID) as ProductCount
FROM dbo.Products
WHERE DistributorID = @DistributorID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetProductsInProductDistributorCount] TO PUBLIC
    AS [dbo];

