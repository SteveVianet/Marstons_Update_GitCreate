CREATE PROCEDURE [dbo].[GetWebUserCleaningSubUsers] 

	@UserID	INT,
	@FromMonday	DATETIME,
	@ToMonday	DATETIME,
	@Weekly	BIT = 0,
	@Development BIT = 0

AS

SET NOCOUNT ON

DECLARE @UserType AS INT
SELECT @UserType = UserType FROM Users WHERE ID = @UserID

DECLARE @DatabaseID AS INT
SELECT @DatabaseID = CAST(PropertyValue AS INT) FROM Configuration WHERE PropertyName = 'Service Owner ID'

DECLARE @AllSites AS BIT
DECLARE @UserName AS VARCHAR(250)
SELECT @AllSites = AllSitesVisible, @UserName = UserName FROM Users JOIN UserTypes ON UserTypes.ID = UserType WHERE Users.ID = @UserID

IF @UserType IN (1,3,4)
BEGIN
	SELECT @UserName AS ReportUser, CAST(UserName AS VARCHAR(255)) AS UserName, ID, CAST(NULL AS INT) AS DatabaseID, CAST(NULL AS INT) AS EDISID, CAST(NULL AS VARCHAR(20)) AS SiteID, CAST(NULL AS VARCHAR(50)) AS Name, CAST(NULL AS VARCHAR(50)) AS Town, CAST(NULL AS VARCHAR(10)) AS PostCode, CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, DispenseWeek) + 1, DispenseWeek) ELSE DispenseWeek END AS Date, SUM(ActiveLines) AS ActiveLines, SUM(ActiveLinesCleaned) AS ActiveLinesCleaned, SUM(Effectiveness) / COUNT(DispenseWeek) AS Effectiveness
	FROM (
		SELECT UserName, UserID AS ID, DispenseWeek, SUM(ActiveLines) AS ActiveLines, SUM(ActiveLinesCleaned) AS ActiveLinesCleaned, CASE SUM(ActiveLines) WHEN 0 THEN 1 ELSE CAST(SUM(ActiveLinesCleaned) AS FLOAT) / CAST(SUM(ActiveLines) AS FLOAT) END AS Effectiveness
		FROM(
			SELECT UserName, Users.ID AS UserID, Effectiveness.EDISID, 
				DispenseWeek,
				SUM(ActiveLines) AS ActiveLines, SUM(ActiveLinesCleaned) AS ActiveLinesCleaned
			FROM PeriodCacheCleaning AS Effectiveness
			JOIN ProductCategories ON Effectiveness.CategoryID = ProductCategories.ID
			JOIN UserSites ON Effectiveness.EDISID = UserSites.EDISID
			JOIN Users ON UserID = Users.ID
			WHERE  (Effectiveness.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID) OR @AllSites = 1)
			AND ((@UserType = 1 AND Users.UserType = 2) OR (@UserType IN (3,4) AND Users.UserType = 1))
			AND DispenseWeek BETWEEN @FromMonday AND @ToMonday
			AND ProductCategories.IncludeInEstateReporting = 1
			GROUP BY Effectiveness.EDISID, UserName, Users.ID, DispenseWeek
		) AS SiteCleaning
		GROUP BY UserName, UserID, DispenseWeek
	) AS LineCleaning
	GROUP BY UserName, ID, CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, DispenseWeek) + 1, DispenseWeek) ELSE DispenseWeek END
	ORDER BY UserName, CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, DispenseWeek) + 1, DispenseWeek) ELSE DispenseWeek END

	
END
ELSE IF @UserType = 2
BEGIN
	SELECT	@UserName AS ReportUser, 
			CAST(NULL AS VARCHAR(255)) AS UserName, 
			NULL AS ID, 
			CAST(@DatabaseID AS INT) AS DatabaseID, 
			CAST(LineCleaning.EDISID AS INT) AS EDISID, 
			CAST(Sites.SiteID AS VARCHAR(20)) AS SiteID, 
			Sites.SiteID + ': ' + Sites.Name + ', ' + COALESCE(NULLIF(Sites.Address2,''), NULLIF(Sites.Address3,''), NULLIF(Sites.Address4,''), '') + ', ' + Sites.PostCode AS NAME, 
			COALESCE(NULLIF(Sites.Address2,''), NULLIF(Sites.Address3,''), NULLIF(Sites.Address4,''), '') AS Town, 
			CAST(Sites.PostCode AS VARCHAR(10)) AS PostCode, 
			CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, DispenseWeek) + 1, DispenseWeek) ELSE DispenseWeek END AS Date, 
			SUM(Effectiveness) / COUNT(DispenseWeek) AS Effectiveness
	FROM (
		SELECT EDISID, DispenseWeek, SUM(ActiveLines) AS ActiveLines, SUM(ActiveLinesCleaned) AS ActiveLinesCleaned, CASE SUM(ActiveLines) WHEN 0 THEN 1 ELSE CAST(SUM(ActiveLinesCleaned) AS FLOAT) / CAST(SUM(ActiveLines) AS FLOAT) END AS Effectiveness
		FROM(
			SELECT Effectiveness.EDISID, 
				DispenseWeek, CategoryID,
				SUM(ActiveLines) AS ActiveLines, SUM(ActiveLinesCleaned) AS ActiveLinesCleaned
				--CASE SUM(ActiveLines) WHEN 0 THEN 1 ELSE CAST(SUM(ActiveLinesCleaned) AS FLOAT) / CAST(SUM(ActiveLines) AS FLOAT) END AS Effectiveness
			FROM PeriodCacheCleaning AS Effectiveness
			JOIN ProductCategories ON Effectiveness.CategoryID = ProductCategories.ID
			WHERE Effectiveness.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID)
			AND DispenseWeek BETWEEN @FromMonday AND @ToMonday
			AND ProductCategories.IncludeInEstateReporting = 1
			GROUP BY Effectiveness.EDISID, DispenseWeek, CategoryID
		) AS SiteCleaning
		GROUP BY EDISID, DispenseWeek
	) AS LineCleaning
	JOIN Sites ON Sites.EDISID = LineCleaning.EDISID
	GROUP BY LineCleaning.EDISID, Sites.SiteID, Sites.Name, COALESCE(NULLIF(Sites.Address2,''), NULLIF(Sites.Address3,''), NULLIF(Sites.Address4,''), ''), Sites.PostCode, CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, DispenseWeek) + 1, DispenseWeek) ELSE DispenseWeek END
	ORDER BY LineCleaning.EDISID, CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, DispenseWeek) + 1, DispenseWeek) ELSE DispenseWeek END
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserCleaningSubUsers] TO PUBLIC
    AS [dbo];

