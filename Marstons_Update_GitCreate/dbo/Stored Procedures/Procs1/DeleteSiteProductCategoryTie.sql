---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE DeleteSiteProductCategoryTie
(
	@EDISID 		INT,
	@ProductCategoryID	INT
)

AS

DELETE FROM SiteProductCategoryTies
WHERE EDISID = @EDISID
AND ProductCategoryID = @ProductCategoryID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteSiteProductCategoryTie] TO PUBLIC
    AS [dbo];

