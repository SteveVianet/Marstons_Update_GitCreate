CREATE PROCEDURE [dbo].[DeleteCallsForSite]
(
	@EDISID	INT
)

AS

SET XACT_ABORT ON

DECLARE @Calls TABLE(ID INT NOT NULL)

-- Get list of call IDs for deletion
INSERT INTO @Calls
(ID)
SELECT ID
FROM Calls
WHERE EDISID = @EDISID

BEGIN TRAN

-- Calls
DELETE
FROM CallComments
WHERE CallID IN (SELECT ID FROM @Calls)

DELETE
FROM CallActions
WHERE CallID IN (SELECT ID FROM @Calls)

DELETE
FROM CallFaults
WHERE CallID IN (SELECT ID FROM @Calls)

DELETE
FROM CallStatusHistory
WHERE CallID IN (SELECT ID FROM @Calls)

DELETE
FROM CallWorkItems
WHERE CallID IN (SELECT ID FROM @Calls)

DELETE
FROM InvoiceItems
WHERE CallID IN (SELECT ID FROM @Calls)

DELETE
FROM SupplementaryCallStatusItems
WHERE CallID IN (SELECT ID FROM @Calls)

DELETE
FROM PATTracking
WHERE CallID IN (SELECT ID FROM @Calls)

DELETE
FROM CallWorkDetailComments
WHERE CallID IN (SELECT ID FROM @Calls)

DELETE
FROM CallLines
WHERE CallID IN (SELECT ID FROM @Calls)

DELETE
FROM CallCompletionSheets
WHERE CallID IN (SELECT ID FROM @Calls)

DELETE
FROM CallCreditNotes
WHERE CallID IN (SELECT ID FROM @Calls)

DELETE
FROM CallTampers
WHERE CallID IN (SELECT ID FROM @Calls)

DELETE
FROM CallSiteStocks
WHERE CallID IN (SELECT ID FROM @Calls)

--ProposedFontSetups are not deleted, but their Call reference is.
UPDATE ProposedFontSetups 
SET CallID = NULL
WHERE CallID IN (SELECT ID FROM @Calls)

DELETE
FROM Calls
WHERE EDISID = @EDISID

COMMIT

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteCallsForSite] TO PUBLIC
    AS [dbo];

