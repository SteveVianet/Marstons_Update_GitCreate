CREATE PROCEDURE dbo.GetUserSites
(
	@UserID	INT
)

AS

SELECT 	UserSites.EDISID,
		Sites.SiteID
FROM dbo.UserSites
JOIN dbo.Sites ON Sites.EDISID = UserSites.EDISID
WHERE UserSites.UserID = @UserID
ORDER BY [Name] ASC

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetUserSites] TO PUBLIC
    AS [dbo];

