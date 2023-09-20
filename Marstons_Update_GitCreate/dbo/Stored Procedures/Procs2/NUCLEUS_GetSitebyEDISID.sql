CREATE PROCEDURE NUCLEUS_GetSitebyEDISID
(
	@EDISID	INT
)

AS

SELECT SiteProperties.Value AS NucleusID
FROM SiteProperties
JOIN Properties ON Properties.[ID] = SiteProperties.PropertyID
WHERE SiteProperties.EDISID = @EDISID
AND Properties.[Name] = 'NucleusID'
