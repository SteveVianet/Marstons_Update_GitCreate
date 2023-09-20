CREATE PROCEDURE [dbo].[GetInternalUserByName]
(
	@UserName	VARCHAR(60),
	@UserID	INTEGER	OUT
)
AS
BEGIN TRANSACTION

	SELECT 
		@UserID = [ID] 
	FROM 
		dbo.InternalUsers
	WHERE
		UserName = @UserName

	IF @UserID IS NULL 
	BEGIN

		SELECT 
			@UserID = MAX([ID])+1 
		FROM 
			dbo.InternalUsers


		INSERT INTO
			 dbo.InternalUsers([ID], UserName)
		VALUES
			(ISNULL(@UserID,1), @UserName)


		SELECT 
			@UserID = MAX([ID]) 
		FROM 
			dbo.InternalUsers

	END

	IF @@ERROR <> 0 BEGIN ROLLBACK; RAISERROR('Could not insert', 16, 1) END

COMMIT TRANSACTION
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetInternalUserByName] TO PUBLIC
    AS [dbo];

