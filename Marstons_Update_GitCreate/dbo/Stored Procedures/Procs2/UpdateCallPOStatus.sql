CREATE PROCEDURE [dbo].[UpdateCallPOStatus]
(
	@CallID		INT,
	@POStatusID	INT
)

AS

SET NOCOUNT ON

UPDATE Calls
SET POStatusID = @POStatusID
WHERE [ID] = @CallID

EXEC dbo.RefreshHandheldCall @CallID, 1, 1, 1

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallPOStatus] TO PUBLIC
    AS [dbo];

