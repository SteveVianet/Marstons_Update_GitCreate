---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE DeleteSiteStockistCategory
(
	@EDISID		INT,
	@CategoryID	INT
)

AS

DELETE FROM SiteStockistCategories
WHERE EDISID = @EDISID
AND CategoryID = @CategoryID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteSiteStockistCategory] TO PUBLIC
    AS [dbo];

