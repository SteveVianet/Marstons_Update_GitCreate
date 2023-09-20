CREATE PROCEDURE [dbo].[ValidateWebUser]
(
	@Login		VARCHAR(255),
	@Password	VARCHAR(255)
)

AS

SET NOCOUNT ON

DECLARE @DatabaseID INT
SELECT @DatabaseID = CAST(PropertyValue AS INT) FROM Configuration WHERE PropertyName = 'Service Owner ID'


SELECT	@DatabaseID AS DatabaseID,
		@@SERVERNAME AS DatabaseServer,
		DB_NAME() AS DatabaseName,
		ID AS UserID,
		Anonymise
FROM Users
WHERE [Login] = @Login AND [Password] = @Password


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ValidateWebUser] TO PUBLIC
    AS [dbo];

