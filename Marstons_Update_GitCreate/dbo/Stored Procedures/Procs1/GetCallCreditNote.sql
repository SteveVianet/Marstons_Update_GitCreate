CREATE PROCEDURE [dbo].[GetCallCreditNote]
(
	@CallID			INT
)

AS

SELECT	TotalVolume,
	Reason,
	CreditDate,
	LicenseeName,
	LicenseeSignature,
	DateProcessed,
	SignatureBase64
FROM CallCreditNotes
WHERE CallID = @CallID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallCreditNote] TO PUBLIC
    AS [dbo];

