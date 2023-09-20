CREATE PROCEDURE [dbo].[GetGlobalSiteCount]

AS

SELECT COUNT(GlobalEDISID) AS SiteCount 
FROM Sites 
WHERE GlobalEDISID IS NOT NULL




GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetGlobalSiteCount] TO PUBLIC
    AS [dbo];

