CREATE PROCEDURE [dbo].[AddComment]
(
	@CallID			INT,
	@CommentText	TEXT,
	@NewCommentID	INT		OUTPUT,
	@CommentBy		VARCHAR(255) = NULL	OUTPUT,
	@SubmittedOn	DATETIME	OUTPUT,
	@EditedOn		DATETIME = NULL
)

AS

DECLARE @InternalCommentBy VARCHAR(255)
DECLARE @InternalSubmittedOn DATETIME

SET NOCOUNT ON
SET XACT_ABORT ON

BEGIN TRAN

IF @CommentBy IS NULL
	SET @InternalCommentBy = SUSER_SNAME()
ELSE
	SET @InternalCommentBy = @CommentBy

IF @SubmittedOn IS NULL
	SET @InternalSubmittedOn = GETDATE()
ELSE
	SET @InternalSubmittedOn = @SubmittedOn

INSERT INTO dbo.CallComments (CallID, Comment, CommentBy, SubmittedOn, EditedOn)
VALUES (@CallID, @CommentText, @InternalCommentBy, @InternalSubmittedOn, @EditedOn)

SET @NewCommentID = @@IDENTITY
SET @CommentBy = @InternalCommentBy
SET @SubmittedOn = @InternalSubmittedOn

COMMIT

--Refresh call on Handheld if applicable
EXEC dbo.RefreshHandheldCall @CallID, 0, 1, 0

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddComment] TO PUBLIC
    AS [dbo];

