CREATE PROCEDURE dbo.AddAlertSite
(
	@DatabaseID		INT,
	@EDISID		INT
)
AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.AddAlertSite @DatabaseID, @EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddAlertSite] TO PUBLIC
    AS [dbo];

