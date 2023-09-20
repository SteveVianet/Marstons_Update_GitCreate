CREATE PROCEDURE [dbo].[GetWebUserCleaningCategories] 

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

SELECT @UserName AS ReportUser, CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, DispenseWeek) + 1, DispenseWeek) ELSE DispenseWeek END AS Date, CategoryID, ProductCategories.Description, SUM(Effectiveness) / COUNT(DispenseWeek) AS Effectiveness
FROM(
	SELECT CategoryID, DispenseWeek, CASE SUM(ActiveLines) WHEN 0 THEN 1 ELSE CAST(SUM(ActiveLinesCleaned) AS FLOAT) / CAST(SUM(ActiveLines) AS FLOAT) END AS Effectiveness
	FROM(
		SELECT EDISID, 
			DispenseWeek, CategoryID,
			SUM(ActiveLines) AS ActiveLines, SUM(ActiveLinesCleaned) AS ActiveLinesCleaned
		FROM PeriodCacheCleaning AS Effectiveness
		JOIN ProductCategories ON Effectiveness.CategoryID = ProductCategories.ID
		WHERE (Effectiveness.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID) OR @AllSites = 1)
		AND DispenseWeek BETWEEN @FromMonday AND @ToMonday
		AND ProductCategories.IncludeInEstateReporting = 1
		GROUP BY EDISID, DispenseWeek, CategoryID
	) AS CategoryCleaning
	GROUP BY CategoryID, DispenseWeek
) AS LineCleaning
JOIN ProductCategories ON ProductCategories.ID = CategoryID
GROUP BY CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, DispenseWeek) + 1, DispenseWeek) ELSE DispenseWeek END, CategoryID, ProductCategories.Description
ORDER BY CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, DispenseWeek) + 1, DispenseWeek) ELSE DispenseWeek END, CategoryID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserCleaningCategories] TO PUBLIC
    AS [dbo];

