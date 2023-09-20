---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE DeleteSitePointsCategory
(
	@EDISID		INT,
	@CategoryID	INT
)

AS

DELETE FROM SitePointsCategories
WHERE EDISID = @EDISID
AND CategoryID = @CategoryID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteSitePointsCategory] TO PUBLIC
    AS [dbo];

