---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetSiteProductCategoryTies
(
	@EDISID 	INT = NULL
)

AS

SELECT	SiteProductCategoryTies.EDISID,
	SiteProductCategoryTies.ProductCategoryID,
	SiteProductCategoryTies.Tied
FROM SiteProductCategoryTies
JOIN ProductCategories ON ProductCategories.[ID] = SiteProductCategoryTies.ProductCategoryID
WHERE EDISID = @EDISID OR @EDISID IS NULL
ORDER BY ProductCategories.[Description]


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteProductCategoryTies] TO PUBLIC
    AS [dbo];

