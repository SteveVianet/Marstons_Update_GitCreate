CREATE PROCEDURE [dbo].[IT_PermanentlyDeleteCall]
(
	@CallID	INT
)

AS

-- Calls
DELETE
FROM CallComments
WHERE CallID = @CallID

DELETE
FROM CallActions
WHERE CallID = @CallID

DELETE
FROM CallBillingItems
WHERE CallID = @CallID

DELETE
FROM CallFaults
WHERE CallID = @CallID

DELETE
FROM CallStatusHistory
WHERE CallID = @CallID

DELETE
FROM CallWorkItems
WHERE CallID = @CallID

DELETE
FROM InvoiceItems
WHERE CallID = @CallID

DELETE
FROM SupplementaryCallStatusItems
WHERE CallID = @CallID

DELETE
FROM CallWorkDetailComments
WHERE CallID = @CallID

DELETE
FROM CallLines
WHERE CallID = @CallID

DELETE
FROM CallCompletionSheets
WHERE CallID = @CallID

DELETE
FROM CallReasons
WHERE CallID = @CallID

DELETE
FROM CallCreditNotes
WHERE CallID = @CallID

DELETE
FROM CallSiteStocks
WHERE CallID = @CallID

DELETE 
FROM CallTampers
WHERE CallID = @CallID

DELETE
FROM ServiceIssuesEquipment
WHERE CallID = @CallID

DELETE
FROM ServiceIssuesQuality
WHERE CallID = @CallID

DELETE
FROM ServiceIssuesYield
WHERE CallID = @CallID

DELETE
FROM PATTracking
WHERE CallID = @CallID

UPDATE ProposedFontSetups
SET CallID = NULL
WHERE CallID = @CallID

DELETE 
FROM SystemStock
WHERE CallID = @CallID

DELETE
FROM Calls
WHERE ID = @CallID
