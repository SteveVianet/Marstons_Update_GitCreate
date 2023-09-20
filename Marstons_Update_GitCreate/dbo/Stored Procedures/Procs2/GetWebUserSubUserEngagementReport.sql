CREATE PROCEDURE [dbo].[GetWebUserSubUserEngagementReport]
(
	@From DATE,
	@To DATE,
	@UserID INT,
	@Weekly BIT = 1
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

IF @UserType = 1 --RM
BEGIN
	WITH 
	BDMUsers AS (
		SELECT WebSiteUserAnalysisPubCo.BDMID , Users.UserName, AVG(WebSiteUserAnalysisPubCo.BDMLiveIDraughtSites) AS AverageLiveSites
		FROM WebSiteUserAnalysisPubCo
		JOIN Users ON Users.ID = WebSiteUserAnalysisPubCo.BDMID
		WHERE Users.Anonymise = 0 AND Users.Deleted = 0 AND Users.WebActive = 1
		  AND ((@AllSites = 1) OR (WebSiteUserAnalysisPubCo.RMID = @UserID))
		  AND WeekCommencing BETWEEN @From AND @To
		GROUP BY WebSiteUserAnalysisPubCo.BDMID, Users.UserName
	),
	WeeklyLicenseeStats AS (
		SELECT
			CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE) AS [WeekCommencing],
			WebSiteUserAnalysisTenant.BDMID,
			WebSiteUserAnalysisTenant.LicenseeID,
			SUM(WebSiteUserAnalysisTenant.LicenseeLoginCount) AS LicenseeLoginCount,
			COUNT(NULLIF(WebSiteUserAnalysisTenant.LicenseeLoginCount,0)) AS UniqueLicenseeLoginCount
		FROM WebSiteUserAnalysisTenant
		JOIN Users ON ID = WebSiteUserAnalysisTenant.LicenseeID
		JOIN BDMUsers ON BDMUsers.BDMID = WebSiteUserAnalysisTenant.BDMID
	    WHERE WeekCommencing BETWEEN @From AND @To
		  --AND LicenseeLoginCount > 0
		  AND Users.Anonymise = 0 AND Users.Deleted = 0 AND Users.WebActive = 1
		GROUP BY 
			CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE),
			WebSiteUserAnalysisTenant.BDMID,
			WebSiteUserAnalysisTenant.LicenseeID
	),
	MonthlyLicenseeStats AS (
		SELECT  
			CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE) AS [WeekCommencing],
			WebSiteUserAnalysisTenant.BDMID,
			WebSiteUserAnalysisTenant.LicenseeID,
			SUM(WebSiteUserAnalysisTenant.LicenseeLoginCount) AS LicenseeLoginCount,
			COUNT(NULLIF(WebSiteUserAnalysisTenant.LicenseeLoginCount,0)) AS UniqueLicenseeLoginCount
		FROM WebSiteUserAnalysisTenant
		JOIN Users ON ID = WebSiteUserAnalysisTenant.LicenseeID
		JOIN BDMUsers ON BDMUsers.BDMID = WebSiteUserAnalysisTenant.BDMID
	    WHERE WeekCommencing BETWEEN @From AND @To
		  --AND LicenseeLoginCount > 0
		  AND Users.Anonymise = 0 AND Users.Deleted = 0 AND Users.WebActive = 1
		GROUP BY 
			CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE),
			WebSiteUserAnalysisTenant.BDMID,
			WebSiteUserAnalysisTenant.LicenseeID
	)
	SELECT	COALESCE(WeeklyLicenseeStats.WeekCommencing, MonthlyLicenseeStats.WeekCommencing) AS [WeekCommencing], 
			COALESCE(WeeklyLicenseeStats.BDMID, MonthlyLicenseeStats.BDMID) AS [UserID], 
			Users.UserName AS [UserName],
			BDMUsers.AverageLiveSites AS iDraughtSites,
			COUNT(NULLIF(COALESCE(WeeklyLicenseeStats.UniqueLicenseeLoginCount, MonthlyLicenseeStats.UniqueLicenseeLoginCount),0)) AS UniqueLicenseeLogins,
			BDMUsers.AverageLiveSites - COUNT(NULLIF(COALESCE(WeeklyLicenseeStats.UniqueLicenseeLoginCount, MonthlyLicenseeStats.UniqueLicenseeLoginCount),0)) AS NotLoggedInCount
	FROM BDMUsers
	JOIN Users 
	  ON Users.ID = BDMUsers.BDMID
	LEFT OUTER JOIN WeeklyLicenseeStats
	  ON WeeklyLicenseeStats.BDMID = BDMUsers.BDMID
	 AND @Weekly = 1
	LEFT OUTER JOIN MonthlyLicenseeStats
	  ON MonthlyLicenseeStats.BDMID = BDMUsers.BDMID
	 AND @Weekly = 0
	WHERE COALESCE(WeeklyLicenseeStats.WeekCommencing, MonthlyLicenseeStats.WeekCommencing) IS NOT NULL
	GROUP BY 
		COALESCE(WeeklyLicenseeStats.WeekCommencing, MonthlyLicenseeStats.WeekCommencing), 
		COALESCE(WeeklyLicenseeStats.BDMID, MonthlyLicenseeStats.BDMID), 
		Users.UserName, 
		BDMUsers.AverageLiveSites
