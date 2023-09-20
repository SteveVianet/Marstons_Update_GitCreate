CREATE PROCEDURE dbo.NIS_GET_SITE_HCODE
(
	@EDISID	AS	INT
)
AS
SELECT Value AS HCode
FROM SiteProperties
	JOIN Properties ON Properties.ID = SiteProperties.PropertyID
WHERE (Properties.Name = 'NucleusID') AND (EDISID = @EDISID)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[NIS_GET_SITE_HCODE] TO PUBLIC
    AS [dbo];

