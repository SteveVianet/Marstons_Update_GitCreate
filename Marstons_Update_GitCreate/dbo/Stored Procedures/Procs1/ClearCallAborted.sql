---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE ClearCallAborted
(
	@CallID		INT
)

AS

UPDATE dbo.Calls
SET	AbortReasonID	= 0,
	AbortDate	= NULL,
	AbortUser	= NULL,
	AbortCode	= NULL
WHERE [ID] = @CallID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ClearCallAborted] TO PUBLIC
    AS [dbo];

