CREATE PROCEDURE dbo.AddContractLinkedBillingItem
(
	@ContractID				INT,
	@BillingItemID			INT,
	@LinkedBillingItemID	INT
)
AS

INSERT INTO dbo.ContractLinkedBillingItems
(ContractID, BillingItemID, LinkedBillingItemID)
VALUES
(@ContractID, @BillingItemID, @LinkedBillingItemID)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddContractLinkedBillingItem] TO PUBLIC
    AS [dbo];

