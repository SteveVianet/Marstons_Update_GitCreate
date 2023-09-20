---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE RollbackItemPriceToMaster
(
	@ContractID	INT = NULL,
	@ItemID		INT
)

AS

BEGIN TRAN
	IF @ContractID IS NOT NULL
	BEGIN
		DELETE FROM ContractItemPrices
		WHERE ContractID = @ContractID
		AND ItemID = @ItemID
	END
	
	DELETE FROM ItemPrices
	WHERE ItemID = @ItemID
	
COMMIT


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[RollbackItemPriceToMaster] TO PUBLIC
    AS [dbo];

