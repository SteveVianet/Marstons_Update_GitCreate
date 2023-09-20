---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetRelatedUsers
(
	@UserID		INT,
	@UserType	INT
)

AS

DECLARE @AllSitesVisible	BIT

SET NOCOUNT ON

SELECT @AllSitesVisible = AllSitesVisible
FROM UserTypes
JOIN Users ON Users.UserType = UserTypes.[ID]
WHERE Users.[ID] = @UserID

IF @AllSitesVisible =1
	SELECT Users.[ID] AS UserID
	FROM Users
	JOIN UserSites ON UserSites.UserID = Users.[ID]
	WHERE Users.UserType = @UserType
	GROUP BY Users.[ID]
ELSE
	SELECT Users.[ID] AS UserID
	FROM UserSites AS ParentUserSites
	JOIN UserSites AS RelatedUserSites ON ParentUserSites.EDISID = RelatedUserSites.EDISID
	JOIN Users ON Users.[ID] = RelatedUserSites.UserID
	JOIN Sites ON Sites.EDISID = RelatedUserSites.EDISID
	WHERE ParentUserSites.UserID = @UserID
	AND Users.UserType = @UserType
	AND Sites.Hidden = 0
	GROUP BY Users.[ID]
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetRelatedUsers] TO PUBLIC
    AS [dbo];

