CREATE PROCEDURE [dbo].[GetWebSiteDataUpTo]
(
	@EDISID			INT
)
AS

SELECT ISNULL(LastDownload, SiteOnline) AS DataUpTo
FROM dbo.Sites
WHERE EDISID = @EDISID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteDataUpTo] TO PUBLIC
    AS [dbo];

