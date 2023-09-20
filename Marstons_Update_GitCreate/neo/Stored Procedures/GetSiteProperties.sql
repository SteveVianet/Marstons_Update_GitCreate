CREATE PROCEDURE [neo].[GetSiteProperties]
(
	@EDISID		INT
)

AS

SELECT 
	EDISID,
	PropertyID,
	Value
FROM dbo.SiteProperties
WHERE EDISID = @EDISID 

GO
GRANT EXECUTE
    ON OBJECT::[neo].[GetSiteProperties] TO PUBLIC
    AS [dbo];

