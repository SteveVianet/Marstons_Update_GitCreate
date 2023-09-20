CREATE PROCEDURE [dbo].[GetContractBillingItems]
(
	@ContractID		INT
)
AS

SELECT	ContractID,
		BillingItemID,
		IsCharged,
		BMSRetailPrice,
		IDraughtRetailPrice,
		LabourTypeID,
		LabourMinutes,
		LabourCharge,
		PartsCharge
FROM dbo.ContractBillingItems
WHERE ContractID = @ContractID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetContractBillingItems] TO PUBLIC
    AS [dbo];

