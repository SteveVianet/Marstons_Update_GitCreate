

CREATE PROCEDURE dbo.DeleteAlertSite
(
	@DatabaseID		INT,
	@EDISID		INT
)
AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.DeleteAlertSite @DatabaseID, @EDISID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteAlertSite] TO PUBLIC
    AS [dbo];

