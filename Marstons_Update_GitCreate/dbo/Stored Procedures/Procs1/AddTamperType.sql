
CREATE PROCEDURE [dbo].[AddTamperType]
(
	@TypeID	INTEGER,
	@RefID		INTEGER = NULL OUT
)
AS
BEGIN TRANSACTION

	IF @RefID IS NULL 
	BEGIN
		SELECT @RefID = MAX(RefID)+1 FROM TamperCaseEventTypeList
	END
	
	IF @@ERROR <> 0 BEGIN ROLLBACK; RAISERROR('Could not get ID', 16, 1) END


	INSERT INTO
		TamperCaseEventTypeList(RefID, TypeID)
	VALUES
		(ISNULL(@RefID,1), @TypeID)

	IF @@ERROR <> 0 BEGIN ROLLBACK; RAISERROR('Could not insert', 16, 1) END


	SELECT @RefID = MAX(RefID) FROM TamperCaseEventTypeList

	IF @@ERROR <> 0 BEGIN ROLLBACK; RAISERROR('Could not get ID', 16, 1) END
	

COMMIT TRANSACTION

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddTamperType] TO PUBLIC
    AS [dbo];

