---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetUserPostCodeSites
(
	@UserID	INT,
	@PostCodeArea VARCHAR(2)
)

AS

DECLARE @AllSitesVisible	BIT

SELECT @AllSitesVisible = AllSitesVisible
FROM dbo.UserTypes
JOIN dbo.Users ON Users.UserType = UserTypes.[ID]
WHERE dbo.Users.[ID] = @UserID

IF @AllSitesVisible = 1
BEGIN
	SELECT EDISID,
		OwnerID,
		SiteID,
		[Name],
		TenantName,
		Address1, Address2, Address3, Address4, PostCode,
		SiteTelNo, EDISTelNo,
		EDISPassword,
		SiteOnline,
		SerialNo,
		Region,
		Budget,
		SiteClosed,
		Version,
		LastDownload,
		Comment,
		BDMComment,
		IsVRSMember,
		ModemTypeID
	FROM dbo.Sites
	WHERE PostCode LIKE @PostCodeArea + '[1234567890]%'
END
ELSE
BEGIN
	SELECT Sites.EDISID,
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
	FROM dbo.UserSites
	JOIN dbo.Sites ON Sites.EDISID = UserSites.EDISID
	WHERE UserSites.UserID = @UserID
	AND Sites.PostCode LIKE @PostCodeArea + '[1234567890]%'
END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetUserPostCodeSites] TO PUBLIC
    AS [dbo];

