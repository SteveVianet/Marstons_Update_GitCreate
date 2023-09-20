---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE RollbackItemPriceToCustomer
(
	@ContractID	INT,
	@ItemID		INT
)

AS

DELETE FROM ContractItemPrices
WHERE ContractID = @ContractID
AND ItemID = @ItemID
	

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[RollbackItemPriceToCustomer] TO PUBLIC
    AS [dbo];

