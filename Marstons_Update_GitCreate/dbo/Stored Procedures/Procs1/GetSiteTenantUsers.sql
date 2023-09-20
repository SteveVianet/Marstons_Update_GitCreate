
CREATE PROCEDURE [dbo].[GetSiteTenantUsers]
(
	@EDISID	INT
)

AS

SELECT	UserID,
		EDISID,
		[Login],
		[Password]
FROM dbo.UserSites
JOIN Users ON Users.[ID] = dbo.UserSites.UserID
WHERE EDISID = @EDISID
AND (Users.NeverExpire = 1 OR DATEADD(DAY, -90, GETDATE()) <= Users.LastWebsiteLoginDate)
AND Users.UserType IN (5, 6)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteTenantUsers] TO PUBLIC
    AS [dbo];

