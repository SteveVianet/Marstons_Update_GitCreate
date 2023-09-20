CREATE PROCEDURE [dbo].[UpdateCallRequestID]
(
	@CallID			INT,
	@RequestID		INT
)

AS

UPDATE dbo.Calls
SET RequestID = @RequestID
WHERE [ID] = @CallID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallRequestID] TO PUBLIC
    AS [dbo];

