---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetSupplementaryCallStatuses
(
	@CallTypeID	INT = NULL
)

AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.GetSupplementaryCallStatuses @CallTypeID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSupplementaryCallStatuses] TO PUBLIC
    AS [dbo];

