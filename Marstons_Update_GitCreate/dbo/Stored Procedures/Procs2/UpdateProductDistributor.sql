CREATE PROCEDURE [dbo].[UpdateProductDistributor]
(
	@ProductID		INT,
	@DistributorID	INT
)

AS

UPDATE dbo.Products
SET	DistributorID = @DistributorID
WHERE [ID] = @ProductID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateProductDistributor] TO PUBLIC
    AS [dbo];

