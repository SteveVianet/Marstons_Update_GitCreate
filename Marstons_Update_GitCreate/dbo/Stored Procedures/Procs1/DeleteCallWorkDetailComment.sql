CREATE PROCEDURE dbo.DeleteCallWorkDetailComment
(
	@CommentID	INTEGER
)
AS

DELETE
FROM dbo.CallWorkDetailComments
WHERE [ID] = @CommentID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteCallWorkDetailComment] TO PUBLIC
    AS [dbo];

