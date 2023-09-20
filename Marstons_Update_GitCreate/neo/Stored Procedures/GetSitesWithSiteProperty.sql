CREATE PROCEDURE [neo].[GetSitesWithSiteProperty]
(
	@PropertyName	VARCHAR(50),
	@Value VARCHAR(50) = NULL
)

AS

SELECT SiteProperties.EDISID
FROM dbo.SiteProperties
JOIN dbo.Properties ON Properties.[ID] = SiteProperties.PropertyID
WHERE Properties.[Name] = @PropertyName AND (SiteProperties.Value = @Value OR @Value IS NULL)
ORDER BY Properties.[ID]
GO
GRANT EXECUTE
    ON OBJECT::[neo].[GetSitesWithSiteProperty] TO PUBLIC
    AS [dbo];

