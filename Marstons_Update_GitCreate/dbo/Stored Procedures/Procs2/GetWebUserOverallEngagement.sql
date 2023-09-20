CREATE PROCEDURE [dbo].[GetWebUserOverallEngagement]
(
	@UserID		INT,
	@From		DATE,
	@To			DATE,
	@Weekly		BIT = 0,
	@Summary	BIT = 0,
	@EnableTesting	BIT = 0,
	@ShowIDraughtStats BIT = 1
)
AS

SET NOCOUNT ON

--Horrible RW bodge to default to CEO ('customer') if no user is supplied
--This is for the iDraught Report Pack
IF @UserID IS NULL
BEGIN
	SELECT @UserID = ID
	FROM Users
	WHERE UserType = 3 AND Deleted = 0 AND WebActive = 1
END

IF @To > GETDATE()
BEGIN
	SELECT @To = CAST(GETDATE() AS DATE)
END

DECLARE @AllSites BIT
DECLARE @UserTypeID INT
DECLARE @SubUserCount INT
DECLARE @SiteUserCount INT

SELECT @UserTypeID = UserType FROM Users WHERE ID = @UserID
SELECT @AllSites = AllSitesVisible FROM Users JOIN UserTypes ON UserTypes.ID = UserType WHERE Users.ID = @UserID
SELECT @SubUserCount = COUNT(DISTINCT(BDMID)) FROM WebSiteUserAnalysisPubCo WHERE (((@UserTypeID = 1) AND (RMID = @UserID)) OR ((@UserTypeID = 2) AND (BDMID = @UserID)) OR ((@UserTypeID = 3) OR (@UserTypeID = 4))) AND WebSiteUserAnalysisPubCo.WeekCommencing BETWEEN @From AND @To

DECLARE @BDMStats TABLE (WeekCommencing DATE NOT NULL, LoggedIn BIT NOT NULL, BDMID INT NOT NULL, SiteCount INT NOT NULL)
DECLARE @TenantStats TABLE (WeekCommencing DATE NOT NULL, LoggedIn BIT NOT NULL, LicenseeID INT NOT NULL, BDMID INT NOT NULL)

DECLARE @ManagementLogins TABLE (WeekCommencing DATE NOT NULL, UserType VARCHAR(50) NOT NULL, UserTypeID INT NOT NULL, UserID INT NOT NULL, UserName VARCHAR(100) NOT NULL, PagesServed INT, Logins INT, AvgPagesServed INT)
INSERT INTO @ManagementLogins
EXEC dbo.GetWebUserManagementLoginsReport @UserID, @From, @To

DECLARE @ManagementStats TABLE (WeekCommencing DATE NOT NULL, ManagementUsers INT, ManagementEngagement INT, ManagementEngagementPercent FLOAT)

INSERT INTO @ManagementStats
SELECT
	 FirstDateOfPeriod
	,COUNT(DISTINCT UserID) AS ManagementUsers
	,SUM(CASE WHEN LoginCount > 0 THEN 1 ELSE 0 END) AS ManagementEngagement
	,SUM(CASE WHEN LoginCount > 0 THEN 1 ELSE 0 END) / CAST(COUNT(DISTINCT UserID) AS FLOAT) AS ManagementEngagementPercent
FROM (
	SELECT
			UserID
		   ,CASE WHEN @Weekly = 0 THEN FirstDateOfMonth ELSE FirstDateOfWeek END AS FirstDateOfPeriod
		   ,COUNT(Logins) AS LoginCount
	FROM @ManagementLogins AS Management
	JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.Calendar
		AS Calendar ON Calendar.CalendarDate = Management.WeekCommencing
	WHERE CASE WHEN @Weekly = 0 THEN FirstDateOfMonth ELSE FirstDateOfWeek END BETWEEN @From AND @To 
	GROUP BY UserID, CASE WHEN @Weekly = 0 THEN FirstDateOfMonth ELSE FirstDateOfWeek END
	) AS LoginStats
