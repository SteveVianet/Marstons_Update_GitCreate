---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetCallPOStatuses

AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.GetCallPOStatuses



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallPOStatuses] TO PUBLIC
    AS [dbo];

