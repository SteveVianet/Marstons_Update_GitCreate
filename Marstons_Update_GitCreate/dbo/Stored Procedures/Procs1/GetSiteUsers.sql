CREATE PROCEDURE [dbo].[GetSiteUsers]
(
	@EDISID	INT
)

AS

SELECT	UserID,
	UserName,
	EDISID,
	Deleted,
	UserType
FROM dbo.UserSites
JOIN Users ON Users.[ID] = UserSites.UserID
WHERE EDISID = @EDISID

UNION 

SELECT	Users.[ID] AS UserID,
	UserName,
	@EDISID AS EDISID,
	Deleted,
	UserType
FROM Users
JOIN UserTypes ON UserTypes.[ID] = Users.UserType
WHERE UserTypes.AllSitesVisible = 1
ORDER BY [Deleted]


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteUsers] TO PUBLIC
    AS [dbo];

