CREATE PROCEDURE DeleteProposedFontSetup
(
	@ID	INT
)

AS

DELETE FROM ProposedFontSetupCalibrationValues
WHERE ProposedFontSetupID = @ID

DELETE FROM ProposedFontSetupItems
WHERE ProposedFontSetupID = @ID

DELETE FROM ProposedFontSetups
WHERE [ID] = @ID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteProposedFontSetup] TO PUBLIC
    AS [dbo];

