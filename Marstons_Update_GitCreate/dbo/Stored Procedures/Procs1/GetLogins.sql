---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetLogins

AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.GetLogins



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetLogins] TO PUBLIC
    AS [dbo];

