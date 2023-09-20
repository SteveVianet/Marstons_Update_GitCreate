CREATE PROCEDURE [dbo].[GetWebUserSessionTimeReport]
(
	@From DATE,
	@To DATE,
	@UserID INT = NULL,
	@Weekly BIT = 1,
	@ShowLicenseeTimes BIT = 0
)
AS

DECLARE @AllSites AS BIT
DECLARE @UserType INT
SELECT @AllSites = AllSitesVisible, @UserType = UserType FROM Users JOIN UserTypes ON UserTypes.ID = UserType WHERE Users.ID = @UserID

DECLARE @StartLimit DATE
SET @StartLimit = CASE @Weekly WHEN 1 THEN '2011-06-06' ELSE '2011-06-01' END
IF @StartLimit > @From
BEGIN
	SET @From = @StartLimit
END

IF @ShowLicenseeTimes = 1 AND @UserType IN (1,2)
BEGIN
	SELECT	CASE @Weekly
			WHEN 1 THEN
				CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE)
			ELSE
				CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE)
			END AS [WeekCommencing], 
			WebSiteUserAnalysisTenant.BDMID AS UserID,
			BDMUsers.UserName AS UserName,
			WebSiteUserAnalysisTenant.LicenseeID AS LicenseeUserID,
			LicenseeUsers.UserName AS LicenseeUserName,
			AVG(NULLIF(WebSiteUserAnalysisTenant.LicenseeSessionAverage, 0))/60.0 AS SessionTime,
			AVG(WebSiteUserAnalysisTenant.LicenseeSessionAverage)/60.0 AS RawSessionTime,		
			SUM(WebSiteUserAnalysisTenant.LicenseePagesAccessed) AS PagesAccessed
	FROM WebSiteUserAnalysisTenant
	JOIN Users AS LicenseeUsers
	  ON LicenseeUsers.ID = WebSiteUserAnalysisTenant.LicenseeID
	  AND LicenseeUsers.Anonymise = 0 AND LicenseeUsers.Deleted = 0 AND LicenseeUsers.WebActive = 1
	JOIN (	SELECT BDMID, UserName
			FROM WebSiteUserAnalysisPubCo
			JOIN Users AS BDMUsers
			  ON BDMUsers.ID = WebSiteUserAnalysisPubCo.BDMID
			WHERE (
					  ((@UserID IS NULL) OR  (@AllSites = 1)) --Include everyone
					   OR
					  ((@UserType = 1) AND (WebSiteUserAnalysisPubCo.RMID = @UserID)) --Limit to RM
					   OR
					  ((@UserType = 2) AND (WebSiteUserAnalysisPubCo.BDMID = @UserID)) --Limit to BDM
				  )
			AND BDMUsers.Anonymise = 0 AND BDMUsers.Deleted = 0 AND BDMUsers.WebActive = 1
			GROUP BY BDMID, UserName) AS BDMUsers
		ON BDMUsers.BDMID = WebSiteUserAnalysisTenant.BDMID
	WHERE 
	  CASE @Weekly
				WHEN 1 THEN
					CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE)
				ELSE
					CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE)
				END BETWEEN @From AND @To
	  --AND WebSiteUserAnalysisPubCo.BDMSessionAverage > 0
	GROUP BY	CASE @Weekly
				WHEN 1 THEN
					CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE)
				ELSE
					CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE)
				END,
				WebSiteUserAnalysisTenant.BDMID,
				BDMUsers.UserName,
				WebSiteUserAnalysisTenant.LicenseeID,
				LicenseeUsers.UserName
	HAVING CASE @Weekly
				WHEN 1 THEN
					CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE)
				ELSE
					CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE)
				END BETWEEN @From AND @To
	ORDER BY WeekCommencing, WebSiteUserAnalysisTenant.BDMID
