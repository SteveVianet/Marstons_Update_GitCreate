CREATE PROCEDURE GetSitesByPropertyValue
(
	@PropertyID INT,
	@PropertyValue VARCHAR(255)
)

AS

SELECT Sites.EDISID
FROM Sites
JOIN SiteProperties ON SiteProperties.EDISID = Sites.EDISID
WHERE SiteProperties.PropertyID = @PropertyID
AND SiteProperties.Value = @PropertyValue


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSitesByPropertyValue] TO PUBLIC
    AS [dbo];

