CREATE PROCEDURE [dbo].[DeleteContractLinkedBillingItem]
(
	@ContractID				INT,
	@BillingItemID			INT,
	@LinkedBillingItemID	INT
)
AS

DELETE
FROM dbo.ContractLinkedBillingItems
WHERE ContractID = @ContractID
AND BillingItemID = @BillingItemID
AND LinkedBillingItemID = @LinkedBillingItemID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteContractLinkedBillingItem] TO PUBLIC
    AS [dbo];

