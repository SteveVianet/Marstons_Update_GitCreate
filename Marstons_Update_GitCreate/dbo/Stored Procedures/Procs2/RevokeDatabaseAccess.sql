---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE RevokeDatabaseAccess
(
	@User	VARCHAR(255)
)

AS

EXEC sp_revokedbaccess @name_in_db = @User


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[RevokeDatabaseAccess] TO PUBLIC
    AS [dbo];

