CREATE PROCEDURE [dbo].[GetWebUserCleaningDispenseOverall] 

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

SELECT @UserName AS ReportUser, CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, Date) + 1, Date) ELSE Date END AS Date, 
	CASE SUM(TotalDispense) WHEN 0 THEN NULL ELSE SUM(TotalDispense)/8/36 END AS TotalDispenseBarrels,
	CASE SUM(TotalDispense) WHEN 0 THEN NULL ELSE SUM(CleanDispense)/8/36 END AS CleanDispenseBarrels,
	CASE SUM(TotalDispense) WHEN 0 THEN NULL ELSE SUM(DueCleanDispense)/8/36 END AS DueCleanDispenseBarrels,
	CASE SUM(TotalDispense) WHEN 0 THEN NULL ELSE SUM(OverdueCleanDispense)/8/36 END AS OverdueCleanDispenseBarrels,
	CASE SUM(TotalDispense) WHEN 0 THEN NULL ELSE SUM(CleanDispense)/8 END AS CleanDispenseGallons,
	CASE SUM(TotalDispense) WHEN 0 THEN NULL ELSE SUM(DueCleanDispense)/8 END AS DueCleanDispenseGallons,
	CASE SUM(TotalDispense) WHEN 0 THEN NULL ELSE SUM(OverdueCleanDispense)/8 END AS OverdueCleanDispenseGallons,
	CASE SUM(TotalDispense) WHEN 0 THEN NULL ELSE SUM(CleanDispense)/SUM(TotalDispense) END AS PercentageCleanDispense,
	CASE SUM(TotalDispense) WHEN 0 THEN NULL ELSE SUM(DueCleanDispense)/SUM(TotalDispense) END AS PercentageDueCleanDispense,
	CASE SUM(TotalDispense) WHEN 0 THEN NULL ELSE SUM(OverdueCleanDispense)/SUM(TotalDispense) END AS PercentageOverdueCleanDispense
FROM PeriodCacheCleaningDispense AS Dispense
JOIN ProductCategories ON Dispense.CategoryID = ProductCategories.ID
WHERE (Dispense.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID) OR @AllSites = 1)
AND Date BETWEEN @FromMonday AND @ToMonday
AND ProductCategories.IncludeInEstateReporting = 1
GROUP BY CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, Date) + 1, Date) ELSE Date END
ORDER BY CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, Date) + 1, Date) ELSE Date END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserCleaningDispenseOverall] TO PUBLIC
    AS [dbo];

