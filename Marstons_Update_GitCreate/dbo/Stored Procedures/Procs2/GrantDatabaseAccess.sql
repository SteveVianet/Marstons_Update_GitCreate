---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GrantDatabaseAccess
(
	@User	VARCHAR(255)
)

AS

EXEC sp_grantdbaccess @loginame = @User


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GrantDatabaseAccess] TO PUBLIC
    AS [dbo];

