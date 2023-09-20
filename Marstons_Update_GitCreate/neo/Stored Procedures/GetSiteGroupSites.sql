CREATE PROCEDURE [neo].[GetSiteGroupSites]
(
	@SiteGroupID	INT = NULL
)

AS

SELECT	SiteGroupSites.EDISID,
	SiteGroupSites.SiteGroupID,
	IsPrimary,
	Name,
	SiteID
FROM dbo.SiteGroupSites
JOIN dbo.Sites on dbo.SiteGroupSites.EDISID = dbo.Sites.EDISID
WHERE (SiteGroupSites.SiteGroupID = @SiteGroupID OR @SiteGroupID IS NULL)

GO
GRANT EXECUTE
    ON OBJECT::[neo].[GetSiteGroupSites] TO PUBLIC
    AS [dbo];

