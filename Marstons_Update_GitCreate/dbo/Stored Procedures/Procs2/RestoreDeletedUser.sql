CREATE PROCEDURE [dbo].[RestoreDeletedUser]
(
	@UserID		INT
)

AS

BEGIN
	
SET NOCOUNT ON;
	
UPDATE dbo.Users
SET Deleted = 0
WHERE [ID] = @UserID
   
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[RestoreDeletedUser] TO PUBLIC
    AS [dbo];

