---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE DeleteUserSite
(
	@UserID		INT,
	@EDISID		INT
)

AS

DELETE FROM dbo.UserSites
WHERE UserID = @UserID
AND EDISID = @EDISID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteUserSite] TO PUBLIC
    AS [dbo];


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteUserSite] TO [WebAdmin]
    AS [dbo];

