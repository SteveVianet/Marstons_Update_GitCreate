CREATE PROCEDURE [dbo].[GetUsersSummary]
(
	@IncludeRM		BIT = 0,
	@IncludeBDM		BIT = 0,
	@IncludeNotBDM	BIT = 0, 
	@IncludeCEO		BIT = 0,
	@IncludeCAM		BIT = 0
)
AS

SELECT	Users.[ID], 
		UserName + ' (' + UserTypes.[Description]  + ')' AS UserName ,
		Users.UserType
FROM dbo.Users AS Users
JOIN dbo.UserTypes AS UserTypes ON UserTypes.[ID] = Users.UserType
WHERE ((Users.UserType = 1 AND @IncludeRM = 1)
OR (Users.UserType = 2 AND @IncludeBDM = 1)
OR (Users.UserType = 13 AND @IncludeNotBDM = 1)
OR (Users.UserType = 3 AND @IncludeCEO = 1)
OR (Users.UserType = 9 AND @IncludeCAM = 1))
AND Deleted = 0
ORDER BY Users.UserName

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetUsersSummary] TO PUBLIC
    AS [dbo];

