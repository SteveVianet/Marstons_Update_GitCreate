CREATE PROCEDURE [dbo].[GetWebUserBDMEngagementReport]
(
	@From DATE,
	@To DATE,
	@UserID INT,
	@Weekly BIT = 1
)
AS


CREATE TABLE #UniqueLogins (WeekCommencing DATE NOT NULL, 
							UserID INT NOT NULL, 
							UniqueBDMLogins INT NOT NULL
							)

DECLARE @AllSites BIT
DECLARE @UserType INT

SELECT @AllSites = AllSitesVisible, @UserType = UserType FROM Users JOIN UserTypes ON UserTypes.ID = UserType WHERE Users.ID = @UserID

DECLARE @ReportUsersName AS VARCHAR(255)
SELECT @ReportUsersName = UserName FROM Users WHERE ID = @UserID

DECLARE @TargetManagementEngagement AS FLOAT
SELECT  @TargetManagementEngagement = CAST(PropertyValue AS FLOAT) FROM Configuration WHERE PropertyName = 'TargetManagementEngagement'

DECLARE @StartLimit DATE
SET @StartLimit = '2011-06-06'
IF @StartLimit > @From
BEGIN
	SET @From = @StartLimit
END

IF @UserType IN (1) --RM
BEGIN 
	IF @Weekly = 1
	BEGIN --WEEKLY
		INSERT INTO #UniqueLogins (WeekCommencing, UserID, UniqueBDMLogins)
		SELECT 
			WeekCommencing,
			BDMID,
			COUNT(NULLIF(WebSiteUserAnalysisPubCo.BDMLoginCount,0)) AS UniqueBDMLoginCount
		FROM
			WebSiteUserAnalysisPubCo
		JOIN
			Users
			ON Users.ID = WebSiteUserAnalysisPubCo.BDMID
		WHERE
			(WeekCommencing BETWEEN @From AND @To)
			AND
			(Users.Anonymise = 0 AND Users.Deleted = 0 AND Users.WebActive = 1)
			AND
			(WebSiteUserAnalysisPubCo.RMID = @UserID)
		GROUP BY
			WeekCommencing,
			BDMID
	END
	ELSE
	BEGIN --MONTHLY
		INSERT INTO #UniqueLogins (WeekCommencing, UserID, UniqueBDMLogins)
		SELECT 
			WeekCommencing,
			BDMID,
			COUNT(NULLIF(UniqueBDMLoginCount,0)) AS UniqueBDMLoginCount
		FROM (	
			SELECT 
				CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE) AS WeekCommencing,
				BDMID,
				COUNT(NULLIF(WebSiteUserAnalysisPubCo.BDMLoginCount,0)) AS UniqueBDMLoginCount
			FROM
				WebSiteUserAnalysisPubCo
			JOIN
				Users
				ON Users.ID = WebSiteUserAnalysisPubCo.BDMID
			WHERE
				(WeekCommencing BETWEEN @From AND @To)
				AND
				(Users.Anonymise = 0 AND Users.Deleted = 0 AND Users.WebActive = 1)
				AND
				(WebSiteUserAnalysisPubCo.RMID = @UserID)
			GROUP BY
				CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE),
				BDMID
			) AS BDMLogins
		GROUP BY
			WeekCommencing,
			BDMID
	END

	SELECT 
		BDMDetails.WeekCommencing,
		BDMDetails.UserID,
		BDMDetails.UserName,
		BDMDetails.NumberOfBDMs,
		BDMDetails.BDMLoginCount,
		BDMDetails.NumberOfBDMs - LoginDetails.UniqueBDMLogins AS NotLoggedInCount,
		@ReportUsersName AS ReportUsersName,
		@TargetManagementEngagement AS TargetManagementEngagement
	FROM (
		SELECT 
			CASE @Weekly WHEN 1 THEN
				WebSiteUserAnalysisPubCo.WeekCommencing
			ELSE
				CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE)
			END AS [WeekCommencing],
			WebSiteUserAnalysisPubCo.BDMID AS UserID,
			Users.UserName,
			1 AS NumberOfBDMs,
			SUM(WebSiteUserAnalysisPubCo.BDMLoginCount) AS BDMLoginCount
		FROM
			WebSiteUserAnalysisPubCo
		JOIN
			Users
			ON Users.ID = WebSiteUserAnalysisPubCo.BDMID
		WHERE
			(WeekCommencing BETWEEN @From AND @To)
			AND
			(Users.Anonymise = 0 AND Users.Deleted = 0 AND Users.WebActive = 1)
			AND
			(WebSiteUserAnalysisPubCo.RMID = @UserID)
		GROUP BY 
			CASE @Weekly WHEN 1 THEN
				WeekCommencing
			ELSE
				CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE)
			END,
			BDMID,
			Users.UserName
		 ) AS BDMDetails
	JOIN 
		#UniqueLogins AS LoginDetails
		ON LoginDetails.WeekCommencing = BDMDetails.WeekCommencing
		AND LoginDetails.UserID = BDMDetails.UserID	
