CREATE PROCEDURE [dbo].[GetWebUserTillYieldSubUsers2] 
(
	@UserID	INT,
	@FromMonday	DATE,
	@ToMonday	DATE,
	@Weekly	BIT = 0
)
AS

SET NOCOUNT ON
SET DATEFIRST 1

DECLARE @AllSites AS BIT
DECLARE @CashValue AS FLOAT
DECLARE @DatabaseID AS INT
DECLARE @SiteCount AS INT
DECLARE @SiteTillCount AS INT
DECLARE @UserType AS INT
DECLARE @UserName AS VARCHAR(250)

SELECT @AllSites = AllSitesVisible, @UserName = UserName, @UserType = UserType FROM Users JOIN UserTypes ON UserTypes.ID = UserType WHERE Users.ID = @UserID

--TODO: These 2 values should be read from EDISDatabases
SELECT @DatabaseID = CAST(PropertyValue AS INT) FROM Configuration WHERE PropertyName = 'Service Owner ID'
SELECT @CashValue = RetailCashValue FROM [EDISSQL1\SQL1].ServiceLogger.dbo.EDISDatabases WHERE ID = @DatabaseID
--SELECT @CashValue = CAST(PropertyValue AS FLOAT) FROM Configuration WHERE PropertyName = 'RetailCashValue'

SELECT @SiteCount = COUNT(EDISID), @SiteTillCount = SUM(CASE Sales WHEN 0 THEN 0 ELSE 1 END) 
FROM (
	SELECT UserSites.EDISID, SUM(ISNULL(Sold,0)) AS Sales
	FROM UserSites
	JOIN Users 
	  ON Users.ID = UserSites.UserID
	JOIN Sites
	  ON Sites.EDISID = UserSites.EDISID
	 AND Sites.Quality = 1
	 AND Sites.[Status] IN (1, 2, 10, 3, 4)
	LEFT JOIN PeriodCacheSales AS Sales
	  ON Sales.EDISID = UserSites.EDISID
	 AND SaleDay BETWEEN @FromMonday AND @ToMonday
	WHERE (UserSites.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID) OR @AllSites = 1)
	  AND ((@UserType IN (1,2) AND Users.UserType = 2) OR (@UserType IN (3,4) AND Users.UserType = 1))
	  AND UserSites.EDISID NOT IN (SELECT EDISID FROM SiteGroupSites JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID WHERE SiteGroups.TypeID = 1 AND IsPrimary = 0)
	GROUP BY UserSites.EDISID ) AS TillSites

--Depending on the User Type the results will return different columns
IF @UserType IN (1,3,4)
BEGIN
	WITH 
	Yield AS (
		SELECT UserName, Users.ID, Yield.EDISID, DispenseDay, Yield.CategoryID, SUM(Drinks) AS Drinks, SUM(Quantity) AS Quantity, SUM(Sales.Sold) AS Sold
		FROM PeriodCacheSales AS Sales
		JOIN ProductCategories
		  ON ProductCategories.ID = Sales.CategoryID
		 AND ProductCategories.IncludeInEstateReporting = 1
		JOIN (SELECT EDISID, DispenseDay, CategoryID, SUM(Drinks) AS Drinks , SUM(Quantity) AS Quantity
			  FROM PeriodCacheYield
			  WHERE DispenseDay BETWEEN @FromMonday AND @ToMonday
			  GROUP BY EDISID, DispenseDay, CategoryID) AS Yield
		  ON Sales.SaleDay = Yield.DispenseDay
		 AND Sales.CategoryID = Yield.CategoryID
		 AND Sales.EDISID = Yield.EDISID
		JOIN UserSites 
		  ON Yield.EDISID = UserSites.EDISID
		JOIN Users 
		  ON UserSites.UserID = Users.ID
		WHERE  (Yield.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID) OR @AllSites = 1)
		AND ((@UserType = 1 AND Users.UserType = 2) OR (@UserType IN (3,4) AND Users.UserType = 1))
		AND DispenseDay BETWEEN @FromMonday AND @ToMonday
		GROUP BY Yield.EDISID, Users.UserName, Users.ID, Yield.DispenseDay, Yield.CategoryID
		HAVING SUM(Sales.Sold) > 0
	)
	SELECT	@UserName AS ReportUser, 
			CAST(UserName AS VARCHAR(255)) AS Name, 
			ID, 
			CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, DispenseDay) + 1, DispenseDay) ELSE DispenseDay END AS [Date], 
			CASE SUM(Drinks) WHEN 0 THEN 0 ELSE SUM(Sold) - SUM(Drinks) END AS TillYield,
			CASE SUM(Drinks) WHEN 0 THEN 0 
			ELSE CASE
				 WHEN ((SUM(Sold) - SUM(Drinks)) * @CashValue) > 0
				 THEN 0 
				 ELSE (SUM(Sold) - SUM(Drinks)) * @CashValue
				 END
			END AS TillYieldCost,
			CASE SUM(Drinks) WHEN 0 THEN 0 
			ELSE CASE
				 WHEN ((SUM(Sold) - SUM(Drinks)) * @CashValue) > 0
				 THEN (SUM(Sold) - SUM(Drinks)) * @CashValue
				 ELSE 0
				 END
			END AS TillYieldGain,
			CASE SUM(Drinks) WHEN 0 THEN 0 ELSE ((SUM(Sold) - SUM(Drinks)) / SUM(Drinks)) +1 END AS TillYieldPercent,
			SUM(Sold) AS Sold,
			SUM(Drinks) AS Drinks,
			@SiteCount AS SiteCount,
			@SiteTillCount AS SitesWithTillCount
	FROM Yield
	GROUP BY	UserName, 
				ID, 
				CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, DispenseDay) + 1, DispenseDay) ELSE DispenseDay END
	--HAVING		(((SUM(Sold) - SUM(Drinks)) / SUM(Drinks)) + 1) BETWEEN 0.85 AND 1.01
	ORDER BY	UserName, 
				CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, DispenseDay) + 1, DispenseDay) ELSE DispenseDay END
