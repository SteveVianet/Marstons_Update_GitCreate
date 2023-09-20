
CREATE PROCEDURE dbo.UpdateUserWebsiteLogin
(
	@UserID	INT
)

AS

UPDATE dbo.Users
SET LastWebsiteLoginDate = GETDATE()
WHERE [ID] = @UserID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateUserWebsiteLogin] TO PUBLIC
    AS [dbo];

