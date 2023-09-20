CREATE PROCEDURE [dbo].[GetWebUserCleaningOverall] 

	@UserID 	INT,
	@FromMonday 	DATETIME,
	@ToMonday	DATETIME,
	@Weekly	BIT = 0,
	@Development BIT = 0

AS

SET NOCOUNT ON
DECLARE @AllSites AS BIT
DECLARE @UserName AS VARCHAR(250)
SELECT @AllSites = AllSitesVisible, @UserName = UserName FROM Users JOIN UserTypes ON UserTypes.ID = UserType WHERE Users.ID = @UserID

SELECT @UserName AS ReportUser, CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, DispenseWeek) + 1, DispenseWeek) ELSE DispenseWeek END AS Date, SUM(Effectiveness) / COUNT(DispenseWeek) AS Effectiveness
FROM(
	SELECT DispenseWeek, CASE SUM(ActiveLines) WHEN 0 THEN 1 ELSE CAST(SUM(ActiveLinesCleaned) AS FLOAT) / CAST(SUM(ActiveLines) AS FLOAT) END AS Effectiveness
	FROM(
		SELECT EDISID, 
			DispenseWeek, CategoryID,
			SUM(ActiveLines) AS ActiveLines, SUM(ActiveLinesCleaned) AS ActiveLinesCleaned
			--CASE SUM(ActiveLines) WHEN 0 THEN 1 ELSE CAST(SUM(ActiveLinesCleaned) AS FLOAT) / CAST(SUM(ActiveLines) AS FLOAT) END AS Effectiveness
		FROM PeriodCacheCleaning AS Effectiveness
		JOIN ProductCategories ON Effectiveness.CategoryID = ProductCategories.ID
		WHERE (Effectiveness.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID) OR @AllSites = 1)
		AND DispenseWeek BETWEEN @FromMonday AND @ToMonday
		AND ProductCategories.IncludeInEstateReporting = 1
		GROUP BY EDISID, DispenseWeek, CategoryID
	) AS SiteCleaning
	GROUP BY DispenseWeek
) AS LineCleaning
GROUP BY CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, DispenseWeek) + 1, DispenseWeek) ELSE DispenseWeek END
ORDER BY CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, DispenseWeek) + 1, DispenseWeek) ELSE DispenseWeek END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserCleaningOverall] TO PUBLIC
    AS [dbo];

