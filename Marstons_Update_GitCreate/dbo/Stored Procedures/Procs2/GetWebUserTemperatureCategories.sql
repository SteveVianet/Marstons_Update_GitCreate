CREATE PROCEDURE [dbo].[GetWebUserTemperatureCategories] 

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




SELECT @UserName AS ReportUser, CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, Date) + 1, Date) ELSE Date END AS Date, CategoryID, ProductCategories.Description,
	CASE SUM(TotalDispense) WHEN 0 THEN NULL ELSE SUM(TotalDispense)/8/36 END AS TotalDispenseBarrels,
	CASE SUM(TotalDispense) WHEN 0 THEN NULL ELSE SUM(InSpec)/8/36 END AS InSpecBarrels,
	CASE SUM(TotalDispense) WHEN 0 THEN NULL ELSE SUM(InTolerance)/8/36 END AS InToleranceBarrels,
	CASE SUM(TotalDispense) WHEN 0 THEN NULL ELSE SUM(OutSpec)/8/36 END AS OutSpecBarrels,
	CASE SUM(TotalDispense) WHEN 0 THEN NULL ELSE SUM(InSpec)/8 END AS InSpecGallons,
	CASE SUM(TotalDispense) WHEN 0 THEN NULL ELSE SUM(InTolerance)/8 END AS InToleranceGallons,
	CASE SUM(TotalDispense) WHEN 0 THEN NULL ELSE SUM(OutSpec)/8 END AS OutSpecGallons,
	CASE SUM(TotalDispense) WHEN 0 THEN NULL ELSE SUM(InSpec)/SUM(TotalDispense) END AS PercentageInSpec,
	CASE SUM(TotalDispense) WHEN 0 THEN NULL ELSE SUM(InTolerance)/SUM(TotalDispense) END AS PercentageInTolerance,
	CASE SUM(TotalDispense) WHEN 0 THEN NULL ELSE SUM(OutSpec)/SUM(TotalDispense) END AS PercentageOutSpec
FROM PeriodCacheTemperature AS Dispense
JOIN ProductCategories ON ProductCategories.ID = CategoryID
WHERE (Dispense.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID) OR @AllSites = 1)
AND Date BETWEEN @FromMonday AND @ToMonday
AND ProductCategories.IncludeInEstateReporting = 1
GROUP BY CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, Date) + 1, Date) ELSE Date END, CategoryID, ProductCategories.Description
ORDER BY CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, Date) + 1, Date) ELSE Date END, CategoryID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserTemperatureCategories] TO PUBLIC
    AS [dbo];

