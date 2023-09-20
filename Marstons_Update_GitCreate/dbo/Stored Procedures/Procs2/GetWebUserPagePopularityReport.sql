CREATE PROCEDURE [dbo].[GetWebUserPagePopularityReport]
(
	@UserID		INT,
	@From		DATE,
	@To			DATE,
	@ShowLicenseeInfo	BIT = 1
)
AS

CREATE TABLE #PageLogs (SessionID INT NOT NULL, [Type] VARCHAR(256) NOT NULL, [DateTime] DATETIME NOT NULL)

DECLARE @DatabaseID INT
DECLARE @AllSites BIT

DECLARE @StartLimit DATE
SET @StartLimit = '2011-06-06'
IF @StartLimit > @From
BEGIN
	SET @From = @StartLimit
END

SELECT @AllSites = AllSitesVisible FROM Users JOIN UserTypes ON UserTypes.ID = UserType WHERE Users.ID = @UserID

SELECT @DatabaseID = ID FROM [SQL1\SQL1].ServiceLogger.dbo.EDISDatabases
WHERE Name = DB_NAME()

INSERT INTO #PageLogs (SessionID, [Type], [DateTime])
SELECT PageLogs.SessionID, [Type], [DateTime]
FROM [SQL1\SQL1].ServiceLogger.dbo.WebSitePageLogs AS PageLogs
JOIN (
	SELECT DISTINCT(SessionID) AS SessionID
	FROM [SQL1\SQL1].ServiceLogger.dbo.WebSiteSessionDatabases AS WebDatabaseInfo
	JOIN [SQL1\SQL1].ServiceLogger.dbo.WebSiteSession AS WebSiteSessions
	  ON WebSiteSessions.ID = WebDatabaseInfo.SessionID
	JOIN	(SELECT Users.ID, UserName
			 FROM Users
			 JOIN UserTypes ON UserTypes.ID = Users.UserType
			 JOIN UserSites ON UserSites.UserID = Users.ID
			 JOIN (SELECT DISTINCT(EDISID) FROM UserSites WHERE (UserID = @UserID) OR (@AllSites = 1)) AS WantedSites
			   ON WantedSites.EDISID = UserSites.EDISID
			 WHERE
				((@ShowLicenseeInfo = 1) AND (UserTypes.ID IN (5,6)))
				 OR
				((@ShowLicenseeInfo = 0) AND (UserTypes.ID IN (2)))
			 GROUP BY Users.ID, UserName) AS LicenseeUsers
	  ON LicenseeUsers.ID = WebDatabaseInfo.UserID
	WHERE DatabaseID = @DatabaseID
	  AND (([DateTime] >= @From) AND ([DateTime] < DATEADD(DAY, 1, @To)))
	  AND Testing = 0
	) AS RelevantSessions
  ON RelevantSessions.SessionID = PageLogs.SessionID
JOIN [SQL1\SQL1].ServiceLogger.dbo.WebSitePages AS Pages
  ON Pages.PageType = PageLogs.[Type]
WHERE Pages.ReportedOn = 1
  AND IsPostBack = 0
  AND (CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, [DateTime]), 0) AS DATE) BETWEEN @From AND @To)

SELECT	CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, [DateTime]), 0) AS DATE) AS [WeekCommencing],
		Pages.[Description] AS Page,
		COUNT([Type]) AS Count
FROM #PageLogs AS PageLogs
JOIN [SQL1\SQL1].ServiceLogger.dbo.WebSitePages AS Pages
  ON Pages.PageType = PageLogs.[Type]
JOIN (
	SELECT	--TOP 5 
			Pages.[Description] AS Page,
			COUNT(Pages.[Description]) AS Count
	FROM #PageLogs AS PageLogs
	JOIN (
		SELECT DISTINCT(SessionID) AS SessionID
		FROM #PageLogs) AS RelevantSessions
	  ON RelevantSessions.SessionID = PageLogs.SessionID
	JOIN [SQL1\SQL1].ServiceLogger.dbo.WebSitePages AS Pages
	  ON Pages.PageType = PageLogs.[Type]
	WHERE Pages.ReportedOn = 1
	GROUP BY Pages.[Description]
	--ORDER BY COUNT(Pages.[Description]) DESC
	) AS TopFive
  ON TopFive.Page = Pages.[Description]
GROUP BY CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, [DateTime]), 0) AS DATE), Pages.[Description]
HAVING CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, [DateTime]), 0) AS DATE) >= @From
ORDER BY CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, [DateTime]), 0) AS DATE) ASC

DROP TABLE #PageLogs
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserPagePopularityReport] TO PUBLIC
    AS [dbo];

