
CREATE PROCEDURE [dbo].[UpdateCallInstallCallID]
(
	@CallID					INT,
	@InstallCallID			INT
)

AS

UPDATE dbo.Calls
SET InstallCallID = @InstallCallID
WHERE [ID] = @CallID

EXEC dbo.RefreshHandheldCall @CallID, 1, 1, 1

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallInstallCallID] TO PUBLIC
    AS [dbo];

