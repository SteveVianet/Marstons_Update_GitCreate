CREATE PROCEDURE [dbo].[UpdateCallCreditNote]
(
	@CallID			INT,
	@TotalVolume		INT,
	@Reason			VARCHAR(255),
	@CreditDate		DATETIME,
	@LicenseeName		VARCHAR(50),
	@LicenseeSignature	VARCHAR(1500),
	@SignatureBase64	VARCHAR(MAX) = NULL
)

AS

UPDATE CallCreditNotes
SET	TotalVolume = @TotalVolume,
	Reason = @Reason,
	CreditDate = @CreditDate,
	LicenseeName = @LicenseeName,
	LicenseeSignature =  @LicenseeSignature,
	SignatureBase64 = @SignatureBase64
WHERE CallID = @CallID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallCreditNote] TO PUBLIC
    AS [dbo];

