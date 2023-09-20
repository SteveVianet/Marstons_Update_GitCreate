CREATE PROCEDURE AddInvoiceItem
(
	@CallID		INTEGER,
	@ItemID	INTEGER,
	@Quantity	FLOAT,
	@Cost		FLOAT = NULL,
	@VAT		FLOAT = NULL
)

AS

INSERT INTO dbo.InvoiceItems
(CallID, ItemID, Quantity, Cost, VAT)
VALUES
(@CallID, @ItemID, @Quantity, @Cost, @VAT)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddInvoiceItem] TO PUBLIC
    AS [dbo];

