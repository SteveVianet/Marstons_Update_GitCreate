CREATE PROCEDURE [dbo].[UpdateCallIncompleteReasonID]
(
	@CallID					INT,
	@IncompleteReasonID		INT
)

AS

UPDATE dbo.Calls
SET IncompleteReasonID = @IncompleteReasonID
WHERE [ID] = @CallID

EXEC dbo.RefreshHandheldCall @CallID, 1, 1, 1

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallIncompleteReasonID] TO PUBLIC
    AS [dbo];

