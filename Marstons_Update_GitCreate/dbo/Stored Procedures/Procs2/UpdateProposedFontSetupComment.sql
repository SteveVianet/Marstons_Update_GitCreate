---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE UpdateProposedFontSetupComment
(
	@ProposedFontSetupID	INT,
	@Comment		TEXT
)

AS

UPDATE ProposedFontSetups
SET	Comment = @Comment
WHERE [ID] = @ProposedFontSetupID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateProposedFontSetupComment] TO PUBLIC
    AS [dbo];

