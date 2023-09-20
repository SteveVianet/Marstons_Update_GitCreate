---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE AddUserSite
(
	@UserID		INT,
	@EDISID		INT
)

AS

INSERT INTO dbo.UserSites
(UserID, EDISID)
VALUES
(@UserID, @EDISID)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddUserSite] TO PUBLIC
    AS [dbo];


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddUserSite] TO [SiteCreator]
    AS [dbo];


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddUserSite] TO [WebAdmin]
    AS [dbo];