END
ELSE IF @UserType = 2
BEGIN
	WITH 
	Yield AS (
		SELECT Yield.EDISID, DispenseDay, Yield.CategoryID, SUM(Drinks) AS Drinks, SUM(Quantity) AS Quantity, SUM(Sales.Sold) AS Sold
		FROM PeriodCacheSales AS Sales
		JOIN ProductCategories
		  ON ProductCategories.ID = Sales.CategoryID
		 AND ProductCategories.IncludeInEstateReporting = 1
		JOIN (SELECT EDISID, DispenseDay, CategoryID, SUM(Drinks) AS Drinks , SUM(Quantity) AS Quantity
			  FROM PeriodCacheYield
			  WHERE DispenseDay BETWEEN @FromMonday AND @ToMonday
			  GROUP BY EDISID, DispenseDay, CategoryID) AS Yield
		  ON Sales.SaleDay = Yield.DispenseDay
		 AND Sales.CategoryID = Yield.CategoryID
		 AND Sales.EDISID = Yield.EDISID
		WHERE Yield.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID)
		  AND DispenseDay BETWEEN @FromMonday AND @ToMonday
		GROUP BY Yield.EDISID, DispenseDay, Yield.CategoryID
		HAVING SUM(Sales.Sold) > 0

	)
	SELECT	@UserName AS ReportUser, 
			@DatabaseID AS DatabaseID, 
			Yield.EDISID AS EDISID, 
			Sites.SiteID AS SiteID, 
			Sites.Name AS Name, 
			COALESCE(NULLIF(Sites.Address2,''), NULLIF(Sites.Address3,''), NULLIF(Sites.Address4,''), '') AS Town, 
			Sites.PostCode AS PostCode, 
			CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, DispenseDay) + 1, DispenseDay) ELSE DispenseDay END AS [Date], 
			CASE SUM(Drinks) WHEN 0 THEN 0 ELSE SUM(Sold) - SUM(Drinks) END AS TillYield,
			CASE SUM(Drinks) 
				WHEN 0 
				THEN 0 
				ELSE CASE
					 WHEN ((SUM(Sold) - SUM(Drinks)) * @CashValue) > 0
					 THEN 0 
					 ELSE (SUM(Sold) - SUM(Drinks)) * @CashValue
					 END
			END AS TillYieldCost,
			CASE SUM(Drinks) WHEN 0 THEN 0 
			ELSE CASE
				 WHEN ((SUM(Sold) - SUM(Drinks)) * @CashValue) > 0
				 THEN (SUM(Sold) - SUM(Drinks)) * @CashValue
				 ELSE 0
				 END
			END AS TillYieldGain,			
			CASE SUM(Drinks) WHEN 0 THEN 0 ELSE ((SUM(Sold) - SUM(Drinks)) / SUM(Drinks)) +1 END AS TillYieldPercent,
			SUM(Sold) AS Sold,
			SUM(Drinks) AS Drinks,
			@SiteCount AS SiteCount,
			@SiteTillCount AS SitesWithTillCount
	FROM Yield
	JOIN Sites ON Sites.EDISID = Yield.EDISID
	GROUP BY	Yield.EDISID, 
				Sites.SiteID, 
				Sites.Name, 
				COALESCE(NULLIF(Sites.Address2,''), NULLIF(Sites.Address3,''), NULLIF(Sites.Address4,''), ''), 
				Sites.PostCode, 
				CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, DispenseDay) + 1, DispenseDay) ELSE DispenseDay END
	ORDER BY	Yield.EDISID, 
				CASE @Weekly WHEN 0 THEN DATEADD(dd, -DATEPART(dd, DispenseDay) + 1, DispenseDay) ELSE DispenseDay END
END
