CREATE PROCEDURE [dbo].[GetProposedFontSetupItemCalibrationValues]
(
	@ProposedFontSetupID	INT,
	@FontNumber		INT = NULL
)

AS

SELECT	Reading,
		Pulses,
		Volume,
		Selected,
		FontNumber
FROM ProposedFontSetupCalibrationValues
WHERE ProposedFontSetupID = @ProposedFontSetupID
AND ( (FontNumber = @FontNumber) OR (@FontNumber IS NULL) )
ORDER BY Reading


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetProposedFontSetupItemCalibrationValues] TO PUBLIC
    AS [dbo];

