
CREATE PROCEDURE [dbo].[DeleteSiteExceptionEmailAddresses]
(
	@EDISID			INT
)
AS

SET NOCOUNT ON

DELETE
FROM SiteExceptionEmailAddresses
WHERE EDISID = @EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteSiteExceptionEmailAddresses] TO PUBLIC
    AS [dbo];

