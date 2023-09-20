CREATE PROCEDURE [dbo].[GetContractChangeLog]
(
	@ContractID					INT,
	@ShowContractChanges		BIT = 1,
	@ShowBillingItemChanges		BIT = 1,
	@ShowCallReasonChanges		BIT = 1,
	@ShowContractSiteChanges	BIT = 1,
	@ShowMaintenanceChanges		BIT = 1
)
AS

SELECT	ContractID,
		ItemType,
		ChangeDate,
		[User],
		[Description]
FROM dbo.ContractChangeLog
WHERE ContractID = @ContractID
AND ((ItemType = 'Contract' AND @ShowContractChanges = 1)
OR (ItemType = 'Contract Billing Item' AND @ShowBillingItemChanges = 1)
OR (ItemType = 'Call Reason' AND @ShowCallReasonChanges = 1)
OR (ItemType = 'Site Contract' AND @ShowContractSiteChanges = 1)
OR (ItemType = 'Maintenance' AND @ShowMaintenanceChanges = 1))
ORDER BY ChangeDate DESC

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetContractChangeLog] TO PUBLIC
    AS [dbo];

