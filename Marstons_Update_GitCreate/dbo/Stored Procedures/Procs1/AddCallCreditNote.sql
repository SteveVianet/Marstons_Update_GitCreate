CREATE PROCEDURE [dbo].[AddCallCreditNote]
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

INSERT INTO CallCreditNotes
(CallID, TotalVolume, Reason, CreditDate, LicenseeName, LicenseeSignature, DateProcessed, SignatureBase64)
VALUES
(@CallID, @TotalVolume, @Reason, @CreditDate, @LicenseeName, @LicenseeSignature, GETDATE(), @SignatureBase64)
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddCallCreditNote] TO PUBLIC
    AS [dbo];

