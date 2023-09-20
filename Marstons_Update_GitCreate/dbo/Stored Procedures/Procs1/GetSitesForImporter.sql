CREATE PROCEDURE [dbo].[GetSitesForImporter]

AS

-- Get the site details.
SELECT	Sites.EDISID,
		SiteID
FROM dbo.Sites WITH (NOLOCK)
WHERE (Hidden = 0) -- Only Visible Sites


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSitesForImporter] TO PUBLIC
    AS [dbo];

