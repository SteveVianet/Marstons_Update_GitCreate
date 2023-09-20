---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetCallComments
(
	@CallID	INT
)

AS

SELECT	[ID],
	Comment,
	CommentBy,
	SubmittedOn,
	EditedOn
FROM CallComments
WHERE CallID = @CallID
ORDER BY SubmittedOn


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallComments] TO PUBLIC
    AS [dbo];

