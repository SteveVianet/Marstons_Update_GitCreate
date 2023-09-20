CREATE PROCEDURE NUCLEUS_GetSitebyCallID
(
	@CallID	INT
)

AS

SELECT SiteProperties.Value AS NucleusID
FROM SiteProperties
JOIN Calls ON Calls.EDISID = SiteProperties.EDISID
JOIN Properties ON Properties.[ID] = SiteProperties.PropertyID
WHERE Calls.[ID] = @CallID
AND Properties.[Name] = 'NucleusID'
