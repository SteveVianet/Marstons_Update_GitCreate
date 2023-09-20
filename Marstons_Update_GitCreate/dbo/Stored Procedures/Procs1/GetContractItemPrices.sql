CREATE PROCEDURE dbo.GetContractItemPrices
(
	@ContractID			INT,
	@ShowHistoricalPrices		BIT = 0
)

AS

IF @ShowHistoricalPrices = 1
BEGIN
	SELECT	ItemID,
		Price,
		ValidTo
	FROM dbo.ContractItemPrices
	WHERE ContractID = @ContractID
END
ELSE
BEGIN
	SELECT	ItemID,
		Price,
		ValidTo
	FROM dbo.ContractItemPrices
	WHERE ContractID = @ContractID
	AND ValidTo IS NULL

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetContractItemPrices] TO PUBLIC
    AS [dbo];

