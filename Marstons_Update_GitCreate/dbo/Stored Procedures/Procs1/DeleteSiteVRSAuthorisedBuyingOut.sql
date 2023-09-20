
CREATE PROCEDURE dbo.DeleteSiteVRSAuthorisedBuyingOut
(
	@ID					INT
)
AS

DELETE
FROM SiteVRSAuthorisedBuyingOut
WHERE ID = @ID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteSiteVRSAuthorisedBuyingOut] TO PUBLIC
    AS [dbo];

