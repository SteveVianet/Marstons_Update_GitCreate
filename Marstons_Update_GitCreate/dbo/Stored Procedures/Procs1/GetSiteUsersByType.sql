CREATE PROCEDURE [dbo].[GetSiteUsersByType]
(
	@EDISID	INT,
	@UserType INT
)

AS

SELECT	UserID,
	EDISID
FROM dbo.UserSites
JOIN Users ON Users.[ID] = dbo.UserSites.UserID
WHERE EDISID = @EDISID
AND Users.UserType = @UserType

UNION 

SELECT	Users.[ID] AS UserID,
	@EDISID AS EDISID
FROM Users
JOIN UserTypes ON UserTypes.[ID] = Users.UserType
WHERE UserTypes.AllSitesVisible = 1
AND Users.UserType = @UserType
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteUsersByType] TO PUBLIC
    AS [dbo];