END
ELSE IF @ShowLicenseeTimes = 1 AND @UserType IN (3,4)
BEGIN
	SELECT	CASE @Weekly
			WHEN 1 THEN
				CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE)
			ELSE
				CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE)
			END AS [WeekCommencing], 
			BDMUsers.RMID AS UserID,
			RMUsers.UserName AS UserName,
			WebSiteUserAnalysisTenant.LicenseeID AS LicenseeUserID,
			LicenseeUsers.UserName AS LicenseeUserName,
			AVG(NULLIF(WebSiteUserAnalysisTenant.LicenseeSessionAverage, 0))/60.0 AS SessionTime,
			AVG(WebSiteUserAnalysisTenant.LicenseeSessionAverage)/60.0 AS RawSessionTime,		
			SUM(WebSiteUserAnalysisTenant.LicenseePagesAccessed) AS PagesAccessed
	FROM WebSiteUserAnalysisTenant
	JOIN Users AS LicenseeUsers
	  ON LicenseeUsers.ID = WebSiteUserAnalysisTenant.LicenseeID
	  AND LicenseeUsers.Anonymise = 0 AND LicenseeUsers.Deleted = 0 AND LicenseeUsers.WebActive = 1
	JOIN (	SELECT RMID, BDMID, UserName
			FROM WebSiteUserAnalysisPubCo
			JOIN Users AS BDMUsers
			  ON BDMUsers.ID = WebSiteUserAnalysisPubCo.BDMID
			WHERE (
					  ((@UserID IS NULL) OR  (@AllSites = 1)) --Include everyone
					   OR
					  ((@UserType IN (3,4)))
				  )
			AND BDMUsers.Anonymise = 0 AND BDMUsers.Deleted = 0 AND BDMUsers.WebActive = 1
			GROUP BY RMID, BDMID, UserName) AS BDMUsers
		ON BDMUsers.BDMID = WebSiteUserAnalysisTenant.BDMID
	JOIN Users AS RMUsers
		ON RMUsers.ID = BDMUsers.RMID
	WHERE 
	  CASE @Weekly
				WHEN 1 THEN
					CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE)
				ELSE
					CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE)
				END BETWEEN @From AND @To
	  --AND WebSiteUserAnalysisPubCo.BDMSessionAverage > 0
	  AND RMUsers.Anonymise = 0 AND RMUsers.Deleted = 0 AND RMUsers.WebActive = 1 -- RW: Did this for MF ex-Punch users in Spirit
	GROUP BY	CASE @Weekly
				WHEN 1 THEN
					CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE)
				ELSE
					CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE)
				END,
				BDMUsers.RMID,
				RMUsers.UserName,
				WebSiteUserAnalysisTenant.LicenseeID,
				LicenseeUsers.UserName
	HAVING CASE @Weekly
				WHEN 1 THEN
					CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE)
				ELSE
					CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE)
				END BETWEEN @From AND @To
	ORDER BY WeekCommencing, BDMUsers.RMID
END
ELSE IF @ShowLicenseeTimes = 0 AND @UserType = 1
BEGIN
	SELECT	CASE @Weekly
			WHEN 1 THEN
				CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE)
			ELSE
				CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE)
			END AS [WeekCommencing], 
			WebSiteUserAnalysisPubCo.BDMID AS UserID,
			BDMUsers.UserName AS UserName,
			AVG(NULLIF(WebSiteUserAnalysisPubCo.BDMSessionAverage, 0))/60.0 AS SessionTime,
			AVG(WebSiteUserAnalysisPubCo.BDMSessionAverage)/60.0 AS RawSessionTime
	FROM WebSiteUserAnalysisPubCo 
	JOIN Users AS BDMUsers
	  ON BDMUsers.ID = WebSiteUserAnalysisPubCo.BDMID
	WHERE (
			  ((@UserID IS NULL) OR (@AllSites = 1)) --Include everyone
			   OR
			  ((@UserType = 1) AND (WebSiteUserAnalysisPubCo.RMID = @UserID)) --Limit to RM
		  )
	  AND BDMUsers.Anonymise = 0 AND BDMUsers.Deleted = 0 AND BDMUsers.WebActive = 1
	  --AND WebSiteUserAnalysisPubCo.BDMSessionAverage > 0
	GROUP BY	CASE @Weekly
				WHEN 1 THEN
					CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE)
				ELSE
					CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE)
				END,
				WebSiteUserAnalysisPubCo.BDMID,
				BDMUsers.UserName
	HAVING CASE @Weekly
				WHEN 1 THEN
					CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE)
				ELSE
					CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE)
				END BETWEEN @From AND @To
