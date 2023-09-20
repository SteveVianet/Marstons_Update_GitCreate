CREATE PROCEDURE [dbo].[GetSiteUsers2]
(
	@EDISID	INT
)

AS

SELECT	UserID,
	UserName,
	EDISID,
	Deleted,
	UserType,
	UserTypes.Description as UserTypeDescription,
	[Login],
	[Password]
FROM dbo.UserSites
JOIN Users ON Users.[ID] = UserSites.UserID
JOIN UserTypes ON UserTypes.[ID] = Users.UserType
WHERE EDISID = @EDISID

UNION 

SELECT	Users.[ID] AS UserID,
	UserName,
	@EDISID AS EDISID,
	Deleted,
	UserType,
	UserTypes.Description as UserTypeDescription,
	[Login],
	[Password]
FROM Users
JOIN UserTypes ON UserTypes.[ID] = Users.UserType
WHERE UserTypes.AllSitesVisible = 1
ORDER BY [Deleted], UserName

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteUsers2] TO PUBLIC
    AS [dbo];

