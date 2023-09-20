
CREATE PROCEDURE [dbo].[GetActiveUsers]
(
	@UserTypeID					INT,
	@OnlyExceptionSiteUsers		BIT = 0
)
AS

SET NOCOUNT ON

SELECT	Users.ID AS UserID,
		UserName,
		[Login],
		[Password],
		EMail,
		UserTypes.[Description] AS UserType
FROM Users
JOIN UserTypes ON UserTypes.ID = Users.UserType
WHERE (Users.NeverExpire = 1 OR DATEADD(DAY, -90, GETDATE()) <= Users.LastWebsiteLoginDate)
AND (Users.UserType = @UserTypeID OR @UserTypeID IS NULL)
AND (Users.ID IN (
	SELECT DISTINCT Users.ID
	FROM Users
	JOIN UserTypes ON UserTypes.ID = Users.UserType AND UserTypes.ID = @UserTypeID
	JOIN UserSites ON UserSites.UserID = Users.ID OR UserTypes.AllSitesVisible = 1
	JOIN Sites ON Sites.EDISID = UserSites.EDISID
	JOIN Owners ON Owners.ID = Sites.OwnerID
	WHERE Owners.UseExceptionReporting = 1
	AND Sites.Quality = 1
) OR @OnlyExceptionSiteUsers = 0)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetActiveUsers] TO PUBLIC
    AS [dbo];

