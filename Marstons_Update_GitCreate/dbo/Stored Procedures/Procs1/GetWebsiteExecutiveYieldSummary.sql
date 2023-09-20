CREATE PROCEDURE [dbo].[GetWebsiteExecutiveYieldSummary]
(
    @UserID     INT,
    @From       DATE,
    @To         DATE
)
AS

--DECLARE @UserID INT = 11
--DECLARE @From DATE = '2014-02-17'
--DECLARE @To DATE = '2014-02-23'

SET NOCOUNT ON

DECLARE @AllSitesVisible BIT

SELECT @AllSitesVisible = AllSitesVisible
FROM UserTypes
JOIN Users ON Users.UserType = UserTypes.ID
WHERE Users.ID = @UserID

CREATE TABLE #UserSites(UserID INT, EDISID INT)

IF @AllSitesVisible = 1
BEGIN
 INSERT INTO #UserSites
 SELECT @UserID, EDISID
 FROM Sites


END
ELSE
BEGIN
 INSERT INTO #UserSites
 SELECT Users.ID, UserSites.EDISID
 FROM Users
 JOIN UserSites ON UserSites.UserID = Users.ID
 WHERE UserID = @UserID
END

DECLARE @DatabaseID INTEGER

SELECT @DatabaseID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE Configuration.PropertyName = 'Service Owner ID'

SELECT @DatabaseID AS DatabaseID
	  ,ISNULL([RMUsers].[ID], 0) AS [RMID]
      ,ISNULL([RMUsers].[UserName], '' ) AS [RM]
      ,ISNULL([BDMUsers].[ID], 0) AS [BDMID]
      ,ISNULL([BDMUsers].[UserName], '') AS [BDM]
      ,COALESCE([PeriodCacheYieldDaily].[EDISID], [PeriodCacheSalesDaily].[EDISID]) AS [EDISID]
      ,[Sites].[SiteID] AS [SiteID]
      ,[Sites].[Name] AS [Name]
      ,[Sites].[Address1] AS [Address1]
      ,[Sites].[Address2] AS [Address2]
      ,SUM(ISNULL([PeriodCacheYieldDaily].[Quantity], 0)) AS BeerDispensed
      ,SUM(ISNULL([PeriodCacheYieldDaily].[CleaningWaste], 0)) AS BeerInLineCleaning
      ,SUM(ISNULL([PeriodCacheYieldDaily].[Quantity], 0) + ISNULL([PeriodCacheYieldDaily].[CleaningWaste], 0)) AS BeerMeasured
      ,SUM(ISNULL([PeriodCacheYieldDaily].[Drinks], 0)) AS DrinksDispensed
      ,SUM(ISNULL([PeriodCacheSalesDaily].[Sold], 0)) AS Sold
	  ,ISNULL(SiteOwner.POSYieldCashValue, 0) AS POSYieldCashValue
      ,ISNULL(SiteOwner.CleaningCashValue, 0) AS CleaningCashValue
      ,ISNULL(SiteOwner.PouringYieldCashValue, 0) AS PouringYieldCashValue
      ,SUM(ISNULL([PeriodCacheCleaningDispenseDaily].TotalDispense, 0)) AS TotalDispense
      ,SUM(ISNULL([PeriodCacheCleaningDispenseDaily].OverdueCleanDispense, 0)) AS OverdueCleanDispense
FROM (
	SELECT	EDISID,
			CategoryID,
			SUM(Quantity) AS Quantity,
			SUM(CleaningWaste) AS CleaningWaste,
			SUM(Drinks) AS Drinks
	FROM PeriodCacheYieldDaily
	WHERE DispenseDay BETWEEN @From AND @To
	--AND OutsideThreshold = 0
	GROUP BY EDISID, CategoryID
) AS PeriodCacheYieldDaily
FULL JOIN (
	SELECT	EDISID,
			CategoryID,
			SUM(Sold) AS Sold
	FROM PeriodCacheSalesDaily
	WHERE SaleDay BETWEEN @From AND @To
	GROUP BY EDISID, CategoryID
) AS PeriodCacheSalesDaily ON [PeriodCacheSalesDaily].EDISID = [PeriodCacheYieldDaily].[EDISID]
  AND [PeriodCacheSalesDaily].[CategoryID] = [PeriodCacheYieldDaily].[CategoryID]
FULL JOIN (
		SELECT	EDISID,
				CategoryID,
				SUM(TotalDispense) AS TotalDispense,
				SUM(OverdueCleanDispense) AS OverdueCleanDispense
	FROM PeriodCacheCleaningDispenseDaily
	WHERE [Date] BETWEEN @From AND @To
	GROUP BY EDISID, CategoryID
) AS PeriodCacheCleaningDispenseDaily ON [PeriodCacheCleaningDispenseDaily].[EDISID] = [PeriodCacheYieldDaily].[EDISID]
 AND [PeriodCacheCleaningDispenseDaily].[CategoryID] = [PeriodCacheYieldDaily].[CategoryID]
LEFT JOIN
(
 SELECT Sites.EDISID, MAX(RMUsers.ID) AS RMID, MAX(BDMUsers.ID) AS BDMID
 FROM Sites
 JOIN UserSites ON UserSites.EDISID = Sites.EDISID
 LEFT JOIN Users AS RMUsers ON RMUsers.ID = UserSites.UserID 
 AND RMUsers.UserType = 1
 LEFT JOIN Users AS BDMUsers ON BDMUsers.ID = UserSites.UserID 
 AND BDMUsers.UserType = 2
 GROUP BY Sites.EDISID
) AS SiteUsers ON SiteUsers.EDISID = PeriodCacheYieldDaily.EDISID
LEFT JOIN Users AS RMUsers ON RMUsers.ID = SiteUsers.RMID
LEFT JOIN Users AS BDMUsers ON BDMUsers.ID = SiteUsers.BDMID
JOIN Sites ON Sites.EDISID = PeriodCacheYieldDaily.EDISID
JOIN Users ON Users.ID = @UserID
JOIN UserTypes ON UserTypes.ID = Users.UserType
LEFT JOIN #UserSites AS UserSites ON UserSites.EDISID = Sites.EDISID
JOIN (
    SELECT EDISID, POSYieldCashValue, CleaningCashValue, PouringYieldCashValue
    FROM Sites
    JOIN Owners ON Owners.ID = Sites.OwnerID
) AS SiteOwner ON SiteOwner.EDISID = [PeriodCacheYieldDaily].[EDISID]
WHERE (@UserID IS NULL OR [UserSites].[UserID] = @UserID) 
GROUP BY [RMUsers].[ID]
      ,[RMUsers].[UserName]
      ,[BDMUsers].[ID] 
      ,[BDMUsers].[UserName] 
      ,COALESCE([PeriodCacheYieldDaily].[EDISID], [PeriodCacheSalesDaily].[EDISID])
      ,[Sites].[SiteID]
   ,[Sites].[Name]
      ,[Sites].[Address1] 
      ,[Sites].[Address2] 
   ,SiteOwner.POSYieldCashValue
      ,SiteOwner.CleaningCashValue
      ,SiteOwner.PouringYieldCashValue
	  
DROP TABLE #UserSites

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebsiteExecutiveYieldSummary] TO PUBLIC
    AS [dbo];

