CREATE PROCEDURE [dbo].[AddProductGroupProduct]

(
	@ProductID	INT,
	@ProductGroupID	INT,
	@IsPrimary	BIT
)

AS

SET NOCOUNT ON

INSERT INTO dbo.ProductGroupProducts
(ProductGroupID, ProductID, IsPrimary)
VALUES
(@ProductGroupID, @ProductID, @IsPrimary)

IF @IsPrimary = 1 
BEGIN
	DECLARE @ProductName VARCHAR(50)
	
	SELECT @ProductName = [Description]
	FROM Products 
	WHERE ID = @ProductID
	
	UPDATE dbo.ProductGroups
	SET [Description] = @ProductName
	WHERE ID = @ProductGroupID
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddProductGroupProduct] TO PUBLIC
    AS [dbo];