GROUP BY FirstDateOfPeriod

IF @UserTypeID = 1
BEGIN
	SELECT @SiteUserCount = COUNT(DISTINCT(WebSiteUserAnalysisTenant.LicenseeID)) 
	FROM WebSiteUserAnalysisPubCo 
	JOIN WebSiteUserAnalysisTenant 
		ON WebSiteUserAnalysisTenant.BDMID = WebSiteUserAnalysisPubCo.BDMID
		AND WebSiteUserAnalysisTenant.WeekCommencing BETWEEN @From AND @To
	JOIN Users
		ON Users.ID = WebSiteUserAnalysisTenant.LicenseeID
	JOIN UserSites
		ON UserSites.UserID = WebSiteUserAnalysisTenant.LicenseeID
	JOIN Sites 
		ON Sites.EDISID = UserSites.EDISID
	WHERE RMID = @UserID
		AND WebSiteUserAnalysisPubCo.WeekCommencing BETWEEN @From AND @To
		AND Users.WebActive = 1
		AND Users.Anonymise = 0
		AND Users.Deleted = 0
		AND Sites.[Status] IN (1, 2, 10, 3, 4)
		AND ((Sites.Quality = 1 AND @ShowIDraughtStats = 1) OR (Sites.Quality = 0 AND @ShowIDraughtStats = 0))
END
ELSE IF @UserTypeID = 2
BEGIN
	SELECT @SiteUserCount = COUNT(DISTINCT(WebSiteUserAnalysisTenant.LicenseeID))
	FROM WebSiteUserAnalysisTenant 
	JOIN Users
		ON Users.ID = WebSiteUserAnalysisTenant.LicenseeID
	JOIN UserSites
		ON UserSites.UserID = WebSiteUserAnalysisTenant.LicenseeID
	JOIN Sites 
		ON Sites.EDISID = UserSites.EDISID
	WHERE BDMID = @UserID 
		AND WeekCommencing BETWEEN @From AND @To
		AND Users.WebActive = 1
		AND Users.Anonymise = 0
		AND Users.Deleted = 0
		AND Sites.[Status] IN (1, 2, 10, 3, 4)
		AND ((Sites.Quality = 1 AND @ShowIDraughtStats = 1) OR (Sites.Quality = 0 AND @ShowIDraughtStats = 0))
END
ELSE IF @UserTypeID IN (3, 4) AND @AllSites = 1
BEGIN
	SELECT @SiteUserCount = COUNT(DISTINCT(WebSiteUserAnalysisTenant.LicenseeID))
	FROM WebSiteUserAnalysisTenant 
	JOIN Users
		ON Users.ID = WebSiteUserAnalysisTenant.LicenseeID
	JOIN UserSites
		ON UserSites.UserID = WebSiteUserAnalysisTenant.LicenseeID
	JOIN Sites 
		ON Sites.EDISID = UserSites.EDISID
	WHERE  WeekCommencing BETWEEN @From AND @To
		AND BDMID IN (
			  SELECT DISTINCT(Users.ID) FROM Users
			  JOIN UserSites ON UserSites.UserID = Users.ID
			  WHERE UserType = 2)
		AND Users.WebActive = 1
		AND Users.Anonymise = 0
		AND Users.Deleted = 0
		AND Sites.[Status] IN (1, 2, 10, 3, 4)
		AND ((Sites.Quality = 1 AND @ShowIDraughtStats = 1) OR (Sites.Quality = 0 AND @ShowIDraughtStats = 0))
