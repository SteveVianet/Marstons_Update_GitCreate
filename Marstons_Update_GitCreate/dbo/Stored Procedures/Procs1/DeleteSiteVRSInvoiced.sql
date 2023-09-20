
CREATE PROCEDURE dbo.DeleteSiteVRSInvoiced
(
	@ID					INT
)
AS

DELETE
FROM SiteVRSInvoiced
WHERE ID = @ID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteSiteVRSInvoiced] TO PUBLIC
    AS [dbo];

