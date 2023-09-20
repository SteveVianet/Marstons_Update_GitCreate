---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE DeleteSiteGroupSite
(
	@EDISID		INT,
	@SiteGroupID	INT
)

AS

DELETE FROM dbo.SiteGroupSites
WHERE EDISID = @EDISID
AND SiteGroupID = @SiteGroupID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteSiteGroupSite] TO PUBLIC
    AS [dbo];

