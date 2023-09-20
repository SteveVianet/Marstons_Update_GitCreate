CREATE PROCEDURE dbo.UpdateCallTelecomReference
(
	@CallID			INT,
	@TelecomReference		VARCHAR(255)
)

AS

UPDATE dbo.Calls
SET TelecomReference = @TelecomReference
WHERE [ID] = @CallID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallTelecomReference] TO PUBLIC
    AS [dbo];

