CREATE PROCEDURE [dbo].[GetWebUserYieldSubUsers] 

	@UserID	INT,
	@FromMonday	DATETIME,
	@ToMonday	DATETIME,
	@Weekly	BIT = 0,
	@Development BIT = 0

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
	SELECT @UserName AS ReportUser, CAST(UserName AS VARCHAR(255)) AS UserName, ID, CAST(NULL AS INT) AS DatabaseID, CAST(NULL AS INT) AS EDISID, CAST(NULL AS VARCHAR(20)) AS SiteID, CAST(NULL AS VARCHAR(50)) AS Name, CAST(NULL AS VARCHAR(50)) AS Town, CAST(NULL AS VARCHAR(10)) AS PostCode, CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, DispenseDay) + 1, DispenseDay) ELSE DispenseDay END AS Date, CASE SUM(Drinks) WHEN 0 THEN 0 ELSE (SUM(Drinks)/SUM(Quantity)) END AS Yield
	FROM(
		SELECT UserName, Users.ID, Yield.EDISID, DispenseDay, CategoryID, SUM(Drinks) AS Drinks, SUM(Quantity) AS Quantity
		FROM PeriodCacheYield AS Yield
		JOIN UserSites ON Yield.EDISID = UserSites.EDISID
		JOIN Users ON UserID = Users.ID
		JOIN ProductCategories ON ProductCategories.[ID] = Yield.CategoryID
		WHERE  (Yield.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID) OR @AllSites = 1)
		AND ((@UserType = 1 AND Users.UserType = 2) OR (@UserType IN (3,4) AND Users.UserType = 1))
		AND DispenseDay BETWEEN @FromMonday AND @ToMonday
		AND OutsideThreshold = 0
		AND ProductCategories.IncludeInEstateReporting = 1
		GROUP BY Yield.EDISID, UserName, Users.ID, DispenseDay, CategoryID
	) AS Dispense
	GROUP BY UserName, ID, CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, DispenseDay) + 1, DispenseDay) ELSE DispenseDay END
	ORDER BY UserName, CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, DispenseDay) + 1, DispenseDay) ELSE DispenseDay END
	
END
ELSE IF @UserType = 2
BEGIN
	SELECT	@UserName AS ReportUser, 
			CAST(NULL AS VARCHAR(255)) AS UserName, NULL AS ID, 
			CAST(@DatabaseID AS INT) AS DatabaseID, 
			CAST(Dispense.EDISID AS INT) AS EDISID, 
			CAST(Sites.SiteID AS VARCHAR(20)) AS SiteID, 
			Sites.SiteID + ': ' + Sites.Name + ', ' + COALESCE(NULLIF(Sites.Address2,''), NULLIF(Sites.Address3,''), NULLIF(Sites.Address4,''), '') + ', ' + Sites.PostCode AS NAME, 
			COALESCE(NULLIF(Sites.Address2,''), NULLIF(Sites.Address3,''), NULLIF(Sites.Address4,''), '') AS Town, 
			CAST(Sites.PostCode AS VARCHAR(10)) AS PostCode, 
			CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, DispenseDay) + 1, DispenseDay) ELSE DispenseDay END AS Date, 
			CASE SUM(Drinks) WHEN 0 THEN 0 ELSE (SUM(Drinks)/SUM(Quantity)) END AS Yield
	FROM(
		SELECT Yield.EDISID, DispenseDay, CategoryID, SUM(Drinks) AS Drinks, SUM(Quantity) AS Quantity
		FROM PeriodCacheYield AS Yield
		JOIN ProductCategories ON ProductCategories.[ID] = Yield.CategoryID
		WHERE Yield.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID)
		AND DispenseDay BETWEEN @FromMonday AND @ToMonday
		AND OutsideThreshold = 0
		AND ProductCategories.IncludeInEstateReporting = 1
		GROUP BY Yield.EDISID, DispenseDay, CategoryID
	) AS Dispense
	JOIN Sites ON Sites.EDISID = Dispense.EDISID
	GROUP BY Dispense.EDISID, Sites.SiteID, Sites.Name, COALESCE(NULLIF(Sites.Address2,''), NULLIF(Sites.Address3,''), NULLIF(Sites.Address4,''), ''), Sites.PostCode, CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, DispenseDay) + 1, DispenseDay) ELSE DispenseDay END
	ORDER BY Dispense.EDISID, CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, DispenseDay) + 1, DispenseDay) ELSE DispenseDay END
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserYieldSubUsers] TO PUBLIC
    AS [dbo];

