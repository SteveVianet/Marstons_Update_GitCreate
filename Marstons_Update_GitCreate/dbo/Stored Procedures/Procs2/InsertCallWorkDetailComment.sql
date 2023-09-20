CREATE PROCEDURE [dbo].[InsertCallWorkDetailComment]
(
	@CallID			INT,
	@CommentText	TEXT,
	@CommentBy		VARCHAR(255),
	@SubmittedOn	DATETIME,
	@EditedOn		DATETIME
)

AS

INSERT INTO dbo.CallWorkDetailComments 
	(CallID, WorkDetailComment, WorkDetailCommentBy, SubmittedOn, EditedOn)
VALUES 
	(@CallID, @CommentText, @CommentBy, @SubmittedOn, @EditedOn)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[InsertCallWorkDetailComment] TO PUBLIC
    AS [dbo];

