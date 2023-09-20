---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE AddUserToRole
(
	@User	VARCHAR(255),
	@Role	VARCHAR(255)
)

AS

EXEC sp_addrolemember @rolename = @Role, @membername = @User


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddUserToRole] TO PUBLIC
    AS [dbo];