END
ELSE IF @ShowLicenseeTimes = 0 AND @UserType = 2
BEGIN
	SELECT	CASE @Weekly
			WHEN 1 THEN
				CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE)
			ELSE
				CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE)
			END AS [WeekCommencing], 
			WebSiteUserAnalysisPubCo.BDMID AS UserID,
			BDMUsers.UserName AS UserName,
			AVG(NULLIF(WebSiteUserAnalysisPubCo.BDMSessionAverage, 0))/60.0 AS SessionTime,
			AVG(WebSiteUserAnalysisPubCo.BDMSessionAverage)/60.0 AS RawSessionTime
	FROM WebSiteUserAnalysisPubCo 
	JOIN Users AS BDMUsers
	  ON BDMUsers.ID = WebSiteUserAnalysisPubCo.BDMID
	WHERE BDMID = @UserID
	  AND BDMUsers.Anonymise = 0 AND BDMUsers.Deleted = 0 AND BDMUsers.WebActive = 1
	  --AND WebSiteUserAnalysisPubCo.BDMSessionAverage > 0
	GROUP BY	CASE @Weekly
				WHEN 1 THEN
					CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE)
				ELSE
					CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE)
				END,
				WebSiteUserAnalysisPubCo.BDMID,
				BDMUsers.UserName
	HAVING CASE @Weekly
				WHEN 1 THEN
					CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE)
				ELSE
					CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE)
				END BETWEEN @From AND @To
END
ELSE IF @ShowLicenseeTimes = 0 AND @UserType IN (3,4)
BEGIN
	SELECT	CASE @Weekly
			WHEN 1 THEN
				CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE)
			ELSE
				CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE)
			END AS [WeekCommencing], 
			WebSiteUserAnalysisPubCo.RMID AS UserID,
			RMUsers.UserName AS UserName,
			AVG(NULLIF(WebSiteUserAnalysisPubCo.BDMSessionAverage, 0))/60.0 AS SessionTime,
			AVG(WebSiteUserAnalysisPubCo.BDMSessionAverage)/60.0 AS RawSessionTime
	FROM WebSiteUserAnalysisPubCo 
	JOIN Users AS RMUsers
	  ON RMUsers.ID = WebSiteUserAnalysisPubCo.RMID	
	JOIN Users AS BDMUsers
	  ON BDMUsers.ID = WebSiteUserAnalysisPubCo.BDMID
	WHERE (
			  ((@UserID IS NULL) OR ((@UserType IN (3, 4)) AND (@AllSites = 1))) --Include everyone
			   OR
			  ((@UserType IN (3, 4) AND @AllSites = 0) AND WebSiteUserAnalysisPubCo.BDMID IN 
				(	SELECT DISTINCT(UserID) AS UserID
					FROM UserSites
					JOIN Users ON Users.ID = UserSites.UserID
					WHERE EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID)
					  AND Users.UserType = 2 AND Users.Deleted = 0 AND Users.WebActive = 1 AND Users.Anonymise = 0))
			   OR
			  ((@UserType = 1) AND (WebSiteUserAnalysisPubCo.RMID = @UserID)) --Limit to RM
		  )
	  
	  AND RMUsers.Anonymise = 0 AND RMUsers.Deleted = 0 AND RMUsers.WebActive = 1
	  AND BDMUsers.Anonymise = 0 AND BDMUsers.Deleted = 0 AND BDMUsers.WebActive = 1
	  --AND WebSiteUserAnalysisPubCo.BDMSessionAverage > 0
	GROUP BY	CASE @Weekly
				WHEN 1 THEN
					CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE)
				ELSE
					CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE)
				END,
				WebSiteUserAnalysisPubCo.RMID,
				RMUsers.UserName
	HAVING CASE @Weekly
				WHEN 1 THEN
					CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE)
				ELSE
					CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE)
				END BETWEEN @From AND @To
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserSessionTimeReport] TO PUBLIC
    AS [dbo];

