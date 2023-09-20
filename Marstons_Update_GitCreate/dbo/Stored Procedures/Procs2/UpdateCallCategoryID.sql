CREATE PROCEDURE [dbo].[UpdateCallCategoryID]
(
	@CallID				INT,
	@CategoryID			INT
)

AS

UPDATE dbo.Calls
SET CallCategoryID = @CategoryID
WHERE [ID] = @CallID

EXEC dbo.RefreshHandheldCall @CallID, 1, 1, 1

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallCategoryID] TO PUBLIC
    AS [dbo];

