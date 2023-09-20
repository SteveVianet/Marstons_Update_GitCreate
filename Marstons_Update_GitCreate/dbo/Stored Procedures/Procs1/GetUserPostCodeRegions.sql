---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetUserPostCodeRegions
(
	@UserID	INT,
	@RegionID INT
)

AS

DECLARE @AllSitesVisible	BIT

SELECT @AllSitesVisible = AllSitesVisible
FROM dbo.UserTypes
JOIN dbo.Users ON Users.UserType = UserTypes.[ID]
WHERE dbo.Users.[ID] = @UserID

IF @AllSitesVisible = 1
BEGIN

	SELECT 	Sites.EDISID,
		Sites.OwnerID,
		Sites.SiteID,
		Sites.[Name],
		Sites.TenantName,
		Sites.Address1, Sites.Address2, Sites.Address3, Sites.Address4, Sites.PostCode,
		Sites.SiteTelNo, Sites.EDISTelNo,
		Sites.EDISPassword,
		Sites.SiteOnline,
		Sites.SerialNo,
		Sites.Region,
		Sites.Budget,
		Sites.SiteClosed,
		Sites.Version,
		Sites.LastDownload,
		Sites.Comment,
		Sites.BDMComment,
		Sites.IsVRSMember,
		Sites.ModemTypeID
	FROM dbo.Sites
	JOIN dbo.Regions ON Regions.[ID] = Sites.Region
	WHERE Regions.[ID] = @RegionID
END
ELSE
BEGIN
	SELECT 	Sites.EDISID,
		Sites.OwnerID,
		Sites.SiteID,
		Sites.[Name],
		Sites.TenantName,
		Sites.Address1, Sites.Address2, Sites.Address3, Sites.Address4, Sites.PostCode,
		Sites.SiteTelNo, Sites.EDISTelNo,
		Sites.EDISPassword,
		Sites.SiteOnline,
		Sites.SerialNo,
		Sites.Region,
		Sites.Budget,
		Sites.SiteClosed,
		Sites.Version,
		Sites.LastDownload,
		Sites.Comment,
		Sites.BDMComment,
		Sites.IsVRSMember,
		Sites.ModemTypeID
	FROM dbo.Sites
	JOIN dbo.UserSites ON Sites.EDISID = UserSites.EDISID
	JOIN dbo.Regions ON Regions.[ID] = Sites.Region
	WHERE UserSites.UserID = @UserID
	AND Regions.[ID] = @RegionID
END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetUserPostCodeRegions] TO PUBLIC
    AS [dbo];

