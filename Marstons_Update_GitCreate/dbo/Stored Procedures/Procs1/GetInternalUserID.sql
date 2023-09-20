
CREATE PROCEDURE [dbo].[GetInternalUserID]
(
	@UserID	INTEGER	OUT
)
AS
BEGIN TRANSACTION

	SELECT 
		@UserID = [ID] 
	FROM 
		dbo.InternalUsers
	WHERE
		UserName = SYSTEM_USER

	IF @UserID IS NULL 
	BEGIN

		SELECT 
			@UserID = MAX([ID])+1 
		FROM 
			dbo.InternalUsers


		INSERT INTO
			 dbo.InternalUsers([ID], UserName)
		VALUES
			(ISNULL(@UserID,1), SYSTEM_USER)


		SELECT 
			@UserID = MAX([ID]) 
		FROM 
			dbo.InternalUsers

	END

	IF @@ERROR <> 0 BEGIN ROLLBACK; RAISERROR('Could not insert', 16, 1) END

COMMIT TRANSACTION

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetInternalUserID] TO PUBLIC
    AS [dbo];

