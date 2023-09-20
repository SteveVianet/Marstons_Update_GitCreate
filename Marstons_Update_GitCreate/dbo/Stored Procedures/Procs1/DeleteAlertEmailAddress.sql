CREATE PROCEDURE dbo.DeleteAlertEmailAddress
(
	@DatabaseID		INTEGER,
	@EmailAddress		VARCHAR(100)
)
AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.DeleteAlertEmailAddress @DatabaseID, @EmailAddress


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteAlertEmailAddress] TO PUBLIC
    AS [dbo];

