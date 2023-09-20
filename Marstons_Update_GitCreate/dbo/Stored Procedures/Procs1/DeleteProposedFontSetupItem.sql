CREATE PROCEDURE DeleteProposedFontSetupItem
(
	@ProposedFontSetupID	INT,
	@FontNumber		INT
)

AS

DELETE FROM ProposedFontSetupCalibrationValues
WHERE ProposedFontSetupID = @ProposedFontSetupID
AND FontNumber = @FontNumber

DELETE FROM ProposedFontSetupItems
WHERE ProposedFontSetupID = @ProposedFontSetupID
AND FontNumber = @FontNumber

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteProposedFontSetupItem] TO PUBLIC
    AS [dbo];

