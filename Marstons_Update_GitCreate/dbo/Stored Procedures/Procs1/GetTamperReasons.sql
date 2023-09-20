---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetTamperReasons

AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.ENG_GetTamperReasons


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTamperReasons] TO PUBLIC
    AS [dbo];

