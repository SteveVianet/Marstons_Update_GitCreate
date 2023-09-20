CREATE PROCEDURE dbo.UpdateUserExtension 
(
	@Username	VARCHAR(50),
	@Extension	VARCHAR(15)
)
AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.UpdateUserExtension @Username, @Extension

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateUserExtension] TO PUBLIC
    AS [dbo];

