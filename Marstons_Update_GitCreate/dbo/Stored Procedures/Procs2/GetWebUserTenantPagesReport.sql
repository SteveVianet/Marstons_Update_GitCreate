CREATE PROCEDURE [dbo].[GetWebUserTenantPagesReport]
(
	@UserID INT,
	@From DATE,
	@To DATE
)
AS

SET NOCOUNT ON

DECLARE @DatabaseID INT

SELECT @DatabaseID = ID 
FROM [EDISSQL1\SQL1].ServiceLogger.dbo.EDISDatabases
WHERE Name = DB_NAME()

--EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.[GetWebStatisticsTenantPagesReport] @DatabaseID, @UserID, @From, @To

-- Get the Current Users Type
DECLARE @MasterUserType	INT
IF @UserID IS NOT NULL AND @DatabaseID IS NOT NULL
BEGIN
	SELECT @MasterUserType = WebSiteUsers.UserTypeID
	FROM [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteUsers
	WHERE
		WebSiteUsers.DatabaseID = @DatabaseID
	AND WebSiteUsers.UserID = @UserID
END

-- Pull the From date forwards if it goes back before the logs were 'trustworthy'
DECLARE @StartLimit DATE = '2011-06-06'
IF @StartLimit > @From
BEGIN
	SET @From = @StartLimit
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

CREATE TABLE #PageLogs (SessionID INT, [DateTime] DATETIME, PageType VARCHAR(256), [Description] VARCHAR(256))

INSERT INTO #PageLogs
SELECT	WebSitePageLogs.SessionID,
		WebSitePageLogs.[DateTime],
		WebSitePages.PageType,
		WebSitePages.[Description]
FROM [EDISSQL1\SQL1].ServiceLogger.dbo.WebSitePages
LEFT JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.WebSitePageLogs
	ON	WebSitePageLogs.[Type] = WebSitePages.PageType
LEFT JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteSession
	ON	WebSiteSession.ID = WebSitePageLogs.SessionID
LEFT JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteSessionDatabases
	ON	WebSiteSessionDatabases.SessionID = WebSiteSession.ID
LEFT JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteSessionSites
    ON WebSiteSessionSites.SessionID = WebSiteSession.ID
WHERE WebSitePageLogs.DatabaseID = @DatabaseID
AND	WebSiteSession.Testing = 0
AND WebSiteSession.WebSiteID = 1
AND	WebSitePageLogs.IsPostBack = 0
AND	WebSitePages.ReportedOn = 1 --This overrides any user type enablers
AND WebSitePages.ReportedOnTenant = 1 --This enables pages for tenant-report viewing
AND WebSitePages.WebSiteID = 1
AND	((@From IS NULL AND @To IS NULL) OR (WebSiteSession.[DateTime] BETWEEN @From AND @To))
AND WebSiteSessionDatabases.UserTypeID IN (5, 6)
AND WebSiteSessionSites.EDISID IN (    SELECT DISTINCT EDISID 
										FROM UserSites
										WHERE ((UserID =  @UserID)
												OR
												(@AllSitesVisible = 1))
                )

CREATE TABLE #PageReport (PeriodCommencing DATE, Page VARCHAR(256), TimesAccessed INT, UNIQUE(PeriodCommencing, Page))

INSERT INTO #PageReport
SELECT Calendar.PeriodDate			AS PeriodCommencing
	  ,PageLogs.[Description]	AS Page
	  ,SUM(Pages.TotalPages)		AS TimesAccessed
FROM [EDISSQL1\SQL1].ServiceLogger.dbo.WebSitePages AS PageLogs
CROSS JOIN 
(
	SELECT CASE WHEN @Weekly = 1
				THEN FirstDateOfWeek
				ELSE FirstDateOfMonth
				END AS PeriodDate
	FROM Calendar
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
								THEN CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, PageLogs.[DateTime]), 0) AS DATE) 
								ELSE CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, PageLogs.[DateTime]), 0) AS DATE)
								END AS [PeriodCommencing]
						  ,PageLogs.PageType		AS Page
						  ,[Description]
						  ,COUNT(*)						AS TotalPages
					FROM #PageLogs AS PageLogs
					GROUP BY CASE WHEN @Weekly = 1
								  THEN CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, PageLogs.[DateTime]), 0) AS DATE) 
								  ELSE CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, PageLogs.[DateTime]), 0) AS DATE)
								  END
							,PageLogs.PageType
							,[Description]) AS Pages
	ON Pages.Page = PageLogs.PageType
	AND Pages.PeriodCommencing = Calendar.PeriodDate
WHERE 
    PageLogs.ReportedOn = 1 --This overrides any user type enablers
AND PageLogs.ReportedOnTenant = 1 --This enables pages for tenant-report viewing
AND PageLogs.WebSiteID = 1
GROUP BY Calendar.PeriodDate
		,PageLogs.[Description]

SELECT PageReport.PeriodCommencing
	  ,Page
	  ,ISNULL(TimesAccessed, 0) AS TimesAccessed
	  ,ISNULL(TotalAccesses, 0) AS PeriodAccesses
	  ,ISNULL(ISNULL(TimesAccessed, 0) / CAST(TotalAccesses AS FLOAT), 0) AS PeriodPercentage
FROM #PageReport AS PageReport
JOIN (	SELECT PeriodCommencing
			  ,SUM(TimesAccessed) AS TotalAccesses
		FROM #PageReport
		GROUP BY PeriodCommencing) AS MonthlyTotals
	ON MonthlyTotals.PeriodCommencing = PageReport.PeriodCommencing
ORDER BY Page
		,PageReport.PeriodCommencing

DROP TABLE #PageReport
DROP TABLE #PageLogs

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserTenantPagesReport] TO PUBLIC
    AS [dbo];

