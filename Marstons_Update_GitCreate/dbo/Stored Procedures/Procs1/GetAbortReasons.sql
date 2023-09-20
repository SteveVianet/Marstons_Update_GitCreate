---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetAbortReasons

AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.GetAbortReasons



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAbortReasons] TO PUBLIC
    AS [dbo];

