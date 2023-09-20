---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetCallTypes

AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.GetCallTypes



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallTypes] TO PUBLIC
    AS [dbo];