END
ELSE IF @UserTypeID IN (3, 4) AND @AllSites = 0
BEGIN
	SELECT @SiteUserCount = COUNT(DISTINCT(WebSiteUserAnalysisTenant.LicenseeID)) 
	FROM WebSiteUserAnalysisTenant 
	JOIN Users
		ON Users.ID = WebSiteUserAnalysisTenant.LicenseeID
	JOIN UserSites
		ON UserSites.UserID = WebSiteUserAnalysisTenant.LicenseeID
	JOIN Sites 
		ON Sites.EDISID = UserSites.EDISID
	WHERE WeekCommencing BETWEEN @From AND @To
	  AND BDMID IN (
			  SELECT DISTINCT(Users.ID) FROM Users
			  JOIN UserSites ON UserSites.UserID = Users.ID
			  WHERE UserType = 2
			  AND UserSites.EDISID IN (SELECT EDISID FROM UserSites WHERE UserSites.UserID = 256))
		AND Users.WebActive = 1
		AND Users.Anonymise = 0
		AND Users.Deleted = 0
		AND Sites.[Status] IN (1, 2, 10, 3, 4)
		AND ((Sites.Quality = 1 AND @ShowIDraughtStats = 1) OR (Sites.Quality = 0 AND @ShowIDraughtStats = 0))
END

