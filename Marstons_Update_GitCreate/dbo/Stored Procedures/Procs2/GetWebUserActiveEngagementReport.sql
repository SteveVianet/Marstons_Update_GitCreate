CREATE PROCEDURE [dbo].[GetWebUserActiveEngagementReport]
(
	@From				DATETIME,
	@To					DATETIME,
	@ShowIDraughtSites	BIT = 1
)
AS

SET NOCOUNT ON

DECLARE @DatabaseID INT

SET @To = DATEADD(SECOND, -1, DATEADD(DAY, 1, @To))

SELECT @DatabaseID = ID 
FROM [EDISSQL1\SQL1].ServiceLogger.dbo.EDISDatabases
WHERE Name = DB_NAME()

SELECT	Configuration.PropertyValue AS CompanyName,
		ManagementUsers,
		ManagementEngagement,
		ManagementEngagement / CASE WHEN ManagementUsers = 0 THEN 1 ELSE CAST(ManagementUsers AS FLOAT) END AS ManagementEngagementPercent,
		TenantUsers,
		TenantEngagement,
		TenantEngagement / CASE WHEN TenantUsers = 0 THEN 1 ELSE CAST(TenantUsers AS FLOAT) END AS TenantEngagementPercent
FROM
(
	SELECT	@DatabaseID AS DatabaseID,
			SUM(CASE WHEN UserTypeID IN (1, 2, 15) THEN 1 ELSE 0 END) AS ManagementUsers,
			SUM(CASE WHEN UserTypeID IN (5, 6) THEN 1 ELSE 0 END) AS TenantUsers
	FROM [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteUsers
	WHERE ((@ShowIDraughtSites = 1 AND iDraughtSites > 0) OR (@ShowIDraughtSites = 0 AND BMSSites > 0))
	AND DatabaseID = @DatabaseID
) AS Users
LEFT JOIN
(
	SELECT	@DatabaseID AS DatabaseID,
			COUNT(DISTINCT CASE WHEN WebSiteUsers.UserTypeID IN (1, 2, 15) THEN WebSiteUsers.UserID END) AS ManagementEngagement,
			COUNT(DISTINCT CASE WHEN WebSiteUsers.UserTypeID IN (5, 6) THEN WebSiteUsers.UserID END) AS TenantEngagement
	FROM [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteSession
	JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteSessionDatabases ON WebSiteSessionDatabases.SessionID = WebSiteSession.ID
	JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteUsers ON WebSiteUsers.UserID = WebSiteSessionDatabases.UserID
	WHERE ((@ShowIDraughtSites = 1 AND iDraughtSites > 0) OR (@ShowIDraughtSites = 0 AND BMSSites > 0))
	AND ([DateTime] BETWEEN @From AND @To)
	AND WebSiteUsers.DatabaseID = @DatabaseID
	AND Testing = 0
	AND Authenticated = 1
	AND ((@ShowIDraughtSites = 1 AND WebSiteID = 1 OR @ShowIDraughtSites = 0 AND WebSiteID = 2))
) AS Engagement ON Engagement.DatabaseID = Users.DatabaseID
JOIN Configuration ON PropertyName = 'Company Name'

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserActiveEngagementReport] TO PUBLIC
    AS [dbo];

