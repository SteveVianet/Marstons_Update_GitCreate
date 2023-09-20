CREATE PROCEDURE [dbo].[GetProductAliases]
(
	@ProductID	INT = null
)

AS

IF(@ProductID IS NOT NULL)
BEGIN
SELECT UPPER(Alias) AS Alias,
       VolumeMultiplier,
	   	 CreatedBy,
	 CreatedOn

FROM dbo.ProductAlias
WHERE ProductID = @ProductID
END

ELSE
BEGIN
SELECT 
	ProductID,
	UPPER(Alias) AS Alias,
     VolumeMultiplier,
	 CreatedBy,
	 CreatedOn

FROM dbo.ProductAlias
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetProductAliases] TO PUBLIC
    AS [dbo];