IF @Summary = 0
BEGIN
	IF @EnableTesting = 0
	BEGIN
		--BDM Login Statistics
		INSERT INTO @BDMStats (WeekCommencing, LoggedIn, BDMID, SiteCount)
		SELECT 
			CASE @Weekly WHEN 1 THEN WebSiteUserAnalysisPubCo.WeekCommencing ELSE CASE @Summary WHEN 1 THEN @From ELSE CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE) END END AS [WeekCommencing],
			CASE WHEN COUNT(NULLIF(WebSiteUserAnalysisPubCo.BDMLoginCount,0)) > 0 THEN 1 ELSE 0 END AS LoggedIn,
			BDMID,
			AVG(BDMLiveIDraughtSites)
		FROM WebSiteUserAnalysisPubCo
		WHERE 
			(
			((@UserTypeID = 1) AND (RMID = @UserID)) 
			OR 
			((@UserTypeID = 2) AND (BDMID = @UserID))
			OR
			((@UserTypeID = 3) OR (@UserTypeID = 4))
			)
		GROUP BY 
			CASE @Weekly WHEN 1 THEN WebSiteUserAnalysisPubCo.WeekCommencing ELSE CASE @Summary WHEN 1 THEN @From ELSE CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE) END END,
			BDMID
		HAVING 
			CASE @Weekly WHEN 1 THEN WebSiteUserAnalysisPubCo.WeekCommencing ELSE CASE @Summary WHEN 1 THEN @From ELSE CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE) END END BETWEEN @From AND @To
		
		--Tenant Login Statistics
		INSERT INTO @TenantStats (WeekCommencing, LoggedIn, LicenseeID, BDMID)
		SELECT
			CASE @Weekly WHEN 1 THEN WebSiteUserAnalysisTenant.WeekCommencing ELSE CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE) END AS [WeekCommencing],
			CASE WHEN COUNT(NULLIF(WebSiteUserAnalysisTenant.LicenseeLoginCount,0)) > 0 THEN 1 ELSE 0 END AS LoggedIn,
			LicenseeID,
			WebSiteUserAnalysisTenant.BDMID
		FROM WebSiteUserAnalysisTenant
		JOIN(	SELECT BDMID
				FROM WebSiteUserAnalysisPubCo
				WHERE WeekCommencing BETWEEN @From AND @To
				AND (
					((@UserTypeID = 1) AND (RMID = @UserID)) 
					OR 
					((@UserTypeID = 2) AND (BDMID = @UserID))
					OR
					((@UserTypeID = 3) OR (@UserTypeID = 4))
					)
				) AS PubCoUsers ON PubCoUsers.BDMID = WebSiteUserAnalysisTenant.BDMID
		GROUP BY
			CASE @Weekly WHEN 1 THEN WebSiteUserAnalysisTenant.WeekCommencing ELSE CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE) END,
			LicenseeID,
			WebSiteUserAnalysisTenant.BDMID
		HAVING 
			CASE @Weekly WHEN 1 THEN WebSiteUserAnalysisTenant.WeekCommencing ELSE CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE) END BETWEEN @From AND @To

		--The BDM actual/percent numbers will not be fully accurate on a weekly/monthly level as they only calculate the total for the whole period, not each week/month
		SELECT
			Configuration.PropertyValue AS CompanyName, 
			Users.UserName AS ReportUser,
			BDMStats.WeekCommencing,
			@SubUserCount AS ManagementUsers,
			CAST(@SubUserCount * CASE WHEN CAST(@SubUserCount AS FLOAT) <> 0 THEN COUNT(NULLIF(BDMStats.LoggedIn,0)) / CAST(@SubUserCount AS FLOAT) ELSE 0 END AS INT) AS ManagementEngagement,
			CASE WHEN CAST(@SubUserCount AS FLOAT) <> 0 THEN
				COUNT(NULLIF(BDMStats.LoggedIn,0)) / CAST(@SubUserCount AS FLOAT) 
			ELSE 0 
			END AS ManagementEngagementPercent,
			@SiteUserCount AS TenantUsers,
			CAST(@SiteUserCount * AVG(TenantPercent) AS INT) AS TenantEngagement,
			AVG(TenantPercent) AS TenantEngagementPercent
		FROM @BDMStats AS BDMStats
		JOIN Configuration ON PropertyName = 'Company Name'
		JOIN 
			(
			SELECT	
				TenantStats.WeekCommencing,
				TenantStats.BDMID,
				CASE WHEN CAST(AVG(BDMStats.SiteCount) AS FLOAT) <> 0 THEN
					COUNT(NULLIF(TenantStats.LoggedIn,0)) / CAST(AVG(BDMStats.SiteCount) AS FLOAT)
				ELSE 0
				END AS TenantPercent
			FROM @TenantStats AS TenantStats
			JOIN @BDMStats AS BDMStats 
				ON BDMStats.WeekCommencing = TenantStats.WeekCommencing
				AND BDMStats.BDMID = TenantStats.BDMID
			GROUP BY 
				TenantStats.WeekCommencing,
				TenantStats.BDMID
			) AS TenantStats 
			ON TenantStats.WeekCommencing = BDMStats.WeekCommencing
			AND TenantStats.BDMID = BDMStats.BDMID
		JOIN Users 
			ON Users.ID = @UserID
		GROUP BY Configuration.PropertyValue, BDMStats.WeekCommencing, Users.UserName
	END
	ELSE
	BEGIN
		--BDM Login Statistics
		INSERT INTO @BDMStats (WeekCommencing, LoggedIn, BDMID, SiteCount)
		SELECT 
			CASE @Weekly WHEN 1 THEN WebSiteUserAnalysisPubCo.WeekCommencing ELSE CASE @Summary WHEN 1 THEN @From ELSE CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE) END END AS [WeekCommencing],
			CASE WHEN COUNT(NULLIF(WebSiteUserAnalysisPubCo.BDMLoginCount,0)) > 0 THEN 1 ELSE 0 END AS LoggedIn,
			BDMID,
			AVG(BDMLiveIDraughtSites)
		FROM WebSiteUserAnalysisPubCo
		WHERE 
			(
			((@UserTypeID = 1) AND (RMID = @UserID)) 
			OR 
			((@UserTypeID = 2) AND (BDMID = @UserID))
			OR
			((@UserTypeID = 3) OR (@UserTypeID = 4))
			)
		GROUP BY 
			CASE @Weekly WHEN 1 THEN WebSiteUserAnalysisPubCo.WeekCommencing ELSE CASE @Summary WHEN 1 THEN @From ELSE CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE) END END,
			BDMID
		HAVING 
			CASE @Weekly WHEN 1 THEN WebSiteUserAnalysisPubCo.WeekCommencing ELSE CASE @Summary WHEN 1 THEN @From ELSE CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE) END END BETWEEN @From AND @To
		
		--Tenant Login Statistics
		INSERT INTO @TenantStats (WeekCommencing, LoggedIn, LicenseeID, BDMID)
		SELECT
			CASE @Weekly WHEN 1 THEN WebSiteUserAnalysisTenant.WeekCommencing ELSE CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE) END AS [WeekCommencing],
			CASE WHEN COUNT(NULLIF(WebSiteUserAnalysisTenant.LicenseeLoginCount,0)) > 0 THEN 1 ELSE 0 END AS LoggedIn,
			LicenseeID,
			WebSiteUserAnalysisTenant.BDMID
		FROM WebSiteUserAnalysisTenant
		JOIN(	SELECT BDMID
				FROM WebSiteUserAnalysisPubCo
				WHERE WeekCommencing BETWEEN @From AND @To
				AND (
					((@UserTypeID = 1) AND (RMID = @UserID)) 
					OR 
					((@UserTypeID = 2) AND (BDMID = @UserID))
					OR
					((@UserTypeID = 3) OR (@UserTypeID = 4))
					)
				) AS PubCoUsers ON PubCoUsers.BDMID = WebSiteUserAnalysisTenant.BDMID
		GROUP BY
			CASE @Weekly WHEN 1 THEN WebSiteUserAnalysisTenant.WeekCommencing ELSE CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE) END,
			LicenseeID,
			WebSiteUserAnalysisTenant.BDMID
		HAVING 
			CASE @Weekly WHEN 1 THEN WebSiteUserAnalysisTenant.WeekCommencing ELSE CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisTenant.WeekCommencing), 0) AS DATE) END BETWEEN @From AND @To

		--The BDM actual/percent numbers will not be fully accurate on a weekly/monthly level as they only calculate the total for the whole period, not each week/month
		SELECT
			Configuration.PropertyValue AS CompanyName, 
			Users.UserName AS ReportUser,
			BDMStats.WeekCommencing,
			ManagementStats.ManagementUsers AS ManagementUsers,
			ManagementStats.ManagementEngagement AS ManagementEngagement,
			ManagementStats.ManagementEngagementPercent AS ManagementEngagementPercent,
			@SiteUserCount AS TenantUsers,
			CAST(@SiteUserCount * AVG(TenantPercent) AS INT) AS TenantEngagement,
			AVG(TenantPercent) AS TenantEngagementPercent
		FROM @BDMStats AS BDMStats
		JOIN Configuration ON PropertyName = 'Company Name'
		JOIN @ManagementStats AS ManagementStats
			ON ManagementStats.WeekCommencing = BDMStats.WeekCommencing
		JOIN 
			(
			SELECT	
				TenantStats.WeekCommencing,
				TenantStats.BDMID,
				CASE WHEN CAST(AVG(BDMStats.SiteCount) AS FLOAT) <> 0 THEN
					COUNT(NULLIF(TenantStats.LoggedIn,0)) / CAST(AVG(BDMStats.SiteCount) AS FLOAT)
				ELSE 0
				END AS TenantPercent
			FROM @TenantStats AS TenantStats
			JOIN @BDMStats AS BDMStats 
				ON BDMStats.WeekCommencing = TenantStats.WeekCommencing
				AND BDMStats.BDMID = TenantStats.BDMID
			GROUP BY 
				TenantStats.WeekCommencing,
				TenantStats.BDMID
			) AS TenantStats 
			ON TenantStats.WeekCommencing = BDMStats.WeekCommencing
			AND TenantStats.BDMID = BDMStats.BDMID
		JOIN Users 
			ON Users.ID = @UserID
		GROUP BY Configuration.PropertyValue, BDMStats.WeekCommencing, Users.UserName, ManagementUsers, ManagementEngagement, ManagementEngagementPercent	
	END
