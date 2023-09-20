CREATE PROCEDURE [dbo].[AddCallCompletionSheet]
(
	@CallID INT,
	@FontsWork BIT,
	@CellarClean BIT,
	@PowerDisruption BIT,
	@MinorWorksCertificate BIT,
	@CreditNoteIssued BIT,
	@Calibration BIT,
	@Verification BIT,
	@Uplift BIT,
	@Cooling BIT,
	@CreditRequired BIT,
	@TotalVolumeDispensed INT,
	@LicenseeName VARCHAR(255),
	@LicenseeSignature VARCHAR(1500),
	@SignatureDate DATETIME,
	@FlowmetersUsed INT,
	@FlowmetersRemoved INT,
	@CheckValvesUsed INT,
	@CheckValvesRemoved INT,
	@WorkCarriedOut VARCHAR(255),
	@TimeOnSite INT,
	@SigBase64 VARCHAR(MAX) = NULL
)

AS

INSERT INTO CallCompletionSheets
(CallID, FontsWork, CellarClean, PowerDisruption, MinorWorksCertificate, CreditNoteIssued, 
Calibration, Verification, Uplift, Cooling, CreditRequired, TotalVolumeDispensed,
LicenseeName, LicenseeSignature, SignatureDate, FlowmetersUsed, FlowmetersRemoved,
CheckValvesUsed, CheckValvesRemoved, WorkCarriedOut, TimeOnSite, SignatureBase64)
VALUES
(@CallID, @FontsWork, @CellarClean, @PowerDisruption, @MinorWorksCertificate, @CreditNoteIssued, 
@Calibration, @Verification, @Uplift, @Cooling, @CreditRequired, @TotalVolumeDispensed,
@LicenseeName, @LicenseeSignature, @SignatureDate, @FlowmetersUsed, @FlowmetersRemoved,
@CheckValvesUsed, @CheckValvesRemoved, @WorkCarriedOut, @TimeOnSite, @SigBase64)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddCallCompletionSheet] TO PUBLIC
    AS [dbo];

