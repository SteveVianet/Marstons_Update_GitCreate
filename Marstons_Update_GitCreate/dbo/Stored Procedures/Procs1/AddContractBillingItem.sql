CREATE PROCEDURE [dbo].[AddContractBillingItem]
(
	@ContractID				INT,
	@BillingItemID			INT,
	@IsCharged				BIT,
	@BMSRetailPrice			MONEY,
	@IDraughtRetailPrice	MONEY,
	@LabourTypeID			INT = NULL,
	@LabourMinutes			INT = NULL, 
	@LabourCharge			FLOAT = NULL,
	@PartsCharge			FLOAT = NULL
)
AS

INSERT INTO dbo.ContractBillingItems
(ContractID, BillingItemID, IsCharged, BMSRetailPrice, IDraughtRetailPrice, LabourTypeID, LabourMinutes, LabourCharge, PartsCharge)
VALUES
(@ContractID, @BillingItemID, @IsCharged, @BMSRetailPrice, @IDraughtRetailPrice, @LabourTypeID, @LabourMinutes, @LabourCharge, @PartsCharge)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddContractBillingItem] TO PUBLIC
    AS [dbo];

