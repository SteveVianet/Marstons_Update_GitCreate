---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetUserPostCodes
(
	@UserID	INT
)

AS

DECLARE @AllSitesVisible	BIT

SELECT @AllSitesVisible = AllSitesVisible
FROM dbo.UserTypes
JOIN dbo.Users ON Users.UserType = UserTypes.[ID]
WHERE dbo.Users.[ID] = @UserID

IF @AllSitesVisible = 1
BEGIN
	SELECT DISTINCT LEFT(PostCode, PATINDEX('%[1234567890]%', PostCode) - 1) AS PostCodeArea
	FROM dbo.Sites
	WHERE PATINDEX('%[1234567890]%', PostCode) > 0
END
ELSE
BEGIN
	SELECT DISTINCT LEFT(Sites.PostCode, PATINDEX('%[1234567890]%', Sites.PostCode) - 1) AS PostCodeArea
	FROM dbo.UserSites
	JOIN dbo.Sites ON Sites.EDISID = UserSites.EDISID
	WHERE UserSites.UserID = @UserID
	AND PATINDEX('%[1234567890]%', PostCode) > 0
END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetUserPostCodes] TO PUBLIC
    AS [dbo];

