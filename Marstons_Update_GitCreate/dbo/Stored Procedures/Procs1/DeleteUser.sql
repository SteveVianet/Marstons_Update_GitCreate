CREATE PROCEDURE [dbo].[DeleteUser]
(
	@UserID		INT
)

AS

UPDATE dbo.Users
SET Deleted = 1
WHERE [ID] = @UserID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteUser] TO PUBLIC
    AS [dbo];


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteUser] TO [WebAdmin]
    AS [dbo];

