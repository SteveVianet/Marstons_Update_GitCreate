CREATE PROCEDURE [dbo].[GetWebUserYieldCategories] 

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

SELECT 
	@UserName AS ReportUser, 
	CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, DispenseDay) + 1, DispenseDay) ELSE DispenseDay END AS Date, 
	CategoryID, 
	CategoryDescription as Description, 
	CASE SUM(Drinks) WHEN 0 THEN 0 ELSE (SUM(Drinks)/SUM(Quantity)) END AS Yield,
	SUM(Drinks) AS Drinks
FROM (
	SELECT Yield.EDISID, DispenseDay, CategoryID, ProductCategories.[Description] AS CategoryDescription, SUM(Drinks) AS Drinks, SUM(Quantity) AS Quantity
	FROM PeriodCacheYield AS Yield
	JOIN ProductCategories ON ProductCategories.[ID] = Yield.CategoryID
	WHERE (Yield.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID) OR @AllSites = 1)
	AND DispenseDay BETWEEN @FromMonday AND @ToMonday
	AND OutsideThreshold = 0
	AND ProductCategories.IncludeInEstateReporting = 1
	GROUP BY EDISID, DispenseDay, CategoryID, ProductCategories.[Description]
) AS Dispense
GROUP BY CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, DispenseDay) + 1, DispenseDay) ELSE DispenseDay END, CategoryID, CategoryDescription
ORDER BY CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, DispenseDay) + 1, DispenseDay) ELSE DispenseDay END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserYieldCategories] TO PUBLIC
    AS [dbo];

