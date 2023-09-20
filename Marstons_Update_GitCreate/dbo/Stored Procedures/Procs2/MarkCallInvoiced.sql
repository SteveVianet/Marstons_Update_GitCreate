---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE MarkCallInvoiced
(
	@CallID	INT
)

AS

UPDATE Calls
SET	InvoicedBy = SUSER_SNAME(),
	InvoicedOn = GETDATE()
WHERE [ID] = @CallID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[MarkCallInvoiced] TO PUBLIC
    AS [dbo];