END
ELSE
BEGIN
	IF @EnableTesting = 0
	BEGIN
		--BDM Login Statistics
		INSERT INTO @BDMStats (WeekCommencing, LoggedIn, BDMID, SiteCount)
		SELECT 
			MIN(WebSiteUserAnalysisPubCo.WeekCommencing) AS [WeekCommencing],
			CASE WHEN COUNT(NULLIF(WebSiteUserAnalysisPubCo.BDMLoginCount,0)) > 0 THEN 1 ELSE 0 END AS LoggedIn,
			BDMID,
			AVG(BDMLiveIDraughtSites)
		FROM WebSiteUserAnalysisPubCo
		WHERE 
			(
			((@UserTypeID = 1) AND (RMID = @UserID)) 
			OR 
			((@UserTypeID = 2) AND (BDMID = @UserID))
			OR
			((@UserTypeID = 3) OR (@UserTypeID = 4))
			)
			AND WebSiteUserAnalysisPubCo.WeekCommencing BETWEEN @From AND @To
		GROUP BY 
			BDMID
			
		--Tenant Login Statistics
		INSERT INTO @TenantStats (WeekCommencing, LoggedIn, LicenseeID, BDMID)
		SELECT
			MIN(WebSiteUserAnalysisTenant.WeekCommencing),
			CASE WHEN COUNT(NULLIF(WebSiteUserAnalysisTenant.LicenseeLoginCount,0)) > 0 THEN 1 ELSE 0 END AS LoggedIn,
			LicenseeID,
			WebSiteUserAnalysisTenant.BDMID
		FROM WebSiteUserAnalysisTenant
		JOIN(	SELECT BDMID
				FROM WebSiteUserAnalysisPubCo
				WHERE WeekCommencing BETWEEN @From AND @To
				AND (
					((@UserTypeID = 1) AND (RMID = @UserID)) 
					OR 
					((@UserTypeID = 2) AND (BDMID = @UserID))
					OR
					((@UserTypeID = 3) OR (@UserTypeID = 4))
					)
				) AS PubCoUsers ON PubCoUsers.BDMID = WebSiteUserAnalysisTenant.BDMID
		WHERE WebSiteUserAnalysisTenant.WeekCommencing BETWEEN @From AND @To
		GROUP BY
			LicenseeID,
			WebSiteUserAnalysisTenant.BDMID

		SELECT
			Configuration.PropertyValue AS CompanyName, 
			Users.UserName AS ReportUser,
			MIN(BDMStats.WeekCommencing) AS WeekCommencing,
			@SubUserCount AS ManagementUsers,
			CAST(@SubUserCount * CASE WHEN CAST(@SubUserCount AS FLOAT) <> 0 THEN COUNT(NULLIF(BDMStats.LoggedIn,0)) / CAST(@SubUserCount AS FLOAT) ELSE 0 END AS INT) AS ManagementEngagement,
			CASE WHEN CAST(@SubUserCount AS FLOAT) <> 0 THEN
				COUNT(NULLIF(BDMStats.LoggedIn,0)) / CAST(@SubUserCount AS FLOAT) 
			ELSE 0 
			END AS ManagementEngagementPercent,
			@SiteUserCount AS TenantUsers,
			SUM(TenantCount) AS TenantEngagement,
			(SUM(TenantCount) / CAST(@SiteUserCount AS FLOAT)) AS TenantEngagementPercent
		FROM @BDMStats AS BDMStats
		JOIN Configuration ON PropertyName = 'Company Name'
		JOIN 
			(
			SELECT	
				TenantStats.BDMID,
				COUNT(NULLIF(TenantStats.LoggedIn,0)) AS TenantCount
			FROM @TenantStats AS TenantStats
			JOIN @BDMStats AS BDMStats 
				ON BDMStats.BDMID = TenantStats.BDMID
			GROUP BY 
				TenantStats.BDMID
			) AS TenantStats 
			ON TenantStats.BDMID = BDMStats.BDMID
		JOIN Users 
			ON Users.ID = @UserID
		GROUP BY Configuration.PropertyValue, Users.UserName
	END
	ELSE
	BEGIN
		--BDM Login Statistics
		INSERT INTO @BDMStats (WeekCommencing, LoggedIn, BDMID, SiteCount)
		SELECT 
			MIN(WebSiteUserAnalysisPubCo.WeekCommencing) AS [WeekCommencing],
			CASE WHEN COUNT(NULLIF(WebSiteUserAnalysisPubCo.BDMLoginCount,0)) > 0 THEN 1 ELSE 0 END AS LoggedIn,
			BDMID,
			AVG(BDMLiveIDraughtSites)
		FROM WebSiteUserAnalysisPubCo
		WHERE 
			(
			((@UserTypeID = 1) AND (RMID = @UserID)) 
			OR 
			((@UserTypeID = 2) AND (BDMID = @UserID))
			OR
			((@UserTypeID = 3) OR (@UserTypeID = 4))
			)
			AND WebSiteUserAnalysisPubCo.WeekCommencing BETWEEN @From AND @To
		GROUP BY 
			BDMID
			
		--Tenant Login Statistics
		INSERT INTO @TenantStats (WeekCommencing, LoggedIn, LicenseeID, BDMID)
		SELECT
		MIN(WebSiteUserAnalysisTenant.WeekCommencing),
		CASE WHEN COUNT(NULLIF(WebSiteUserAnalysisTenant.LicenseeLoginCount,0)) > 0 THEN 1 ELSE 0 END AS LoggedIn,
		LicenseeID,
		WebSiteUserAnalysisTenant.BDMID
	FROM WebSiteUserAnalysisTenant
	JOIN(	SELECT BDMID
			FROM WebSiteUserAnalysisPubCo
			WHERE WeekCommencing BETWEEN @From AND @To
			AND (
				((@UserTypeID = 1) AND (RMID = @UserID)) 
				OR 
				((@UserTypeID = 2) AND (BDMID = @UserID))
				OR
				((@UserTypeID = 3) OR (@UserTypeID = 4))
				)
			) AS PubCoUsers ON PubCoUsers.BDMID = WebSiteUserAnalysisTenant.BDMID
	WHERE WebSiteUserAnalysisTenant.WeekCommencing BETWEEN @From AND @To
	GROUP BY
		LicenseeID,
		WebSiteUserAnalysisTenant.BDMID

	SELECT
		Configuration.PropertyValue AS CompanyName, 
		Users.UserName AS ReportUser,
		MIN(BDMStats.WeekCommencing) AS WeekCommencing,
		ManagementStats.ManagementUsers AS ManagementUsers,
		ManagementStats.ManagementEngagement AS ManagementEngagement,
		ManagementStats.ManagementEngagementPercent AS ManagementEngagementPercent,
		@SiteUserCount AS TenantUsers,
		SUM(TenantCount) AS TenantEngagement,
		(SUM(TenantCount) / CAST(@SiteUserCount AS FLOAT)) AS TenantEngagementPercent
	FROM @BDMStats AS BDMStats
	JOIN Configuration ON PropertyName = 'Company Name'
	JOIN 
		(
		SELECT	
			TenantStats.BDMID,
			COUNT(NULLIF(TenantStats.LoggedIn,0)) AS TenantCount
		FROM @TenantStats AS TenantStats
		JOIN @BDMStats AS BDMStats 
			ON BDMStats.BDMID = TenantStats.BDMID
		GROUP BY 
			TenantStats.BDMID
		) AS TenantStats 
		ON TenantStats.BDMID = BDMStats.BDMID
	CROSS JOIN
		(
			SELECT 
				AVG(ManagementUsers) AS ManagementUsers,
				AVG(ManagementEngagement) AS ManagementEngagement,
				AVG(ManagementEngagementPercent) AS ManagementEngagementPercent
			FROM
				@ManagementStats
		) AS ManagementStats
	JOIN Users 
		ON Users.ID = @UserID
	GROUP BY Configuration.PropertyValue, Users.UserName, ManagementStats.ManagementUsers, ManagementStats.ManagementEngagement, ManagementStats.ManagementEngagementPercent	
	END

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserOverallEngagement] TO PUBLIC
    AS [dbo];

