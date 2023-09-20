CREATE PROCEDURE SetProposedFontSetupGlasswareStateID
(
	@ProposedFontSetupID	INT,
	@GlasswareStateID	INT
)

AS

UPDATE dbo.ProposedFontSetups
SET	GlasswareStateID = @GlasswareStateID
WHERE [ID] = @ProposedFontSetupID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SetProposedFontSetupGlasswareStateID] TO PUBLIC
    AS [dbo];

