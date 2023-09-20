CREATE PROCEDURE dbo.GetUserExtension
(
	@Username	VARCHAR(50)
)
AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.GetUserExtension @Username

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetUserExtension] TO PUBLIC
    AS [dbo];

