CREATE PROCEDURE [dbo].[UpdateWebUserStatistics]
(
	@ToDate DATE = NULL	
)
AS

/* Get the Week Commencing Date */
IF @ToDate IS NULL
BEGIN
	SET @ToDate = GETDATE()
END
DECLARE @FromDate DATE
SET DATEFIRST 1
SELECT @FromDate = DATEADD(WEEKDAY, -DATEPART(WEEKDAY,@ToDate) + 1, @ToDate)

--SELECT @FromDate, @ToDate

/* ==============================================
	ROD & BDM
   ==============================================  */

/* Delete any existing values for the period (if any) */
DELETE FROM WebSiteUserAnalysisPubCo WHERE WeekCommencing = @FromDate

/* Get RM <-> BDM Relationship */
INSERT INTO WebSiteUserAnalysisPubCo
 (WeekCommencing, RMID, BDMID)
SELECT	@FromDate,
		RMUsers.ID AS RMID,
		BDMSiteAssignments.BDMID AS BDMID
FROM Users AS RMUsers
JOIN UserSites 
  ON UserSites.UserID = RMUsers.ID
JOIN (
	SELECT	BDMUsers.ID AS BDMID,
			UserSites.EDISID AS BDMAssignedEDISID
	FROM Users AS BDMUsers
	JOIN UserSites 
	  ON UserSites.UserID = BDMUsers.ID
	JOIN Sites ON Sites.EDISID = UserSites.EDISID
	WHERE UserType = 2
	  AND Anonymise = 0 AND WebActive = 1 AND Deleted = 0	
	  AND Sites.[Status] IN (1, 2, 10, 3, 4)
	  AND Sites.EDISID NOT IN (SELECT EDISID FROM SiteGroupSites JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID WHERE IsPrimary = 0	AND TypeID = 1)
	) AS BDMSiteAssignments ON BDMSiteAssignments.BDMAssignedEDISID = UserSites.EDISID
WHERE UserType = 1
  AND Anonymise = 0 AND WebActive = 1 AND Deleted = 0	
GROUP BY RMUsers.ID, BDMSiteAssignments.BDMID

/* Get BDM Site Counts */
UPDATE WebSiteUserAnalysisPubCo
SET WebSiteUserAnalysisPubCo.BDMLiveIDraughtSites = AssignedSites.IDraughtCount,
	WebSiteUserAnalysisPubCo.BDMLiveDMSSites = AssignedSites.DMSCount
FROM WebSiteUserAnalysisPubCo
JOIN (
	SELECT	UserSites.UserID AS BDMID, 
			SUM(CASE WHEN Sites.Quality = 1 THEN 1 ELSE 0 END) AS IDraughtCount,
			SUM(CASE WHEN Sites.Quality = 0 THEN 1 ELSE 0 END) AS DMSCount
		FROM UserSites
		JOIN Users ON Users.ID = UserSites.UserID
		JOIN Sites ON Sites.EDISID = UserSites.EDISID
		WHERE Users.UserType = 2
		  AND Users.Anonymise = 0 AND Users.WebActive = 1 AND Users.Deleted = 0
		  AND Sites.[Status] IN (1, 2, 10, 3, 4)
		  AND Sites.EDISID NOT IN (SELECT EDISID FROM SiteGroupSites JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID WHERE IsPrimary = 0	AND TypeID = 1)
		GROUP BY UserSites.UserID
		) AS AssignedSites ON AssignedSites.BDMID = WebSiteUserAnalysisPubCo.BDMID

/* Get the Session Details */
CREATE TABLE #SessionDetails (DatabaseID INT NOT NULL, UserID INT NOT NULL, LoginCount INT NOT NULL, SessionLifetime INT NOT NULL, PagesAccessed INT NOT NULL)
DECLARE @DBID INT
SELECT @DBID = ID FROM [EDISSQL1\SQL1].ServiceLogger.dbo.EDISDatabases WHERE Name = DB_NAME()
INSERT INTO #SessionDetails
 (DatabaseID, UserID, LoginCount, SessionLifetime, PagesAccessed)
EXEC [EDISSQL1\SQL1].ServiceLogger.[dbo].[GetAverageSessionLifetimes] @DBID, @FromDate, @ToDate

--SELECT * FROM #SessionDetails

UPDATE WebSiteUserAnalysisPubCo
SET WebSiteUserAnalysisPubCo.BDMLoginCount = ISNULL(SessionDetails.LoginCount, 0),
	WebSiteUserAnalysisPubCo.BDMSessionAverage = ISNULL(SessionDetails.SessionLifetime, 0)
FROM WebSiteUserAnalysisPubCo
JOIN #SessionDetails AS SessionDetails 
  ON SessionDetails.UserID = WebSiteUserAnalysisPubCo.BDMID
 AND WeekCommencing = @FromDate

/* ==============================================
	BDM & Licensee
   ==============================================  */

/* Delete any existing values for the period (if any) */
DELETE FROM WebSiteUserAnalysisTenant WHERE WeekCommencing = @FromDate

/* Get BDM <-> Licensee/Tenant Relationship */
INSERT INTO WebSiteUserAnalysisTenant
 (WeekCommencing, BDMID, LicenseeID)
SELECT	@FromDate,
		BDMUsers.ID AS BDMID,
		TenantSiteAssignments.TenantID AS LicenseeID
FROM Users AS BDMUsers
JOIN UserSites 
  ON UserSites.UserID = BDMUsers.ID
JOIN (
	SELECT	TenantUsers.ID AS TenantID,
			UserSites.EDISID AS TenantAssignedEDISID
	FROM Users AS TenantUsers
	JOIN UserSites 
	  ON UserSites.UserID = TenantUsers.ID
	JOIN Sites ON Sites.EDISID = UserSites.EDISID
	WHERE UserType IN (5, 6)
	  AND Anonymise = 0 AND WebActive = 1 AND Deleted = 0
	  AND Sites.[Status] IN (1, 2, 10, 3, 4)
	  AND Sites.Quality = 1
	  AND Sites.EDISID NOT IN (SELECT EDISID FROM SiteGroupSites JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID WHERE IsPrimary = 0	AND TypeID = 1)
	) AS TenantSiteAssignments ON TenantSiteAssignments.TenantAssignedEDISID = UserSites.EDISID
WHERE UserType = 2
  AND Anonymise = 0 AND WebActive = 1 AND Deleted = 0	
GROUP BY BDMUsers.ID, TenantSiteAssignments.TenantID

/* We already have the Session Details from the BDM/ROD step */

UPDATE WebSiteUserAnalysisTenant
SET WebSiteUserAnalysisTenant.LicenseeLoginCount = ISNULL(SessionDetails.LoginCount, 0),
	WebSiteUserAnalysisTenant.LicenseeSessionAverage = ISNULL(SessionDetails.SessionLifetime, 0),
	WebSiteUserAnalysisTenant.LicenseePagesAccessed = ISNULL(SessionDetails.PagesAccessed, 0)
FROM WebSiteUserAnalysisTenant
JOIN #SessionDetails AS SessionDetails 
  ON SessionDetails.UserID = WebSiteUserAnalysisTenant.LicenseeID
 AND WeekCommencing = @FromDate

DROP TABLE #SessionDetails

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateWebUserStatistics] TO PUBLIC
    AS [dbo];

