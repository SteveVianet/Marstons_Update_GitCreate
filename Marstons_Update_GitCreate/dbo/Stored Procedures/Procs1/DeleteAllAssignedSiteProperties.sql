CREATE PROCEDURE DeleteAllAssignedSiteProperties
(
	@PropertyID	INT
)

AS

DELETE FROM SiteProperties
WHERE PropertyID = @PropertyID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteAllAssignedSiteProperties] TO PUBLIC
    AS [dbo];

