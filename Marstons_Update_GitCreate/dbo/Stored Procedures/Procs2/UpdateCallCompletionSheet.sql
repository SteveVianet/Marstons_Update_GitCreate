CREATE PROCEDURE [dbo].[UpdateCallCompletionSheet]
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

UPDATE CallCompletionSheets
SET	FontsWork = @FontsWork,
	CellarClean = @CellarClean,
	PowerDisruption = @PowerDisruption,
	MinorWorksCertificate = @MinorWorksCertificate,
	CreditNoteIssued = @CreditNoteIssued,
	Calibration = @Calibration,
	Verification = @Verification,
	Uplift = @Uplift,
	Cooling = @Cooling,
	CreditRequired = @CreditRequired,
	TotalVolumeDispensed = @TotalVolumeDispensed,
	LicenseeName = @LicenseeName,
	LicenseeSignature = @LicenseeSignature,
	SignatureDate = @SignatureDate,
	FlowmetersUsed = @FlowmetersUsed,
	FlowmetersRemoved = @FlowmetersRemoved,
	CheckValvesUsed = @CheckValvesUsed,
	CheckValvesRemoved = @CheckValvesRemoved,
	WorkCarriedOut = @WorkCarriedOut,
	TimeOnSite = @TimeOnSite,
	SignatureBase64 = @SigBase64
WHERE CallID = @CallID

EXEC dbo.RefreshHandheldCall @CallID, 1, 1, 1

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallCompletionSheet] TO PUBLIC
    AS [dbo];

