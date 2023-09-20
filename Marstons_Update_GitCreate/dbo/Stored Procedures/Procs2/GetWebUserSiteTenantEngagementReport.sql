CREATE PROCEDURE [dbo].[GetWebUserSiteTenantEngagementReport]
(
	@From DATE,
	@To DATE,
	@UserID INT = NULL,
	@Weekly BIT = 1,
	@Development BIT = 0
)
AS

DECLARE @AllSites BIT
DECLARE @UserType INT
SELECT @AllSites = AllSitesVisible, @UserType = UserType FROM Users JOIN UserTypes ON UserTypes.ID = UserType WHERE Users.ID = @UserID

DECLARE @StartLimit DATE
SET @StartLimit = '2011-06-06'
IF @StartLimit > @From
BEGIN
	SET @From = @StartLimit
END

;WITH MasterSites(EDISID, SiteID, Name, Town, PostCode) AS
(
	SELECT	Sites.EDISID, 
			SiteID, 
			Name, 
			COALESCE(Address2, Address3, Address4),
			PostCode FROM Sites
	JOIN UserSites
	  ON UserSites.EDISID = Sites.EDISID
	WHERE (
			((@UserID IS NULL) OR (@AllSites = 1))
			  OR 
			(UserID = @UserID)
		  )
	  AND Sites.[Status] IN (1, 2, 10, 3, 4)
	  AND Sites.[Quality] = 1
	  AND Sites.[EDISID] NOT IN (	SELECT EDISID
									FROM SiteGroupSites 
									JOIN SiteGroups 
									  ON SiteGroups.ID = SiteGroupSites.SiteGroupID
									WHERE IsPrimary = 0
									  AND TypeID = 1)
)
SELECT	CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE) AS [WeekCommencing], 
		UserSites.EDISID AS EDISID, 
		MasterSites.SiteID + ': ' + MasterSites.Name + ', ' + MasterSites.Town + ', ' + MasterSites.PostCode  AS SiteDetails,
		SUM(LicenseeLoginCount) AS Logins
FROM UserSites
JOIN Users ON Users.ID = UserSites.UserID
JOIN MasterSites ON MasterSites.EDISID = UserSites.EDISID
JOIN WebSiteUserAnalysisTenant ON WebSiteUserAnalysisTenant.LicenseeID = UserSites.UserID
WHERE UserType IN (5,6)
  AND Users.Anonymise = 0 AND Users.Deleted = 0 AND Users.WebActive = 1
GROUP BY	CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE), 
			UserSites.EDISID, MasterSites.SiteID, MasterSites.Name, MasterSites.Town, MasterSites.PostCode
HAVING	CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE) BETWEEN @From AND @To
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserSiteTenantEngagementReport] TO PUBLIC
    AS [dbo];

