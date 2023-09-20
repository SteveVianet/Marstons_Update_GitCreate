---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE SetSiteNoteRobustAction
(
	@NoteID		INT,
	@RobustAction	BIT
)

AS

UPDATE SiteNotes
SET RobustAction = @RobustAction
WHERE [ID] = @NoteID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SetSiteNoteRobustAction] TO PUBLIC
    AS [dbo];

