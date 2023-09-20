CREATE PROCEDURE [dbo].[GetCallBillingItems]
(
	@CallID		INT
)
AS

SET NOCOUNT ON


SELECT	CallID,
		BillingItemID,
		Quantity,
		FullCostPrice,
		FullRetailPrice,
		VAT,
		ContractID,
		CallBillingItems.LabourMinutes,
		IsCharged,
		CallBillingItems.LabourTypeID
FROM dbo.CallBillingItems
JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.BillingItems AS BillingItems  ON BillingItems.ID = CallBillingItems.BillingItemID
WHERE CallID = @CallID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallBillingItems] TO PUBLIC
    AS [dbo];

