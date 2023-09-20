CREATE PROCEDURE [dbo].[GetWebUserTenantLoginsReport]
(
    @UserID INT,
	@From DATE,
	@To DATE,
	@LimitSubUserID INT = NULL
)

AS

--DECLARE	@From DATE  = '2012-07-01'
--DECLARE	@To DATE    = '2012-07-22'
--DECLARE	@UserID INT = 55

DECLARE @DatabaseID INT

SELECT @DatabaseID = ID 
FROM [EDISSQL1\SQL1].ServiceLogger.dbo.EDISDatabases
WHERE Name = DB_NAME()

SET NOCOUNT ON

-- Get the Current User's Type
DECLARE @MasterUserType	INT
IF @UserID IS NOT NULL AND @DatabaseID IS NOT NULL
BEGIN
	SELECT @MasterUserType = WebSiteUsers.UserTypeID
	FROM [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteUsers AS WebSiteUsers
	WHERE
		WebSiteUsers.DatabaseID = @DatabaseID
	AND WebSiteUsers.UserID = @UserID
END

-- Get the LimitTo User's Type
DECLARE @LimitSubUserType	INT
IF @LimitSubUserID IS NOT NULL AND @DatabaseID IS NOT NULL
BEGIN
	SELECT @LimitSubUserType = WebSiteUsers.UserTypeID
	FROM [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteUsers AS WebSiteUsers
	WHERE
		WebSiteUsers.DatabaseID = @DatabaseID
	AND WebSiteUsers.UserID = @LimitSubUserID
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

DECLARE @RelevantSites TABLE (EDISID INT NOT NULL PRIMARY KEY)

IF @LimitSubUserID IS NOT NULL
BEGIN
    INSERT INTO @RelevantSites (EDISID)
    EXEC GetSubUserSites @LimitSubUserID
END
ELSE
BEGIN
    INSERT INTO @RelevantSites (EDISID)
    EXEC GetSubUserSites @UserID
END

--PubCo
SELECT SiteStats.PeriodCommencing   AS PeriodCommencing
      ,WebSiteUsers.UserType        AS UserType
      ,WebSiteUsers.UserTypeID      AS UserTypeID
      ,WebSiteUsers.UserID          AS UserID
      ,WebSiteUsers.UserName        AS UserName
      ,UserSites.EDISID             AS EDISID
      ,SiteStats.SiteID             AS SiteID
      ,SiteStats.SiteName           AS SiteName
      ,SiteStats.SiteViewed         AS SiteHasBeenViewed
      ,SiteStats.PagesServed        AS PagesServed
      ,SiteStats.Logins             AS Logins
      ,SiteStats.AvgPagesServed     AS AvgPagesServed
      ,WebSiteUsers.iDraughtSites   AS iDraughtSiteCount
      ,WebSiteUsers.BMSSites        AS BMSSiteCount
FROM [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteUsers AS WebSiteUsers
JOIN UserSites
    ON UserSites.UserID = WebSiteUsers.UserID
JOIN (  SELECT Calendar.PeriodDate                      AS PeriodCommencing
              ,Sites.EDISID                             AS EDISID
              ,Sites.SiteID                             AS SiteID
              ,Sites.Name                               AS SiteName
              ,PageReport.Pages                         AS PagesServed
              ,CASE WHEN SUM(LoginReport.TimesViewed) > 0 
                    THEN 1 
                    ELSE 0 
                    END                                 AS SiteViewed
              ,ISNULL(SUM(LoginReport.TimesViewed),0)   AS Logins
              ,PageReport.Pages / ISNULL(SUM(LoginReport.TimesViewed),0)    AS AvgPagesServed
        FROM Sites
        CROSS JOIN (
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
        LEFT JOIN @RelevantSites AS UserSites
            ON UserSites.EDISID = Sites.EDISID
        LEFT OUTER JOIN (   SELECT  CASE WHEN @Weekly = 1
                                         THEN Calendar.FirstDateOfWeek
                                         ELSE Calendar.FirstDateOfMonth
                                         END AS [PeriodCommencing]
                                   ,WebSiteSessionSites.EDISID AS EDISID
                                   ,COUNT(WebSiteSessionSites.SessionID) AS TimesViewed
                            FROM [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteSessionSites AS WebSiteSessionSites
                            JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteSession AS WebSiteSession
                                ON WebSiteSession.ID = WebSiteSessionSites.SessionID
                            JOIN Calendar
                                ON Calendar.CalendarDate = WebSiteSession.[Date]
                            JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteSessionDatabases AS WebSiteSessionDatabases
                                ON WebSiteSessionDatabases.SessionID = WebSiteSession.ID
                            WHERE
                                WebSiteSession.Testing = 0
                            AND WebSiteSession.WebSiteID = 1
                            AND WebSiteSession.ID IS NOT NULL
                            AND WebSiteSession.[Date] BETWEEN @From AND @To
                            AND WebSiteSessionSites.DatabaseID = @DatabaseID
                            AND WebSiteSessionDatabases.UserTypeID In (5,6)
                            GROUP BY CASE WHEN @Weekly = 1
                                         THEN Calendar.FirstDateOfWeek
                                         ELSE Calendar.FirstDateOfMonth
                                         END
                                    ,WebSiteSessionSites.EDISID) AS LoginReport
            ON LoginReport.PeriodCommencing = Calendar.PeriodDate
            AND LoginReport.EDISID = UserSites.EDISID
        LEFT OUTER JOIN (   SELECT  CASE WHEN @Weekly = 1
                                         THEN Calendar.FirstDateOfWeek
                                         ELSE Calendar.FirstDateOfMonth
                                         END AS [PeriodCommencing]
                                   ,WebSiteSessionSites.EDISID AS EDISID
                                   ,COUNT(*) AS Pages
                            FROM [EDISSQL1\SQL1].ServiceLogger.dbo.WebSitePageLogs AS WebSitePageLogs
                            LEFT JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.WebSitePages AS WebSitePages
                                ON WebSitePages.PageType = WebSitePageLogs.[Type]
                            LEFT JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteSessionSites AS WebSiteSessionSites
                                ON WebSiteSessionSites.SessionID = WebSitePageLogs.SessionID
                            LEFT JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteSession AS WebSiteSession
                                ON WebSiteSession.ID = WebSiteSessionSites.SessionID
                            LEFT JOIN Calendar
                                ON Calendar.CalendarDate = WebSiteSession.[Date]
                            JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteSessionDatabases AS WebSiteSessionDatabases
                                ON WebSiteSessionDatabases.SessionID = WebSiteSession.ID
                            WHERE
                                WebSiteSession.Testing = 0
                            AND WebSiteSession.WebSiteID = 1
                            AND WebSiteSession.ID IS NOT NULL
                            AND WebSitePageLogs.IsPostBack = 0
                            AND WebSitePages.ReportedOn = 1
                            AND WebSiteSession.[Date] BETWEEN @From AND @To
                            AND WebSiteSessionSites.DatabaseID = @DatabaseID
                            AND WebSiteSessionDatabases.UserTypeID In (5,6)
                            GROUP BY CASE WHEN @Weekly = 1
                                         THEN Calendar.FirstDateOfWeek
                                         ELSE Calendar.FirstDateOfMonth
                                         END
                                    ,WebSiteSessionSites.EDISID) AS PageReport
            ON PageReport.PeriodCommencing = Calendar.PeriodDate
            AND PageReport.EDISID = UserSites.EDISID
        WHERE
            ((@AllSitesVisible = 1)
                OR
             (@AllSitesVisible = 0 AND UserSites.EDISID IS NOT NULL))
        AND 
            Sites.Hidden = 0
        AND
            Sites.Quality = 1
        GROUP BY Calendar.PeriodDate
                ,Sites.EDISID
                ,Sites.SiteID
                ,Sites.Name
                ,PageReport.Pages) AS SiteStats
    ON SiteStats.EDISID = UserSites.EDISID
WHERE
	WebSiteUsers.DatabaseID = @DatabaseID
AND ((@MasterUserType IN (3,4) AND @LimitSubUserType IS NULL AND WebSiteUsers.UserTypeID IN (1, 2, 15))	--CEO/MD
	 OR
	 (@MasterUserType = 15 AND @LimitSubUserType IS NULL AND WebSiteUsers.UserTypeID IN (1, 2))			--ROD
	 OR
	 (@MasterUserType = 1 AND @LimitSubUserType IS NULL AND WebSiteUsers.UserTypeID IN (2))				--RM
	 )
AND ((@AllSitesVisible = 1)
		OR
	 WebSiteUsers.UserID IN (	SELECT DISTINCT UserID
								FROM UserSites
								JOIN (	SELECT UserSites.EDISID 
										FROM UserSites
										JOIN Sites ON Sites.EDISID = UserSites.EDISID
										WHERE ((@LimitSubUserID IS NULL AND UserID = @UserID)
                                                OR
                                               (UserID = @LimitSubUserID))
										AND Sites.Quality = 1
										AND Sites.Hidden = 0) AS MasterUserSites
									ON MasterUserSites.EDISID = UserSites.EDISID))
ORDER BY UserType, UserName, SiteName, PeriodCommencing

--Sites
SELECT Calendar.PeriodDate                      AS PeriodCommencing
      ,Sites.EDISID                             AS EDISID
      ,Sites.SiteID                             AS SiteID
      ,Sites.Name                               AS SiteName
      ,PageReport.Pages                         AS PagesServed
      ,CASE WHEN SUM(LoginReport.TimesViewed) > 0 
            THEN 1 
            ELSE 0 
            END                                 AS SiteViewed
      ,ISNULL(SUM(LoginReport.TimesViewed),0)   AS Logins
      ,PageReport.Pages / ISNULL(SUM(LoginReport.TimesViewed),0)    AS AvgPagesServed
FROM Sites
CROSS JOIN (
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
/*
LEFT JOIN UserSites 
    ON UserSites.EDISID = Sites.EDISID 
    AND ((@LimitSubUserID IS NULL AND UserSites.UserID = @UserID)
            OR
        (@LimitSubUserID IS NOT NULL AND UserSites.UserID = @LimitSubUserID))
*/
LEFT JOIN @RelevantSites AS UserSites ON UserSites.EDISID = Sites.EDISID 
LEFT OUTER JOIN (   SELECT  CASE WHEN @Weekly = 1
                                 THEN Calendar.FirstDateOfWeek
                                 ELSE Calendar.FirstDateOfMonth
                                 END AS [PeriodCommencing]
                           ,WebSiteSessionSites.EDISID AS EDISID
                           ,COUNT(WebSiteSessionSites.SessionID) AS TimesViewed
                    FROM [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteSessionSites AS WebSiteSessionSites WITH (NOLOCK)
                    JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteSession AS WebSiteSession
                        ON WebSiteSession.ID = WebSiteSessionSites.SessionID
                    JOIN Calendar 
                        ON Calendar.CalendarDate = WebSiteSession.[Date]
                    JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteSessionDatabases AS WebSiteSessionDatabases
                        ON WebSiteSessionDatabases.SessionID = WebSiteSession.ID
                    WHERE
                        WebSiteSession.Testing = 0
                    AND WebSiteSession.WebSiteID = 1
                    AND WebSiteSession.ID IS NOT NULL
                    AND WebSiteSession.[Date] BETWEEN @From AND @To
                    AND WebSiteSessionSites.DatabaseID = @DatabaseID
                    AND WebSiteSessionDatabases.UserTypeID In (5,6)
                    GROUP BY CASE WHEN @Weekly = 1
                                 THEN Calendar.FirstDateOfWeek
                                 ELSE Calendar.FirstDateOfMonth
                                 END
                            ,WebSiteSessionSites.EDISID) AS LoginReport
    ON LoginReport.PeriodCommencing = Calendar.PeriodDate
    AND LoginReport.EDISID = UserSites.EDISID
LEFT OUTER JOIN (   SELECT  CASE WHEN @Weekly = 1
                                 THEN Calendar.FirstDateOfWeek
                                 ELSE Calendar.FirstDateOfMonth
                                 END AS [PeriodCommencing]
                           ,WebSiteSessionSites.EDISID AS EDISID
                           ,COUNT(*) AS Pages
                    FROM [EDISSQL1\SQL1].ServiceLogger.dbo.WebSitePageLogs AS WebSitePageLogs
                    LEFT JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.WebSitePages AS WebSitePages
                        ON WebSitePages.PageType = WebSitePageLogs.[Type]
                    LEFT JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteSessionSites AS WebSiteSessionSites WITH (NOLOCK)
                        ON WebSiteSessionSites.SessionID = WebSitePageLogs.SessionID
                    LEFT JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteSession AS WebSiteSession
                        ON WebSiteSession.ID = WebSiteSessionSites.SessionID
                    LEFT JOIN Calendar 
                        ON Calendar.CalendarDate = WebSiteSession.[Date]
                    JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteSessionDatabases AS WebSiteSessionDatabases
                        ON WebSiteSessionDatabases.SessionID = WebSiteSession.ID
                    WHERE
                        WebSiteSession.Testing = 0
                    AND WebSiteSession.WebSiteID = 1
                    AND WebSiteSession.ID IS NOT NULL
                    AND WebSitePageLogs.IsPostBack = 0
                    AND WebSitePages.ReportedOn = 1
                    AND WebSiteSession.[Date] BETWEEN @From AND @To
                    AND WebSiteSessionSites.DatabaseID = @DatabaseID
                    AND WebSiteSessionDatabases.UserTypeID In (5,6)
                    GROUP BY CASE WHEN @Weekly = 1
                                 THEN Calendar.FirstDateOfWeek
                                 ELSE Calendar.FirstDateOfMonth
                                 END
                            ,WebSiteSessionSites.EDISID) AS PageReport
    ON PageReport.PeriodCommencing = Calendar.PeriodDate
    AND PageReport.EDISID = UserSites.EDISID
WHERE
    ((@AllSitesVisible = 1)
        OR
     (@AllSitesVisible = 0 AND UserSites.EDISID IS NOT NULL))
AND 
    Sites.Hidden = 0
AND
    Sites.Quality = 1
GROUP BY Calendar.PeriodDate
        ,Sites.EDISID
        ,Sites.SiteID
        ,Sites.Name
        ,PageReport.Pages


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserTenantLoginsReport] TO PUBLIC
    AS [dbo];