END
ELSE IF @UserType = 2 --BDM
BEGIN	
	;WITH
	LicenseeUsers AS (
		SELECT WebSiteUserAnalysisTenant.LicenseeID, Users.UserName, Count(UserSites.EDISID) AS AverageLiveSites
		FROM WebSiteUserAnalysisTenant
		JOIN Users ON Users.ID = WebSiteUserAnalysisTenant.LicenseeID
		JOIN UserSites ON UserSites.UserID = WebSiteUserAnalysisTenant.LicenseeID
		JOIN Sites ON Sites.EDISID = UserSites.EDISID
		WHERE Users.Anonymise = 0 AND Users.Deleted = 0 AND Users.WebActive = 1
		  AND ((@AllSites = 1) OR (WebSiteUserAnalysisTenant.BDMID = @UserID))
		  AND WeekCommencing BETWEEN @From AND @To
		GROUP BY WebSiteUserAnalysisTenant.LicenseeID, Users.UserName
	),
	WeeklyLicenseeStats AS (
		SELECT
			WebSiteUserAnalysisTenant.WeekCommencing AS [WeekCommencing],
			WebSiteUserAnalysisTenant.LicenseeID,
			SUM(WebSiteUserAnalysisTenant.LicenseeLoginCount) AS LicenseeLoginCount,
			COUNT(NULLIF(WebSiteUserAnalysisTenant.LicenseeLoginCount,0)) AS UniqueLicenseeLoginCount
		FROM WebSiteUserAnalysisTenant
		JOIN Users ON ID = WebSiteUserAnalysisTenant.LicenseeID
	    WHERE WeekCommencing BETWEEN @From AND @To
		  --AND LicenseeLoginCount > 0
		  AND Users.Anonymise = 0 AND Users.Deleted = 0 AND Users.WebActive = 1
		GROUP BY 
			WebSiteUserAnalysisTenant.WeekCommencing,
			WebSiteUserAnalysisTenant.LicenseeID
	),
	MonthlyLicenseeStats AS (
		SELECT  
			CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE) AS [WeekCommencing],
			WebSiteUserAnalysisTenant.LicenseeID,
			SUM(WebSiteUserAnalysisTenant.LicenseeLoginCount) AS LicenseeLoginCount,
			COUNT(NULLIF(WebSiteUserAnalysisTenant.LicenseeLoginCount,0)) AS UniqueLicenseeLoginCount
		FROM WebSiteUserAnalysisTenant
		JOIN Users ON ID = WebSiteUserAnalysisTenant.LicenseeID
	    WHERE WeekCommencing BETWEEN @From AND @To
		  --AND LicenseeLoginCount > 0
		  AND Users.Anonymise = 0 AND Users.Deleted = 0 AND Users.WebActive = 1
		GROUP BY 
			CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE),
			WebSiteUserAnalysisTenant.LicenseeID
	)
	SELECT	COALESCE(WeeklyLicenseeStats.WeekCommencing, MonthlyLicenseeStats.WeekCommencing) AS [WeekCommencing], 
			COALESCE(WeeklyLicenseeStats.LicenseeID, MonthlyLicenseeStats.LicenseeID) AS [UserID], 
			Users.UserName AS [UserName],
			1 AS iDraughtSites,
			COUNT(NULLIF(COALESCE(WeeklyLicenseeStats.UniqueLicenseeLoginCount, MonthlyLicenseeStats.UniqueLicenseeLoginCount),0)) AS UniqueLicenseeLogins,
			1 - COUNT(NULLIF(COALESCE(WeeklyLicenseeStats.UniqueLicenseeLoginCount, MonthlyLicenseeStats.UniqueLicenseeLoginCount),0)) AS NotLoggedInCount
	FROM LicenseeUsers
	JOIN Users 
	  ON Users.ID = LicenseeUsers.LicenseeID
	LEFT OUTER JOIN WeeklyLicenseeStats
	  ON WeeklyLicenseeStats.LicenseeID = LicenseeUsers.LicenseeID
	 AND @Weekly = 1
	LEFT OUTER JOIN MonthlyLicenseeStats
	  ON MonthlyLicenseeStats.LicenseeID = LicenseeUsers.LicenseeID
	 AND @Weekly = 0
	WHERE COALESCE(WeeklyLicenseeStats.WeekCommencing, MonthlyLicenseeStats.WeekCommencing) IS NOT NULL
	GROUP BY 
		COALESCE(WeeklyLicenseeStats.WeekCommencing, MonthlyLicenseeStats.WeekCommencing), 
		COALESCE(WeeklyLicenseeStats.LicenseeID, MonthlyLicenseeStats.LicenseeID), 
		Users.UserName, 
		LicenseeUsers.AverageLiveSites
