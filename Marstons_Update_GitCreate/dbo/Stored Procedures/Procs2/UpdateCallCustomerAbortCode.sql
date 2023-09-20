CREATE PROCEDURE [dbo].[UpdateCallCustomerAbortCode]
(
	@CallID			INT,
	@CustomerAbortCode	VARCHAR(255)
)

AS

UPDATE dbo.Calls
SET CustomerAbortCode = @CustomerAbortCode
WHERE [ID] = @CallID

EXEC dbo.RefreshHandheldCall @CallID, 1, 1, 1

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallCustomerAbortCode] TO PUBLIC
    AS [dbo];

