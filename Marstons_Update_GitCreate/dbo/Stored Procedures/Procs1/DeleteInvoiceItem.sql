---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE DeleteInvoiceItem
(
	@CallID		INTEGER,
	@ItemID		INTEGER
)

AS

DELETE FROM InvoiceItems
WHERE CallID = @CallID
AND ItemID = @ItemID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteInvoiceItem] TO PUBLIC
    AS [dbo];

