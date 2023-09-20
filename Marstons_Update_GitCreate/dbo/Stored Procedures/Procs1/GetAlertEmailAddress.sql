CREATE PROCEDURE dbo.GetAlertEmailAddress
(
	@DatabaseID		INTEGER
)
AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.GetAlertEmailAddress @DatabaseID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAlertEmailAddress] TO PUBLIC
    AS [dbo];

