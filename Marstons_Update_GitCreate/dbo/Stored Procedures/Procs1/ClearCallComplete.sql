---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE ClearCallComplete
(
	@CallID	INT
)

AS

UPDATE Calls
SET	ClosedBy = NULL,
	ClosedOn = NULL
WHERE [ID] = @CallID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ClearCallComplete] TO PUBLIC
    AS [dbo];

