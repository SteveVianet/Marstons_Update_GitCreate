---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetUserRegions
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
	SELECT 	Regions.[ID],
		Regions.[Description]
	FROM dbo.Sites
	JOIN dbo.Regions ON Regions.[ID] = Sites.Region
	GROUP BY Regions.[ID], Regions.[Description]
END
ELSE
BEGIN
	SELECT 	Regions.[ID],
		Regions.[Description]
	FROM dbo.UserSites
	JOIN dbo.Sites ON Sites.EDISID = UserSites.EDISID
	JOIN dbo.Regions ON Regions.[ID] = Sites.Region
	WHERE UserSites.UserID = @UserID
	GROUP BY Regions.[ID], Regions.[Description]
END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetUserRegions] TO PUBLIC
    AS [dbo];

