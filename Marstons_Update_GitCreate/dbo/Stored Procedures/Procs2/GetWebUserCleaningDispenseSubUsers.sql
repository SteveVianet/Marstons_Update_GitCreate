

CREATE PROCEDURE [dbo].[GetWebUserCleaningDispenseSubUsers] 
(
	@UserID	INT,
	@FromMonday	DATETIME,
	@ToMonday	DATETIME,
	@Weekly	BIT = 0
)
AS

SET NOCOUNT ON

DECLARE @AllSites AS BIT
DECLARE @UserName AS VARCHAR(250)
SELECT @AllSites = AllSitesVisible, @UserName = UserName FROM Users JOIN UserTypes ON UserTypes.ID = UserType WHERE Users.ID = @UserID

DECLARE @DatabaseID AS INT
SELECT @DatabaseID = CAST(PropertyValue AS INT) FROM Configuration WHERE PropertyName = 'Service Owner ID'

DECLARE @UserType AS INT
SELECT @UserType = UserType FROM Users WHERE ID = @UserID

IF @UserType IN (1,3,4)
BEGIN
	SELECT @UserName AS ReportUser, CAST(UserName AS VARCHAR(255)) AS UserName, Users.ID, CAST(NULL AS INT) AS DatabaseID, CAST(NULL AS INT) AS EDISID, CAST(NULL AS VARCHAR(20)) AS SiteID, CAST(NULL AS VARCHAR(50)) AS Name, CAST(NULL AS VARCHAR(50)) AS Town, CAST(NULL AS VARCHAR(10)) AS PostCode, 
	CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, Date) + 1, Date) ELSE Date END AS Date, 
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
	JOIN UserSites ON Dispense.EDISID = UserSites.EDISID
	JOIN Users ON UserID = Users.ID
	JOIN ProductCategories ON Dispense.CategoryID = ProductCategories.ID
	WHERE (Dispense.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID) OR @AllSites = 1)
	AND Date BETWEEN @FromMonday AND @ToMonday
	AND ((@UserType = 1 AND Users.UserType = 2) OR (@UserType IN (3,4) AND Users.UserType = 1))
	AND ProductCategories.IncludeInEstateReporting = 1
	GROUP BY UserName, Users.ID, CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, Date) + 1, Date) ELSE Date END
	ORDER BY UserName, CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, Date) + 1, Date) ELSE Date END
	
END
ELSE IF @UserType = 2
BEGIN
	SELECT	@UserName AS ReportUser, 
			CAST(NULL AS VARCHAR(255)) AS UserName, 
			NULL AS ID, 
			CAST(@DatabaseID AS INT) AS DatabaseID, 
			CAST(Dispense.EDISID AS INT) AS EDISID, 
			CAST(Sites.SiteID AS VARCHAR(20)) AS SiteID, 
			Sites.SiteID + ': ' + Sites.Name + ', ' + COALESCE(NULLIF(Sites.Address2,''), NULLIF(Sites.Address3,''), NULLIF(Sites.Address4,''), '') + ', ' + Sites.PostCode AS NAME, 
			COALESCE(NULLIF(Sites.Address2,''), NULLIF(Sites.Address3,''), NULLIF(Sites.Address4,''), '') AS Town, 
			CAST(Sites.PostCode AS VARCHAR(10)) AS PostCode, 
	CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, Date) + 1, Date) ELSE Date END AS Date, 
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
	JOIN Sites ON Sites.EDISID = Dispense.EDISID
	JOIN ProductCategories ON Dispense.CategoryID = ProductCategories.ID
	WHERE Dispense.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID)
	AND Date BETWEEN @FromMonday AND @ToMonday
	AND ProductCategories.IncludeInEstateReporting = 1
	GROUP BY Dispense.EDISID, Sites.SiteID, Sites.Name, COALESCE(NULLIF(Sites.Address2,''), NULLIF(Sites.Address3,''), NULLIF(Sites.Address4,''), ''), Sites.PostCode, CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, Date) + 1, Date) ELSE Date END
	ORDER BY Dispense.EDISID, CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, Date) + 1, Date) ELSE Date END
END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserCleaningDispenseSubUsers] TO PUBLIC
    AS [dbo];

