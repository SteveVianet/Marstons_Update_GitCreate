CREATE PROCEDURE [dbo].[GetSiteUsersWithType2]
(
	@EDISID int
)
AS
SELECT
	u.ID,
	u.UserName,
	u.[Login],
	ut.[Description],
	ut.ID [UserTypeID]
FROM Users u
INNER JOIN UserSites us ON u.ID = us.UserID
INNER JOIN UserTypes ut ON u.UserType = ut.ID
WHERE us.EDISID = @EDISID
AND	u.Deleted = 0

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteUsersWithType2] TO PUBLIC
    AS [dbo];

