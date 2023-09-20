CREATE PROCEDURE [dbo].[UpdateCallContractID]
(
	@CallID			INT,
	@ContractID		INT
)

AS

UPDATE dbo.Calls
SET ContractID = @ContractID
WHERE [ID] = @CallID

EXEC dbo.RefreshHandheldCall @CallID, 1, 1, 1

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallContractID] TO PUBLIC
    AS [dbo];

