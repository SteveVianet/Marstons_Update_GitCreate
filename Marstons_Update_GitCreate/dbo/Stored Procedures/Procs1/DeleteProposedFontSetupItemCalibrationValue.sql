---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE DeleteProposedFontSetupItemCalibrationValue
(
	@ProposedFontSetupID	INT,
	@FontNumber		INT,
	@Reading		INT
)

AS

DELETE FROM ProposedFontSetupCalibrationValues
WHERE ProposedFontSetupID = @ProposedFontSetupID
AND FontNumber = @FontNumber
AND Reading = @Reading


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteProposedFontSetupItemCalibrationValue] TO PUBLIC
    AS [dbo];

