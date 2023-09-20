CREATE PROCEDURE dbo.DeleteCallComment 
(
	@CommentID	INTEGER
)
AS

DELETE
FROM dbo.CallComments
WHERE [ID] = @CommentID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteCallComment] TO PUBLIC
    AS [dbo];

