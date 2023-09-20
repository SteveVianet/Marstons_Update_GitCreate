CREATE PROCEDURE [dbo].[GetSiteProductTies]
(
	@EDISID 	INT = NULL
)

AS

SELECT	SiteProductTies.EDISID,
	SiteProductTies.ProductID,
	SiteProductTies.Tied,
		Products.Description
FROM SiteProductTies
JOIN Products ON Products.[ID] = SiteProductTies.ProductID
WHERE EDISID = @EDISID OR @EDISID IS NULL
ORDER BY Products.[Description]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteProductTies] TO PUBLIC
    AS [dbo];

