CREATE PROCEDURE [dbo].[UpdateCallContractor]
(
	@CallID		INT,
	@EngineerID	INT
)

AS

UPDATE dbo.Calls
SET EngineerID = @EngineerID
WHERE [ID] = @CallID

--Refresh call on Handheld database if applicable
EXEC dbo.RefreshHandheldCall @CallID, 1, 1, 1
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallContractor] TO PUBLIC
    AS [dbo];

