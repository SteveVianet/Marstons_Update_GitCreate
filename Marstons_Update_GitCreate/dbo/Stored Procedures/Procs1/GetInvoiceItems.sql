CREATE PROCEDURE GetInvoiceItems
(
	@CallID		INTEGER
)

AS

SELECT	ItemID,
	Quantity,
	Cost,
	VAT
FROM dbo.InvoiceItems
WHERE CallID = @CallID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetInvoiceItems] TO PUBLIC
    AS [dbo];

