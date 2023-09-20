CREATE PROCEDURE [dbo].[GetSiteTimeZones]
(
	@Locale VARCHAR(6) = 'en-US'
)
AS

SELECT TZ.EDISID, TZ.TimeZone 
FROM
	(SELECT Sites.EDISID, SiteProperties.Value AS TimeZone
	FROM dbo.Sites
	JOIN dbo.SiteProperties ON SiteProperties.EDISID = Sites.EDISID
	JOIN dbo.Properties ON  Properties.ID = SiteProperties.PropertyID
	WHERE Properties.Name = 'TimeZone') AS TZ
JOIN
	(SELECT Sites.EDISID, SiteProperties.Value AS International
	FROM dbo.Sites
	JOIN dbo.SiteProperties ON SiteProperties.EDISID = Sites.EDISID
	JOIN dbo.Properties ON  Properties.ID = SiteProperties.PropertyID
	WHERE Properties.Name = 'International') AS US ON US.EDISID = TZ.EDISID
WHERE International = @Locale
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteTimeZones] TO PUBLIC
    AS [dbo];

