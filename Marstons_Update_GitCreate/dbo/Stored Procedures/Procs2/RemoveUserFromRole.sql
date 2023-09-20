---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE RemoveUserFromRole
(
	@User	VARCHAR(255),
	@Role	VARCHAR(255)
)

AS

EXEC sp_droprolemember @rolename = @Role, @membername = @User


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[RemoveUserFromRole] TO PUBLIC
    AS [dbo];

