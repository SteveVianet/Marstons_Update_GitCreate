---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[DeleteSiteProductCategorySpecification]
	@EDISID				INT,
	@ProductCategoryID	INT
AS

DELETE FROM SiteProductCategorySpecifications
WHERE EDISID = @EDISID
  AND ProductCategoryID = @ProductCategoryID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteSiteProductCategorySpecification] TO PUBLIC
    AS [dbo];

