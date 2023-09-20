---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetWorkItems

AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.GetWorkItems


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWorkItems] TO PUBLIC
    AS [dbo];

