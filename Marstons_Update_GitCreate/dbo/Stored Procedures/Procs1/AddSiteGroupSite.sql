CREATE PROCEDURE [dbo].[AddSiteGroupSite]
(
	@EDISID		INT,
	@SiteGroupID	INT,
	@IsPrimary BIT = 0
)

AS

INSERT INTO dbo.SiteGroupSites
(EDISID, SiteGroupID, IsPrimary)
VALUES
(@EDISID, @SiteGroupID, @IsPrimary)
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSiteGroupSite] TO PUBLIC
    AS [dbo];

