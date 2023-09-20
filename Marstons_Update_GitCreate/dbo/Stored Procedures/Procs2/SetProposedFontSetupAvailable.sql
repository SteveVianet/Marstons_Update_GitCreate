CREATE PROCEDURE [dbo].[SetProposedFontSetupAvailable]
(
	@ProposedFontSetupID	INT,
	@Available		BIT
)

AS

DECLARE @NewGlasswareID INT

UPDATE dbo.ProposedFontSetups
SET	Available = @Available,
	Completed = 0
WHERE [ID] = @ProposedFontSetupID

--Update font setup glassware state
EXEC [UpdateSiteProposedFontSetupCalibrationDetails] NULL, @ProposedFontSetupID, @NewGlasswareID OUTPUT

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SetProposedFontSetupAvailable] TO PUBLIC
    AS [dbo];

