CREATE PROCEDURE [dbo].[ClearCallIncomplete]
(
	@CallID		INT
)

AS

UPDATE dbo.Calls
SET	IncompleteReasonID	= 0,
	IncompleteDate	= NULL
WHERE [ID] = @CallID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ClearCallIncomplete] TO PUBLIC
    AS [dbo];

