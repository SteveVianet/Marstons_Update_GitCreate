CREATE PROCEDURE dbo.GetContractLinkedBillingItems
(
	@ContractID				INT,
	@BillingItemID			INT
)
AS

SELECT	ContractID,
		BillingItemID,
		LinkedBillingItemID
FROM dbo.ContractLinkedBillingItems
WHERE ContractID = @ContractID
AND BillingItemID = @BillingItemID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetContractLinkedBillingItems] TO PUBLIC
    AS [dbo];

