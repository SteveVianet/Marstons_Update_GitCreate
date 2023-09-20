CREATE PROCEDURE [dbo].[GetWebUserManagementLoginsReport]
(
	@UserID			INT,
	@From			DATE,
	@To				DATE
)
AS

DECLARE @DatabaseID INT

SELECT @DatabaseID = ID 
FROM [EDISSQL1\SQL1].ServiceLogger.dbo.EDISDatabases
WHERE Name = DB_NAME()

--EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.[GetWebStatisticsManagementLoginsReport] @DatabaseID, @UserID, @From, @To

SET NOCOUNT ON

-- Get the Current Users Type
DECLARE @MasterUserType	INT
IF @UserID IS NOT NULL AND @DatabaseID IS NOT NULL
BEGIN
	SELECT @MasterUserType = WebSiteUsers.UserTypeID
	FROM [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteUsers AS WebSiteUsers
	WHERE
		WebSiteUsers.DatabaseID = @DatabaseID
	AND WebSiteUsers.UserID = @UserID
END

-- Get whether the User has implicit site assignments
DECLARE @AllSitesVisible BIT
IF @MasterUserType IS NOT NULL
BEGIN
	SELECT @AllSitesVisible = UserTypes.AllSitesVisible
	FROM UserTypes
	WHERE ID = @MasterUserType
END

-- Work out whether we need Weekly or Monthly periods
DECLARE @Weekly BIT
IF DATEDIFF(WEEK, @From, @To) < 8
BEGIN
	-- Less than 8 weeks, use Weekly periods
	SET @Weekly = 1
END
ELSE
BEGIN
	-- 8 weeks or more, use Monthly periods
	SET @Weekly = 0
END

SELECT Calendar.PeriodDate						AS PeriodCommencing
	  ,WebSiteUsers.UserType					AS UserType
	  ,WebSiteUsers.UserTypeID					AS UserTypeID
	  ,WebSiteUsers.UserID						AS UserID
	  ,WebSiteUsers.UserName					AS UserName
	  ,PageReport.Pages							AS PagesServed
	  ,LoginReport.Logins						AS Logins
	  ,PageReport.Pages / LoginReport.Logins	AS AvgPagesServed
FROM [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteUsers AS WebSiteUsers
CROSS JOIN (
	SELECT CASE WHEN @Weekly = 1
				THEN FirstDateOfWeek
				ELSE FirstDateOfMonth
				END AS PeriodDate
	FROM [EDISSQL1\SQL1].ServiceLogger.dbo.Calendar AS Calendar
	WHERE 
		(@From IS NULL AND @To IS NULL) 
		OR 
		(Calendar.CalendarDate BETWEEN @From AND @To)
	GROUP BY 
		CASE WHEN @Weekly = 1
			 THEN FirstDateOfWeek
			 ELSE FirstDateOfMonth
			 END
) AS Calendar
LEFT OUTER JOIN (	SELECT CASE WHEN @Weekly = 1
								THEN CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, WebSiteSession.[DateTime]), 0) AS DATE) 
								ELSE CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteSession.[DateTime]), 0) AS DATE)
								END					AS [PeriodCommencing]
						  ,WebSiteUsers.UserID		AS UserID
						  ,WebSiteUsers.UserName	AS UserName
						  ,COUNT(ID)				AS Logins
					FROM [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteSession AS WebSiteSession
					JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteSessionDatabases AS WebSiteSessionDatabases
						ON WebSiteSessionDatabases.SessionID = WebSiteSession.ID
					JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteUsers AS WebSiteUsers
						ON WebSiteUsers.UserID = WebSiteSessionDatabases.UserID
						AND WebSiteUsers.DatabaseID = WebSiteSessionDatabases.DatabaseID
					WHERE
						WebSiteSession.Testing = 0
					AND WebSiteSession.WebSiteID = 1
					AND WebSiteSession.Authenticated = 1
					AND WebSiteSessionDatabases.DatabaseID = @DatabaseID
					AND	((@From IS NULL AND @To IS NULL) OR (WebSiteSession.[DateTime] BETWEEN @From AND @To))
					AND ((@MasterUserType IN (3,4) AND WebSiteSessionDatabases.UserTypeID IN (1, 2, 15))	--CEO/MD
						 OR
						 (@MasterUserType = 15 AND WebSiteSessionDatabases.UserTypeID IN (1, 2))			--ROD
						 OR
						 (@MasterUserType = 1 AND WebSiteSessionDatabases.UserTypeID IN (2))				--RM
						 )
					GROUP BY CASE WHEN @Weekly = 1
								THEN CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, WebSiteSession.[DateTime]), 0) AS DATE) 
								ELSE CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSiteSession.[DateTime]), 0) AS DATE)
								END
							,WebSiteUsers.UserID
							,WebSiteUsers.UserName) AS LoginReport
	ON LoginReport.PeriodCommencing = Calendar.PeriodDate
	AND LoginReport.UserID = WebSiteUsers.UserID
	AND LoginReport.UserName = WebSiteUsers.UserName
