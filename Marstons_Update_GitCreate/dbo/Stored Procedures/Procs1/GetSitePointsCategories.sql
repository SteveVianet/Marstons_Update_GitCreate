---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetSitePointsCategories
(
	@EDISID	INT
)

AS

SELECT	EDISID,
	CategoryID,
	Points
FROM SitePointsCategories
WHERE EDISID = @EDISID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSitePointsCategories] TO PUBLIC
    AS [dbo];

