CREATE PROCEDURE [neo].[GetSiteGroups]
(
	@SiteGroupID	INT = NULL,
	@EDISID         INT = NULL
)

AS

SELECT
    [SG].[ID],
	[SG].[Description],
	[SG].[TypeID]
FROM [dbo].[SiteGroups] AS [SG]
JOIN [dbo].[SiteGroupSites] AS [SGS] ON [SG].[ID] = [SGS].[SiteGroupID]
WHERE 
    (@SiteGroupID is NULL OR [SG].[ID] = @SiteGroupID) 
AND (@EDISID IS NULL OR [SGS].[EDISID] = @EDISID)
GROUP BY
    [SG].[ID],
	[SG].[Description],
	[SG].[TypeID]
ORDER BY [SG].[Description]

GO
GRANT EXECUTE
    ON OBJECT::[neo].[GetSiteGroups] TO PUBLIC
    AS [dbo];

