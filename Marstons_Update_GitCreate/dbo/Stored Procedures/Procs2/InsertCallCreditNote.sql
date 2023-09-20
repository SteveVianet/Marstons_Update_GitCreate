CREATE PROCEDURE [dbo].[InsertCallCreditNote]
(
	@CallID			INT,
	@TotalVolume	INT,
	@Reason			VARCHAR(255),
	@CreditDate		DATETIME,
	@LicenseeName		VARCHAR(50),
	@LicenseeSignature	VARCHAR(1500),
	@DateProcessed	DATETIME = NULL
)

AS

INSERT INTO CallCreditNotes
(CallID, TotalVolume, Reason, CreditDate, LicenseeName, LicenseeSignature, DateProcessed)
VALUES
(@CallID, @TotalVolume, @Reason, @CreditDate, @LicenseeName, @LicenseeSignature, @DateProcessed)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[InsertCallCreditNote] TO PUBLIC
    AS [dbo];

