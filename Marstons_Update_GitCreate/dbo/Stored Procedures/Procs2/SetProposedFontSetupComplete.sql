---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE SetProposedFontSetupComplete
(
	@ProposedFontSetupID	INT,
	@Completed		BIT
)

AS

UPDATE ProposedFontSetups
SET	Completed = @Completed
WHERE [ID] = @ProposedFontSetupID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SetProposedFontSetupComplete] TO PUBLIC
    AS [dbo];

