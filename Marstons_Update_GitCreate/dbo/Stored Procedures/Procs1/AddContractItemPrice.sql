CREATE PROCEDURE dbo.AddContractItemPrice
(
	@ContractID		INT,
	@ItemID		INT,
	@Price			MONEY
)
AS

INSERT INTO dbo.ContractItemPrices
(ContractID, ItemID, Price)
VALUES
(@ContractID, @ItemID, @Price)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddContractItemPrice] TO PUBLIC
    AS [dbo];

