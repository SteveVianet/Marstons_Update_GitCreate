
CREATE PROCEDURE [dbo].[AddTamperAttachment]
(
	@AttachmentName	VARCHAR(124),
	@RefID			INTEGER = NULL OUT
	
)
AS
BEGIN TRANSACTION

	IF @RefID IS NULL 
	BEGIN
		SELECT @RefID = MAX(AttachmentID)+1 FROM TamperCaseAttachments
		IF @RefID IS NULL
		BEGIN
			SET @RefID = 1
		END
	END
	
	IF @@ERROR <> 0 BEGIN ROLLBACK; RAISERROR('Could not get ID', 16, 1) END


	INSERT INTO
		TamperCaseAttachments(AttachmentID, AttachmentName)
	VALUES
		(@RefID, @AttachmentName)

	IF @@ERROR <> 0 BEGIN ROLLBACK; RAISERROR('Could not insert', 16, 1) END


COMMIT TRANSACTION

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddTamperAttachment] TO PUBLIC
    AS [dbo];

