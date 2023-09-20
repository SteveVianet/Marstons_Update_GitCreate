CREATE PROCEDURE [dbo].[GetCallObservations]
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
		LabourMinutes,
		IsCharged,
		CallBillingItems.LabourTypeID
FROM dbo.CallBillingItems
JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.BillingItems AS BillingItems ON BillingItems.ID = CallBillingItems.BillingItemID
WHERE CallID = @CallID
AND BillingItems.ItemType = 2

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallObservations] TO PUBLIC
    AS [dbo];