END
ELSE IF @UserType IN (3,4) --CEO/MD
BEGIN
	IF @Weekly = 1
	BEGIN --WEEKLY
		INSERT INTO #UniqueLogins (WeekCommencing, UserID, UniqueBDMLogins)
		SELECT 
			WeekCommencing,
			RMID,
			COUNT(NULLIF(WebSiteUserAnalysisPubCo.BDMLoginCount,0)) AS UniqueBDMLoginCount
		FROM
			WebSiteUserAnalysisPubCo
		JOIN
			Users
			ON Users.ID = WebSiteUserAnalysisPubCo.BDMID
		WHERE
			(WeekCommencing BETWEEN @From AND @To)
			AND
			(Users.Anonymise = 0 AND Users.Deleted = 0 AND Users.WebActive = 1)
		GROUP BY
			WeekCommencing,
			RMID
	END
	ELSE
	BEGIN --MONTHLY
		INSERT INTO #UniqueLogins (WeekCommencing, UserID, UniqueBDMLogins)
		SELECT 
			WeekCommencing,
			RMID,
			COUNT(NULLIF(UniqueBDMLoginCount,0)) AS UniqueBDMLoginCount
		FROM (	
			SELECT 
				CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE) AS WeekCommencing,
				RMID,
				BDMID,
				COUNT(NULLIF(WebSiteUserAnalysisPubCo.BDMLoginCount,0)) AS UniqueBDMLoginCount
			FROM
				WebSiteUserAnalysisPubCo
			JOIN
				Users
				ON Users.ID = WebSiteUserAnalysisPubCo.BDMID
			WHERE
				(WeekCommencing BETWEEN @From AND @To)
				AND
				(Users.Anonymise = 0 AND Users.Deleted = 0 AND Users.WebActive = 1)
			GROUP BY
				CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE),
				RMID,
				BDMID
			) AS BDMLogins
		GROUP BY
			WeekCommencing,
			RMID
	END
	
	SELECT 
		RMDetails.WeekCommencing,
		RMDetails.UserID,
		RMDetails.UserName,
		RMDetails.NumberOfBDMs,
		RMDetails.BDMLoginCount,
		RMDetails.NumberOfBDMs - LoginDetails.UniqueBDMLogins AS NotLoggedInCount,
		@ReportUsersName AS ReportUsersName,
		@TargetManagementEngagement AS TargetManagementEngagement	
	FROM (
		SELECT 
			CASE @Weekly WHEN 1 THEN
				WebSiteUserAnalysisPubCo.WeekCommencing
			ELSE
				CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE)
			END AS [WeekCommencing],
			WebSiteUserAnalysisPubCo.RMID AS UserID,
			Users.UserName,
			COUNT(DISTINCT WebSiteUserAnalysisPubCo.BDMID) AS NumberOfBDMs,
			SUM(WebSiteUserAnalysisPubCo.BDMLoginCount) AS BDMLoginCount
		FROM
			WebSiteUserAnalysisPubCo
		JOIN
			Users
			ON Users.ID = WebSiteUserAnalysisPubCo.RMID
		WHERE
			(WeekCommencing BETWEEN @From AND @To)
			AND
			(Users.Anonymise = 0 AND Users.Deleted = 0 AND Users.WebActive = 1)
		GROUP BY 
			CASE @Weekly WHEN 1 THEN
				WeekCommencing
			ELSE
				CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteUserAnalysisPubCo.WeekCommencing), 0) AS DATE)
			END,
			RMID,
			Users.UserName
		 ) AS RMDetails
	JOIN 
		#UniqueLogins AS LoginDetails
		ON LoginDetails.WeekCommencing = RMDetails.WeekCommencing
		AND LoginDetails.UserID = RMDetails.UserID
END

DROP TABLE #UniqueLogins
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserBDMEngagementReport] TO PUBLIC
    AS [dbo];

