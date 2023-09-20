
CREATE PROCEDURE [dbo].[DeleteSiteSpecification]
(
	@EDISID 	INT
)

AS

SET NOCOUNT ON

DELETE FROM dbo.SiteSpecifications
WHERE EDISID = @EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteSiteSpecification] TO PUBLIC
    AS [dbo];

