CREATE PROCEDURE [dbo].[UpdateSiteGroupSites]
(
	@SiteGroupID INTEGER,
	@EDISID INTEGER,
	@IsPrimary BIT = 0
)

AS

UPDATE	dbo.SiteGroupSites
set IsPrimary = @IsPrimary
Where SiteGroupID = @SiteGroupID AND EDISID = @EDISID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteGroupSites] TO PUBLIC
    AS [dbo];

