CREATE PROCEDURE [dbo].[DeleteCall]
(
	@CallID	INT
)

AS

SET XACT_ABORT ON

BEGIN TRAN

DELETE
FROM CallComments
WHERE CallID = @CallID

DELETE
FROM CallActions
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
FROM PATTracking
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
FROM CallCreditNotes
WHERE CallID = @CallID

DELETE
FROM CallTampers
WHERE CallID = @CallID

DELETE
FROM CallSiteStocks
WHERE CallID = @CallID

--ProposedFontSetups are not deleted, but their Call reference is.
UPDATE ProposedFontSetups 
SET CallID = NULL
WHERE CallID = @CallID

COMMIT
