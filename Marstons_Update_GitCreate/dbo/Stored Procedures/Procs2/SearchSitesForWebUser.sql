CREATE PROCEDURE [dbo].[SearchSitesForWebUser]
(
	@UserID		INT,
	@SiteID		NVARCHAR(50) = NULL,
	@SiteName		NVARCHAR(50) = NULL,
	@SiteTown		NVARCHAR(50) = NULL,
	@SitePostcode		NVARCHAR(8) = NULL
)
AS

--DECLARE @AllSitesVisible BIT

--SET @AllSitesVisible = (SELECT UserTypes.AllSitesVisible
			--FROM Users
			--JOIN UserTypes ON Users.UserType = UserTypes.ID
			--WHERE Users.ID = @UserID)



SELECT TOP 100 Sites.EDISID,
		OwnerID,
		SiteID,
		[Name] AS SiteName,
		Address1, Address2, Address3, Address4, PostCode,
		SiteOnline,
		Region, AreaID,
		LastDownload,
		([Name] + '  -  ' + PostCode + '  -  ' + SiteID) As SiteDetails

FROM dbo.Sites WITH (NOLOCK)
--WHERE Hidden = 0 AND (Sites.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID) OR @AllSitesVisible = 1)
WHERE (UPPER(SiteID) LIKE '%' + UPPER(@SiteID) + '%' OR @SiteID IS NULL)
AND (UPPER([Name]) LIKE '%' + UPPER(@SiteName) + '%' OR @SiteName IS NULL)
AND (UPPER(PostCode) LIKE '%' + UPPER(@SitePostcode) + '%' OR @SitePostcode IS NULL)
AND (UPPER(Address1) LIKE '%' + UPPER(@SiteTown) + '%' 
	OR UPPER(Address2) LIKE '%' + UPPER(@SiteTown) + '%' 
	OR UPPER(Address3) LIKE '%' + UPPER(@SiteTown) + '%' 
	OR UPPER(Address4) LIKE '%' + UPPER(@SiteTown) + '%' 
	OR @SiteTown IS NULL)
AND EDISID NOT IN (
		SELECT EDISID FROM SiteGroupSites
		JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID 
		WHERE SiteGroups.TypeID = 1 AND IsPrimary = 0
	    )
ORDER BY [Name]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SearchSitesForWebUser] TO PUBLIC
    AS [dbo];