LEFT OUTER JOIN (	SELECT CASE WHEN @Weekly = 1
								THEN CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, WebSitePageLogs.[DateTime]), 0) AS DATE) 
								ELSE CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSitePageLogs.[DateTime]), 0) AS DATE)
								END AS [PeriodCommencing]
						  ,WebSiteUsers.UserID
						  ,WebSiteUsers.UserName
						  ,COUNT(*) AS Pages
						  --,MIN(WebSitePageLogs.[DateTime]) AS FirstPageServed
						  --,MAX(WebSitePageLogs.[DateTime]) AS LastPageServed
					FROM [EDISSQL1\SQL1].ServiceLogger.dbo.WebSitePageLogs AS WebSitePageLogs
					LEFT JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.WebSitePages AS WebSitePages
						ON WebSitePages.PageType = WebSitePageLogs.[Type]
					LEFT JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteSession AS WebSiteSession
						ON WebSiteSession.ID = WebSitePageLogs.SessionID
					LEFT JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteSessionDatabases AS WebSiteSessionDatabases
						ON WebSiteSessionDatabases.SessionID = WebSiteSession.ID
					LEFT JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteUsers AS WebSiteUsers
						ON WebSiteUsers.UserID = WebSiteSessionDatabases.UserID
						AND WebSiteUsers.DatabaseID = WebSiteSessionDatabases.DatabaseID
					WHERE
						WebSiteSession.Testing = 0
					AND WebSiteSession.WebSiteID = 1
					AND	WebSitePageLogs.SessionID IS NOT NULL
					AND	WebSitePageLogs.IsPostBack = 0
					AND	WebSitePages.ReportedOn = 1
					AND WebSiteSessionDatabases.DatabaseID = @DatabaseID
					AND	((@From IS NULL AND @To IS NULL) OR (WebSiteSession.[DateTime] BETWEEN @From AND @To))
					AND ((@MasterUserType IN (3,4) AND WebSiteSessionDatabases.UserTypeID IN (1, 2, 15))	--CEO/MD
						 OR
						 (@MasterUserType = 15 AND WebSiteSessionDatabases.UserTypeID IN (1, 2))			--ROD
						 OR
						 (@MasterUserType = 1 AND WebSiteSessionDatabases.UserTypeID IN (2))				--RM
						 )
					GROUP BY CASE WHEN @Weekly = 1
								  THEN CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, WebSitePageLogs.[DateTime]), 0) AS DATE) 
								  ELSE CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, WebSitePageLogs.[DateTime]), 0) AS DATE)
								  END
							,WebSiteUsers.UserID
							,WebSiteUsers.UserName) AS PageReport
	ON PageReport.PeriodCommencing = Calendar.PeriodDate
	AND PageReport.UserID = WebSiteUsers.UserID
	AND PageReport.UserName = WebSiteUsers.UserName
WHERE
	WebSiteUsers.DatabaseID = @DatabaseID
AND ((@MasterUserType IN (3,4) AND WebSiteUsers.UserTypeID IN (1, 2, 15))	--CEO/MD
	 OR
	 (@MasterUserType = 15 AND WebSiteUsers.UserTypeID IN (1, 2))			--ROD
	 OR
	 (@MasterUserType = 1 AND WebSiteUsers.UserTypeID IN (2))				--RM
	 )

AND ((@AllSitesVisible = 1)
		OR
	 WebSiteUsers.UserID IN (	SELECT DISTINCT UserID
								FROM UserSites
								JOIN (	SELECT UserSites.EDISID 
										FROM UserSites
										JOIN Sites ON Sites.EDISID = UserSites.EDISID
										WHERE UserID = @UserID
										AND Sites.Quality = 1
										AND Sites.Hidden = 0) AS MasterUserSites
									ON MasterUserSites.EDISID = UserSites.EDISID))
ORDER BY UserTypeID
		,UserName
		,PeriodCommencing

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserManagementLoginsReport] TO PUBLIC
    AS [dbo];

