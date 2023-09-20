CREATE PROCEDURE [dbo].[GetCallIncompleteReasons]
AS

EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.GetCallIncompleteReasons

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallIncompleteReasons] TO PUBLIC
    AS [dbo];

