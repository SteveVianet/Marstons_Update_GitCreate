CREATE PROCEDURE dbo.AddAlertEmailAddress
(
	@DatabaseID		INTEGER,
	@EmailAddress		VARCHAR(100)
)
AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.AddAlertEmailAddress @DatabaseID, @EmailAddress

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddAlertEmailAddress] TO PUBLIC
    AS [dbo];

