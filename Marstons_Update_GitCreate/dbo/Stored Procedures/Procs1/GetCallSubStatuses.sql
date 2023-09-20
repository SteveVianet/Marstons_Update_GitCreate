---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetCallSubStatuses
(
	@StatusID	INT
)

AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.GetCallSubStatuses @StatusID



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallSubStatuses] TO PUBLIC
    AS [dbo];

