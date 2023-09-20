---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE SetSiteNoteCleared
(
	@NoteID		INT,
	@Cleared	BIT
)

AS

UPDATE SiteNotes
SET Cleared = @Cleared
WHERE [ID] = @NoteID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SetSiteNoteCleared] TO PUBLIC
    AS [dbo];

