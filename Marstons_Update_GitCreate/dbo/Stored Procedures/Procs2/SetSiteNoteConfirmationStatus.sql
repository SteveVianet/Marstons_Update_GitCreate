---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE SetSiteNoteConfirmationStatus
(
	@NoteID		INT,
	@Confirmed	BIT
)

AS

UPDATE SiteNotes
SET Confirmed = @Confirmed
WHERE [ID] = @NoteID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SetSiteNoteConfirmationStatus] TO PUBLIC
    AS [dbo];

