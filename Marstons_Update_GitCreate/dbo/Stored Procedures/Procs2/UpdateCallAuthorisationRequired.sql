CREATE PROCEDURE [dbo].[UpdateCallAuthorisationRequired]
(
	@CallID					INT,
	@AuthorisationRequired	BIT
)

AS

SET NOCOUNT ON

UPDATE dbo.Calls
SET AuthorisationRequired = @AuthorisationRequired
WHERE [ID] = @CallID

EXEC dbo.RefreshHandheldCall @CallID, 1, 1, 1

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallAuthorisationRequired] TO PUBLIC
    AS [dbo];

