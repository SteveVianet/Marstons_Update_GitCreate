CREATE PROCEDURE [dbo].[GetAllProductAliases]
AS

SELECT ProductID,
	   UPPER(Alias) AS Alias,
	   VolumeMultiplier
FROM dbo.ProductAlias WITH (NOLOCK)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAllProductAliases] TO PUBLIC
    AS [dbo];

