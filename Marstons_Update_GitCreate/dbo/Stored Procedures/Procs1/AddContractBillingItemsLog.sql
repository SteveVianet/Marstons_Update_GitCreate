
CREATE PROCEDURE dbo.AddContractBillingItemsLog
(
	@ContractID INT,
	@BillingItemID INT,
	@OldIsCharged BIT,
	@OldBMSRetailPrice MONEY,
	@OldIDraughtRetailPrice MONEY
)
AS

INSERT INTO dbo.ContractBillingItemsLog
(ChangeDate, [User], ContractID, BillingItemID, OldIsCharged, OldBMSRetailPrice, OldIDraughtRetailPrice)
VALUES
(CURRENT_TIMESTAMP, SUSER_NAME(), @ContractID, @BillingItemID, @OldIsCharged, @OldBMSRetailPrice, @OldIDraughtRetailPrice)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddContractBillingItemsLog] TO PUBLIC
    AS [dbo];

