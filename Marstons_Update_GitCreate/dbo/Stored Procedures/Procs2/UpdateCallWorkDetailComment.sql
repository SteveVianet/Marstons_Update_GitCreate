CREATE PROCEDURE [dbo].[UpdateCallWorkDetailComment]
(
	@WorkDetailCommentID	INT,
	@WorkDetailComment		TEXT
)

AS

UPDATE dbo.CallWorkDetailComments
SET WorkDetailComment = @WorkDetailComment
WHERE [ID] = @WorkDetailCommentID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallWorkDetailComment] TO PUBLIC
    AS [dbo];

