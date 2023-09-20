---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE SetContractItemPrice
(
	@ContractID	INT,
	@ItemID		INT,
	@NewPrice	MONEY
)

AS

IF EXISTS(SELECT ItemID FROM ContractItemPrices WHERE ContractID = @ContractID AND ItemID = @ItemID)
	UPDATE ContractItemPrices
	SET Price = @NewPrice
	WHERE ContractID = @ContractID
	AND ItemID = @ItemID
ELSE
	INSERT INTO ContractItemPrices
	(ContractID, ItemID, Price)
	VALUES
	(@ContractID, @ItemID, @NewPrice)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SetContractItemPrice] TO PUBLIC
    AS [dbo];