END
ELSE IF @UserType IN (3,4) --CEO/MD
BEGIN
	WITH 
	MonthlyRMUsers AS (
		SELECT	CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE) AS [WeekCommencing],
				WebSiteUserAnalysisPubCo.RMID, 
				Users.UserName, 
				AVG(RMSiteCount.LiveSites) AS AverageLiveSites
		FROM WebSiteUserAnalysisPubCo
		JOIN Users ON Users.ID = WebSiteUserAnalysisPubCo.RMID
		JOIN (	SELECT WeekCommencing, RMID, SUM(BDMLiveIDraughtSites) AS LiveSites
				FROM WebSiteUserAnalysisPubCo
				JOIN Users AS SubRMUsers ON SubRMUsers.ID = WebSiteUserAnalysisPubCo.RMID
				JOIN Users AS SubBDMUsers ON SubBDMUsers.ID = WebSiteUserAnalysisPubCo.BDMID
				WHERE WeekCommencing BETWEEN @From AND @To
				  AND SubRMUsers.Anonymise = 0 AND SubRMUsers.Deleted = 0 AND SubRMUsers.WebActive = 1
				  AND SubBDMUsers.Anonymise = 0 AND SubBDMUsers.Deleted = 0 AND SubBDMUsers.WebActive = 1
				GROUP BY WeekCommencing, RMID
				) AS RMSiteCount
		   ON RMSiteCount.RMID = WebSiteUserAnalysisPubCo.RMID
		WHERE Users.Anonymise = 0 AND Users.Deleted = 0 AND Users.WebActive = 1
		  AND (
				(@AllSites = 1) 
					OR 
				(WebSiteUserAnalysisPubCo.RMID IN (SELECT UserID FROM UserSites JOIN Users ON Users.ID = UserSites.UserID WHERE UserType = 1 AND EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID)))
			  )
		  AND WebSiteUserAnalysisPubCo.WeekCommencing BETWEEN @From AND @To
		GROUP BY 
				CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE), 
				WebSiteUserAnalysisPubCo.RMID, 
				Users.UserName
	),
	WeeklyRMUsers AS (
		SELECT	WebSiteUserAnalysisPubCo.WeekCommencing AS [WeekCommencing],
				WebSiteUserAnalysisPubCo.RMID, 
				Users.UserName, 
				AVG(RMSiteCount.LiveSites) AS AverageLiveSites
		FROM WebSiteUserAnalysisPubCo
		JOIN Users ON Users.ID = WebSiteUserAnalysisPubCo.RMID
		JOIN (	SELECT WeekCommencing, RMID, SUM(BDMLiveIDraughtSites) AS LiveSites
				FROM WebSiteUserAnalysisPubCo
				JOIN Users AS SubRMUsers ON SubRMUsers.ID = WebSiteUserAnalysisPubCo.RMID
				JOIN Users AS SubBDMUsers ON SubBDMUsers.ID = WebSiteUserAnalysisPubCo.BDMID
				WHERE WeekCommencing BETWEEN @From AND @To
				  AND SubRMUsers.Anonymise = 0 AND SubRMUsers.Deleted = 0 AND SubRMUsers.WebActive = 1
				  AND SubBDMUsers.Anonymise = 0 AND SubBDMUsers.Deleted = 0 AND SubBDMUsers.WebActive = 1
				GROUP BY WeekCommencing, RMID
				) AS RMSiteCount
		   ON RMSiteCount.RMID = WebSiteUserAnalysisPubCo.RMID
		WHERE Users.Anonymise = 0 AND Users.Deleted = 0 AND Users.WebActive = 1
		  AND (
				(@AllSites = 1) 
					OR 
				(WebSiteUserAnalysisPubCo.RMID IN (SELECT UserID FROM UserSites JOIN Users ON Users.ID = UserSites.UserID WHERE UserType = 1 AND EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID)))
			  )
		  AND WebSiteUserAnalysisPubCo.WeekCommencing BETWEEN @From AND @To
		GROUP BY 
				WebSiteUserAnalysisPubCo.WeekCommencing, 
				WebSiteUserAnalysisPubCo.RMID, 
				Users.UserName
	),	
	WeeklyLicenseeStats AS (
		SELECT
			WebSiteUserAnalysisTenant.WeekCommencing AS [WeekCommencing],
			WebSiteUserAnalysisPubCo.RMID,
			WebSiteUserAnalysisTenant.LicenseeID,
			SUM(WebSiteUserAnalysisTenant.LicenseeLoginCount) AS LicenseeLoginCount,
			COUNT(NULLIF(WebSiteUserAnalysisTenant.LicenseeLoginCount,0)) AS UniqueLicenseeLoginCount
		FROM WebSiteUserAnalysisTenant
		JOIN Users ON ID = WebSiteUserAnalysisTenant.LicenseeID
		JOIN WebSiteUserAnalysisPubCo ON WebSiteUserAnalysisPubCo.BDMID = WebSiteUserAnalysisTenant.BDMID
		JOIN WeeklyRMUsers 
		  ON WeeklyRMUsers.RMID = WebSiteUserAnalysisPubCo.RMID
		 AND WeeklyRMUsers.WeekCommencing = WebSiteUserAnalysisTenant.WeekCommencing
		 AND WeeklyRMUsers.WeekCommencing = WebSiteUserAnalysisPubCo.WeekCommencing
	    WHERE WebSiteUserAnalysisTenant.WeekCommencing BETWEEN @From AND @To
	      AND WebSiteUserAnalysisPubCo.WeekCommencing BETWEEN @From AND @To
		  --AND LicenseeLoginCount > 0
		  AND Users.Anonymise = 0 AND Users.Deleted = 0 AND Users.WebActive = 1
		GROUP BY 
			WebSiteUserAnalysisTenant.WeekCommencing,
			WebSiteUserAnalysisPubCo.RMID,
			WebSiteUserAnalysisTenant.LicenseeID
	),
	MonthlyLicenseeStats AS (
		SELECT
			CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE) AS [WeekCommencing],
			WebSiteUserAnalysisPubCo.RMID,
			WebSiteUserAnalysisTenant.LicenseeID,
			SUM(WebSiteUserAnalysisTenant.LicenseeLoginCount) AS LicenseeLoginCount,
			COUNT(NULLIF(WebSiteUserAnalysisTenant.LicenseeLoginCount,0)) AS UniqueLicenseeLoginCount
		FROM WebSiteUserAnalysisTenant
		JOIN Users ON ID = WebSiteUserAnalysisTenant.LicenseeID
		JOIN WebSiteUserAnalysisPubCo ON WebSiteUserAnalysisPubCo.BDMID = WebSiteUserAnalysisTenant.BDMID
		JOIN WeeklyRMUsers
		  ON WeeklyRMUsers.RMID = WebSiteUserAnalysisPubCo.RMID
		 AND WeeklyRMUsers.WeekCommencing = WebSiteUserAnalysisTenant.WeekCommencing
		 AND WeeklyRMUsers.WeekCommencing = WebSiteUserAnalysisPubCo.WeekCommencing
	    WHERE WebSiteUserAnalysisTenant.WeekCommencing BETWEEN @From AND @To
	      AND WebSiteUserAnalysisPubCo.WeekCommencing BETWEEN @From AND @To
		  --AND LicenseeLoginCount > 0
		  AND Users.Anonymise = 0 AND Users.Deleted = 0 AND Users.WebActive = 1
		GROUP BY 
			CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE),
			WebSiteUserAnalysisPubCo.RMID,
			WebSiteUserAnalysisTenant.LicenseeID
	)
	SELECT	COALESCE(WeeklyLicenseeStats.WeekCommencing, MonthlyLicenseeStats.WeekCommencing) AS [WeekCommencing], 
			COALESCE(WeeklyLicenseeStats.RMID, MonthlyLicenseeStats.RMID) AS [UserID], 
			Users.UserName AS [UserName],
			COALESCE(WeeklyRMUsers.AverageLiveSites,MonthlyRMUsers.AverageLiveSites) AS iDraughtSites,
			COUNT(NULLIF(COALESCE(WeeklyLicenseeStats.UniqueLicenseeLoginCount, MonthlyLicenseeStats.UniqueLicenseeLoginCount),0)) AS UniqueLicenseeLogins,
			COALESCE(WeeklyRMUsers.AverageLiveSites,MonthlyRMUsers.AverageLiveSites) - COUNT(NULLIF(COALESCE(WeeklyLicenseeStats.UniqueLicenseeLoginCount, MonthlyLicenseeStats.UniqueLicenseeLoginCount),0)) AS NotLoggedInCount
	FROM Users
	LEFT OUTER JOIN MonthlyRMUsers 
	  ON MonthlyRMUsers.RMID = Users.ID
	 AND @Weekly = 0
	LEFT OUTER JOIN WeeklyRMUsers 
	  ON WeeklyRMUsers.RMID = Users.ID
	 AND @Weekly = 1
	LEFT OUTER JOIN WeeklyLicenseeStats
	  ON WeeklyLicenseeStats.RMID = WeeklyRMUsers.RMID
	 AND WeeklyLicenseeStats.WeekCommencing = WeeklyRMUsers.WeekCommencing
	 AND @Weekly = 1
	LEFT OUTER JOIN MonthlyLicenseeStats
	  ON MonthlyLicenseeStats.RMID = MonthlyRMUsers.RMID
	 AND MonthlyLicenseeStats.WeekCommencing = MonthlyRMUsers.WeekCommencing
	 AND @Weekly = 0
	WHERE COALESCE(WeeklyLicenseeStats.WeekCommencing, MonthlyLicenseeStats.WeekCommencing) IS NOT NULL
	GROUP BY 
		COALESCE(WeeklyLicenseeStats.WeekCommencing, MonthlyLicenseeStats.WeekCommencing), 
		COALESCE(WeeklyLicenseeStats.RMID, MonthlyLicenseeStats.RMID), 
		Users.UserName,
		COALESCE(WeeklyRMUsers.AverageLiveSites,MonthlyRMUsers.AverageLiveSites)
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserSubUserEngagementReport] TO PUBLIC
    AS [dbo];

