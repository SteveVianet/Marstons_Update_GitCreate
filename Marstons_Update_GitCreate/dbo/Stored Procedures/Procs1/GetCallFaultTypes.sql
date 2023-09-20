---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetCallFaultTypes

AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.GetCallFaultTypes



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallFaultTypes] TO PUBLIC
    AS [dbo];

