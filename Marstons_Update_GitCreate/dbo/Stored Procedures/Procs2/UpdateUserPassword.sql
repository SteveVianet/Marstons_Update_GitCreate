CREATE PROCEDURE [dbo].[UpdateUserPassword] 
	
	@DatabaseID INT,
	@UserID INT,
	@Login VARCHAR(100),
	@NewPassword VARCHAR(50),
	@PasswordUpdateSuccessful BIT OUTPUT,
	@SkipExistCheck BIT = 0
	
AS
BEGIN

	SET NOCOUNT ON;
	
	DECLARE @UserCount INT
	
	IF @SkipExistCheck = 0
		BEGIN
	
			SELECT @UserCount = Count(*)
			FROM [SQL1\SQL1].ServiceLogger.dbo.WebSiteUsers
			WHERE ([Login] = @Login AND [Password] = @NewPassword)
		
		END
	ELSE
		BEGIN
			SET @UserCount = 0
		END

	IF @UserCount > 0
		BEGIN
			
			SET @PasswordUpdateSuccessful = 0
		
		END
	ELSE
		BEGIN
			
			UPDATE dbo.Users
			SET [Password] = @NewPassword
			WHERE ID = @UserID
			
			EXEC [SQL1\SQL1].ServiceLogger.dbo.UpdateWebSiteUserPassword @DatabaseID, @UserID, @NewPassword
			SET @PasswordUpdateSuccessful = 1
		
		END

END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateUserPassword] TO PUBLIC
    AS [dbo];

