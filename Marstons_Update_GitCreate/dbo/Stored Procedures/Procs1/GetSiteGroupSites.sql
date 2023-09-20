CREATE PROCEDURE [dbo].[GetSiteGroupSites]
(
	@SiteGroupID	INT = NULL
)

AS

SELECT	SiteGroupSites.EDISID,
	SiteGroupSites.SiteGroupID,
	IsPrimary,
	Name
FROM dbo.SiteGroupSites
JOIN dbo.Sites on dbo.SiteGroupSites.EDISID = dbo.Sites.EDISID
WHERE (SiteGroupSites.SiteGroupID = @SiteGroupID OR @SiteGroupID IS NULL)
ORDER BY SiteID ASC
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteGroupSites] TO PUBLIC
    AS [dbo];

