CREATE PROCEDURE [dbo].[GetCallCompletionSheet]
(
	@CallID INT
)

AS

SELECT 	FontsWork,
	CellarClean,
	PowerDisruption,
	MinorWorksCertificate,
	CreditNoteIssued,
	Calibration,
	Verification,
	Uplift,
	Cooling,
	CreditRequired,
	TotalVolumeDispensed,
	LicenseeName,
	LicenseeSignature,
	SignatureDate,
	FlowmetersUsed,
	FlowmetersRemoved,
	CheckValvesUsed,
	CheckValvesRemoved,
	WorkCarriedOut,
	TimeOnSite,
	SignatureBase64
FROM CallCompletionSheets
WHERE CallID = @CallID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallCompletionSheet] TO PUBLIC
    AS [dbo];

