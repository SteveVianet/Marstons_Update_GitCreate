CREATE PROCEDURE [dbo].[AddCallWorkDetailComment]
(
	@CallID		INT,
	@CommentText	TEXT,
	@NewCommentID	INT			OUTPUT,
	@CommentBy	VARCHAR(255) = NULL	OUTPUT,
	@SubmittedOn	DATETIME		OUTPUT,
	@IsInvoice	BIT = 0
)

AS

DECLARE @InternalCommentBy VARCHAR(255)
DECLARE @InternalSubmittedOn DATETIME

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


INSERT INTO dbo.CallWorkDetailComments (CallID, WorkDetailComment, WorkDetailCommentBy, SubmittedOn, IsInvoice)
VALUES (@CallID, @CommentText, @InternalCommentBy, @InternalSubmittedOn, @IsInvoice)

SET @NewCommentID = @@IDENTITY
SET @CommentBy = @InternalCommentBy
SET @SubmittedOn = @InternalSubmittedOn

EXEC dbo.RefreshHandheldCall @CallID, 1, 1, 0

COMMIT

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddCallWorkDetailComment] TO PUBLIC
    AS [dbo];

