CREATE PROCEDURE [dbo].[UpdateCallSalesReference]
(
	@CallID		INT,
	@SalesReference	VARCHAR(255)
)

AS

UPDATE dbo.Calls
SET SalesReference = @SalesReference
WHERE [ID] = @CallID

EXEC dbo.RefreshHandheldCall @CallID, 1, 1, 1

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallSalesReference] TO PUBLIC
    AS [dbo];

