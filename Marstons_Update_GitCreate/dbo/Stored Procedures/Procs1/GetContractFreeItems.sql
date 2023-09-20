---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetContractFreeItems
(
	@ContractID INT
)

AS

SELECT [ItemID]
FROM ContractFreeItems
WHERE [ContractID] = @ContractID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetContractFreeItems] TO PUBLIC
    AS [dbo];

