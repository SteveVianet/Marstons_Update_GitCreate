
CREATE PROCEDURE [dbo].[GetSiteSpecifications] 
(
	@EDISID 	INT = NULL
)

AS

SELECT	EDISID,
		CleanDaysBeforeAmber,
		CleanDaysBeforeRed
FROM dbo.SiteSpecifications
WHERE EDISID = @EDISID OR @EDISID IS NULL

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteSpecifications] TO PUBLIC
    AS [dbo];

