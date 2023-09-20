CREATE PROCEDURE GetSiteProperties
(
	@EDISID		INT,
	@PropertyName	VARCHAR(50) = NULL
)

AS

SELECT Properties.[Name] AS PropertyName,
	SiteProperties.Value
FROM dbo.SiteProperties
JOIN dbo.Properties ON Properties.[ID] = SiteProperties.PropertyID
WHERE EDISID = @EDISID AND (Properties.[Name] = @PropertyName OR @PropertyName IS NULL)
ORDER BY Properties.[ID]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteProperties] TO PUBLIC
    AS [dbo];

