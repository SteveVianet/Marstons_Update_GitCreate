---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetCallStatuses

AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.GetCallStatuses



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallStatuses] TO PUBLIC
    AS [dbo];

