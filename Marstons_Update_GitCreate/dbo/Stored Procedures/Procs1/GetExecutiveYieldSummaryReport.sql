
CREATE PROCEDURE [dbo].[GetExecutiveYieldSummaryReport]
(
    @UserID                 INT,
    @From                   DATE,
    @To                     DATE,
    @IncludeCleaningWaste   BIT,
    @UnitMultiplier         FLOAT
)
AS

--DECLARE @UserID                 INT = 79
--DECLARE @From                   DATE = '2017-06-09'
--DECLARE @To                     DATE = '2017-06-15'
--DECLARE @IncludeCleaningWaste   BIT = 0
--DECLARE @UnitMultiplier         FLOAT = 19.2152

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

DECLARE @SiteExceptions TABLE ([EDISID] INT NOT NULL, [ExceptionCount] INT NOT NULL)

INSERT INTO @SiteExceptions ([EDISID], [ExceptionCount])
SELECT
    [EDISID],
    COUNT(*) AS 'SiteExceptions'
FROM SiteExceptions se
WHERE se.ExceptionEmailID IS NOT NULL
	AND se.TradingDate BETWEEN @From AND @To
GROUP BY 
    [EDISID]

DECLARE @SiteQuality TABLE ([EDISID] INT NOT NULL, [Quantity] FLOAT, [QuantityOutOfSpec] FLOAT)

INSERT INTO @SiteQuality ([EDISID], [Quantity], [QuantityOutOfSpec])
EXEC [dbo].[GetReportDispenseQuality] @UserID, @From, @To

--SELECT	Sites.EDISID,
--		SUM(Quantity) * @UnitMultiplier AS Quantity,
--		SUM(QuantityOutOfSpec) * @UnitMultiplier AS QuantityOutOfSpec
--FROM PeriodCacheQuality
--JOIN Sites ON Sites.EDISID = PeriodCacheQuality.EDISID
--JOIN Products ON Products.ID = PeriodCacheQuality.ProductID
--JOIN ProductCategories ON ProductCategories.ID = Products.CategoryID
--WHERE TradingDay BETWEEN @From AND @To
--GROUP BY 
--    Sites.EDISID

DECLARE @DatabaseID INT
SELECT @DatabaseID = [ID] FROM [SQL1\SQL1].[ServiceLogger].[dbo].[EDISDatabases] WHERE [Name] = DB_NAME()

IF @DatabaseID IS NULL
BEGIN
    -- Should never happen on Production
    SELECT @DatabaseID = CAST(PropertyValue AS INT)
    FROM [dbo].[Configuration]
    WHERE [PropertyName] = 'Service Owner ID'
END

DECLARE @ExecReport TABLE (
    [DatabaseID] INT NOT NULL,
    [RMID] INT NOT NULL,
    [RM] VARCHAR(255) NOT NULL,
    [BDMID] INT NOT NULL,
    [BDM] VARCHAR(255) NOT NULL,
    [EDISID] INT NOT NULL,
    [SiteID] VARCHAR(15) NOT NULL,
    [Name] VARCHAR(60) NOT NULL,
    [Address1] VARCHAR(50) NOT NULL,
    [Address2] VARCHAR(50),
    [BeerDispensed] FLOAT NOT NULL,
    [BeerInLineCleaning] FLOAT NOT NULL,
    [BeerMeasured] FLOAT NOT NULL,
    [DrinksDispensed] FLOAT NOT NULL,
    [Sold] FLOAT NOT NULL,
    [POSYieldCashValue] FLOAT NOT NULL,
    [CleaningCashValue] FLOAT NOT NULL,
    [PouringYieldCashValue] FLOAT NOT NULL,
    [TotalDispense] FLOAT NOT NULL,
    [OverdueCleanDispense] FLOAT NOT NULL
    )

INSERT INTO @ExecReport (
    [DatabaseID], [RMID], [RM], [BDMID], [BDM], [EDISID], [SiteID], [Name], [Address1], [Address2], [BeerDispensed], [BeerInLineCleaning],
    [BeerMeasured], [DrinksDispensed], [Sold], [POSYieldCashValue], [CleaningCashValue], [PouringYieldCashValue], [TotalDispense], [OverdueCleanDispense])
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
      ,SUM(ISNULL([PeriodCacheYieldDaily].[Quantity], 0)) * @UnitMultiplier AS BeerDispensed
      ,SUM(ISNULL([PeriodCacheYieldDaily].[CleaningWaste], 0)) * @UnitMultiplier AS BeerInLineCleaning
      ,SUM(ISNULL([PeriodCacheYieldDaily].[Quantity], 0) + ISNULL([PeriodCacheYieldDaily].[CleaningWaste], 0)) * @UnitMultiplier AS BeerMeasured
      ,SUM(ISNULL([PeriodCacheYieldDaily].[Drinks], 0)) AS DrinksDispensed
      ,SUM(ISNULL([PeriodCacheSalesDaily].[Sold], 0)) * @UnitMultiplier AS Sold
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
GROUP BY 
       [RMUsers].[ID]
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
	  

SELECT 
    ROW_NUMBER() OVER(
        ORDER BY 
        CASE WHEN @IncludeCleaningWaste = 0
             THEN
             CASE WHEN [BeerDispensed] = 0
                  THEN 0
                  ELSE (([Sold] - [BeerDispensed]) / [BeerDispensed]) + 1
                  END 
             ELSE
             CASE WHEN [BeerMeasured] = 0
                  THEN 0
                  ELSE (([Sold] - [BeerMeasured]) / [BeerMeasured]) + 1
                  END 
        END DESC) AS [Rank],
    [Rank1].[Rank] AS [Rank1],
    [Rank2].[Rank] AS [Rank2],
    [Rank3].[Rank] AS [Rank3],
    [ExecReport].[DatabaseID], 
    [RMID], 
    [RM], 
    [BDMID], 
    [BDM], 
    [ExecReport].[EDISID], 
    [SiteID], 
    [Name], 
    [Address1], 
    [Address2], 
    [BeerDispensed], 
    [BeerInLineCleaning],
    [BeerMeasured], 
    [DrinksDispensed], 
    [Sold], 
    [POSYieldCashValue], 
    [CleaningCashValue], 
    [PouringYieldCashValue], 
    [TotalDispense], 
    [OverdueCleanDispense],
    CASE WHEN @IncludeCleaningWaste = 0
         THEN [Sold] - [BeerDispensed] 
         ELSE [Sold] - ([BeerDispensed] + [BeerInLineCleaning])
         END AS [OverallYield],
    CASE WHEN @IncludeCleaningWaste = 0
         THEN
            CASE WHEN [BeerDispensed] = 0
                 THEN 0
                 ELSE (([Sold] - [BeerDispensed]) / [BeerDispensed]) + 1
                 END 
         ELSE
            CASE WHEN [BeerMeasured] = 0
                 THEN 0
                 ELSE (([Sold] - [BeerMeasured]) / [BeerMeasured]) + 1
                 END 
         END AS [OverallYieldPercent],
    --[BaseYield].[Value] AS [PropertyYield],
    [BaseYield].[Value] / 100.0 AS [OverallYieldPreSystem],
    ([BaseYield].[Value] / 100.0) 
     -
    CASE WHEN @IncludeCleaningWaste = 0
         THEN
            CASE WHEN [BeerDispensed] = 0
                 THEN 0
                 ELSE (([Sold] - [BeerDispensed]) / [BeerDispensed]) + 1
                 END 
         ELSE
            CASE WHEN [BeerMeasured] = 0
                 THEN 0
                 ELSE (([Sold] - [BeerMeasured]) / [BeerMeasured]) + 1
                 END 
         END AS [Improvement],
    CASE WHEN @IncludeCleaningWaste = 0
         THEN 0
         ELSE ([BeerInLineCleaning] * [CleaningCashValue] * -1)
         END
     +
    (([DrinksDispensed] - [BeerDispensed]) * [PouringYieldCashValue])
     + 
    (([Sold] - [DrinksDispensed]) * [POSYieldCashValue]) AS [OverallCash],
    [DrinksDispensed] - [BeerDispensed] AS [OperationalYield],
    ([DrinksDispensed] - [BeerDispensed]) * [PouringYieldCashValue] AS [OperationalYieldCash],
    CASE WHEN [BeerDispensed] = 0
         THEN 0
         ELSE [DrinksDispensed] / [BeerDispensed]
         END AS [OperationalYieldPercent],
    [Sold] - [DrinksDispensed] AS [RetailYield],
    ([Sold] - [DrinksDispensed]) * [POSYieldCashValue] AS [RetailYieldCash],
    CASE WHEN [DrinksDispensed] = 0
         THEN 0
         ELSE (([Sold] - [DrinksDispensed]) / [DrinksDispensed]) + 1
         END AS [RetailYieldPercent],
    ([BeerInLineCleaning] * [CleaningCashValue]) * -1 AS [CleaningCash],
    [PeriodCacheQuality].[Quantity] AS [Quantity], -- TemperatureQuantity
    [PeriodCacheQuality].[QuantityOutOfSpec],
    CASE WHEN [PeriodCacheQuality].[Quantity] = 0
         THEN 0
         --ELSE [PeriodCacheQuality].[QuantityOutOfSpec] / CASE WHEN @IncludeCleaningWaste = 0 THEN [BeerDispensed] ELSE [BeerMeasured] END 
         ELSE [PeriodCacheQuality].[QuantityOutOfSpec] / [PeriodCacheQuality].[Quantity]
         END AS [QuantityOutofSpecPercent],
    CASE WHEN [TotalDispense] = 0
         THEN 0
         ELSE [OverdueCleanDispense] / [TotalDispense] 
         END AS [BeerViaUncleanLines], 
    [SiteExceptions].[ExceptionCount] AS [ExceptionsGenerated]
FROM @ExecReport AS [ExecReport]
LEFT JOIN @SiteQuality AS [PeriodCacheQuality] ON [ExecReport].[EDISID] = [PeriodCacheQuality].[EDISID]
LEFT JOIN @SiteExceptions AS [SiteExceptions] ON [ExecReport].[EDISID] = [SiteExceptions].[EDISID]
LEFT JOIN (
    SELECT
        [SiteProperties].[EDISID],
        [SiteProperties].[Value]
    FROM [dbo].[SiteProperties]
    JOIN [dbo].[Properties] ON [SiteProperties].[PropertyID] = [Properties].[ID]
    WHERE [Properties].[Name] = 'BaseOverallYield') AS [BaseYield] ON [ExecReport].[EDISID] = [BaseYield].[EDISID]
LEFT JOIN (
    SELECT 
        ROW_NUMBER() OVER(
            ORDER BY 
            CASE WHEN @IncludeCleaningWaste = 0
                 THEN
                 CASE WHEN [BeerDispensed] = 0
                      THEN 0
                      ELSE (([Sold] - [BeerDispensed]) / [BeerDispensed]) + 1
                      END 
                 ELSE
                 CASE WHEN [BeerMeasured] = 0
                      THEN 0
                      ELSE (([Sold] - [BeerMeasured]) / [BeerMeasured]) + 1
                      END 
            END DESC) AS [Rank],
        [DatabaseID],
        [EDISID]
    FROM (
        SELECT @DatabaseID AS DatabaseID
              ,COALESCE([PeriodCacheYieldDaily].[EDISID], [PeriodCacheSalesDaily].[EDISID]) AS [EDISID]
              ,SUM(ISNULL([PeriodCacheYieldDaily].[Quantity], 0)) AS BeerDispensed
              ,SUM(ISNULL([PeriodCacheYieldDaily].[Quantity], 0) + ISNULL([PeriodCacheYieldDaily].[CleaningWaste], 0)) AS BeerMeasured
              ,SUM(ISNULL([PeriodCacheSalesDaily].[Sold], 0)) AS Sold
        FROM (
	        SELECT	EDISID,
			        CategoryID,
			        SUM(Quantity) AS Quantity,
			        SUM(CleaningWaste) AS CleaningWaste,
			        SUM(Drinks) AS Drinks
	        FROM PeriodCacheYieldDaily
	        WHERE DispenseDay BETWEEN DATEADD(WEEK, -1, @From) AND DATEADD(WEEK, -1, @To)
	        --AND OutsideThreshold = 0
	        GROUP BY EDISID, CategoryID
        ) AS PeriodCacheYieldDaily
        FULL JOIN (
	        SELECT	EDISID,
			        CategoryID,
			        SUM(Sold) AS Sold
	        FROM PeriodCacheSalesDaily
	        WHERE SaleDay BETWEEN DATEADD(WEEK, -1, @From) AND DATEADD(WEEK, -1, @To)
	        GROUP BY EDISID, CategoryID
        ) AS PeriodCacheSalesDaily ON [PeriodCacheSalesDaily].EDISID = [PeriodCacheYieldDaily].[EDISID]
          AND [PeriodCacheSalesDaily].[CategoryID] = [PeriodCacheYieldDaily].[CategoryID]
        JOIN Sites ON Sites.EDISID = PeriodCacheYieldDaily.EDISID
        JOIN Users ON Users.ID = @UserID
        JOIN UserTypes ON UserTypes.ID = Users.UserType
        LEFT JOIN #UserSites AS UserSites ON UserSites.EDISID = Sites.EDISID
        WHERE (@UserID IS NULL OR [UserSites].[UserID] = @UserID) 
        GROUP BY 
            COALESCE([PeriodCacheYieldDaily].[EDISID], [PeriodCacheSalesDaily].[EDISID])
        ) AS [X1]
    ) AS [Rank1] ON [ExecReport].[EDISID] = [Rank1].[EDISID] AND [ExecReport].[DatabaseID] = [Rank1].[DatabaseID]
LEFT JOIN (
    SELECT 
        ROW_NUMBER() OVER(
            ORDER BY 
            CASE WHEN @IncludeCleaningWaste = 0
                 THEN
                 CASE WHEN [BeerDispensed] = 0
                      THEN 0
                      ELSE (([Sold] - [BeerDispensed]) / [BeerDispensed]) + 1
                      END 
                 ELSE
                 CASE WHEN [BeerMeasured] = 0
                      THEN 0
                      ELSE (([Sold] - [BeerMeasured]) / [BeerMeasured]) + 1
                      END 
            END DESC) AS [Rank],
        [DatabaseID],
        [EDISID]
    FROM (
        SELECT @DatabaseID AS DatabaseID
              ,COALESCE([PeriodCacheYieldDaily].[EDISID], [PeriodCacheSalesDaily].[EDISID]) AS [EDISID]
              ,SUM(ISNULL([PeriodCacheYieldDaily].[Quantity], 0)) AS BeerDispensed
              ,SUM(ISNULL([PeriodCacheYieldDaily].[Quantity], 0) + ISNULL([PeriodCacheYieldDaily].[CleaningWaste], 0)) AS BeerMeasured
              ,SUM(ISNULL([PeriodCacheSalesDaily].[Sold], 0)) AS Sold
        FROM (
	        SELECT	EDISID,
			        CategoryID,
			        SUM(Quantity) AS Quantity,
			        SUM(CleaningWaste) AS CleaningWaste,
			        SUM(Drinks) AS Drinks
	        FROM PeriodCacheYieldDaily
	        WHERE DispenseDay BETWEEN DATEADD(WEEK, -2, @From) AND DATEADD(WEEK, -2, @To)
	        --AND OutsideThreshold = 0
	        GROUP BY EDISID, CategoryID
        ) AS PeriodCacheYieldDaily
        FULL JOIN (
	        SELECT	EDISID,
			        CategoryID,
			        SUM(Sold) AS Sold
	        FROM PeriodCacheSalesDaily
	        WHERE SaleDay BETWEEN DATEADD(WEEK, -2, @From) AND DATEADD(WEEK, -2, @To)
	        GROUP BY EDISID, CategoryID
        ) AS PeriodCacheSalesDaily ON [PeriodCacheSalesDaily].EDISID = [PeriodCacheYieldDaily].[EDISID]
          AND [PeriodCacheSalesDaily].[CategoryID] = [PeriodCacheYieldDaily].[CategoryID]
        JOIN Sites ON Sites.EDISID = PeriodCacheYieldDaily.EDISID
        JOIN Users ON Users.ID = @UserID
        JOIN UserTypes ON UserTypes.ID = Users.UserType
        LEFT JOIN #UserSites AS UserSites ON UserSites.EDISID = Sites.EDISID
        WHERE (@UserID IS NULL OR [UserSites].[UserID] = @UserID) 
        GROUP BY 
            COALESCE([PeriodCacheYieldDaily].[EDISID], [PeriodCacheSalesDaily].[EDISID])
        ) AS [X2]
    ) AS [Rank2] ON [ExecReport].[EDISID] = [Rank2].[EDISID] AND [ExecReport].[DatabaseID] = [Rank2].[DatabaseID]
LEFT JOIN (
    SELECT 
        ROW_NUMBER() OVER(
            ORDER BY 
            CASE WHEN @IncludeCleaningWaste = 0
                 THEN
                 CASE WHEN [BeerDispensed] = 0
                      THEN 0
                      ELSE (([Sold] - [BeerDispensed]) / [BeerDispensed]) + 1
                      END 
                 ELSE
                 CASE WHEN [BeerMeasured] = 0
                      THEN 0
                      ELSE (([Sold] - [BeerMeasured]) / [BeerMeasured]) + 1
                      END 
            END DESC) AS [Rank],
        [DatabaseID],
        [EDISID]
    FROM (
        SELECT @DatabaseID AS DatabaseID
              ,COALESCE([PeriodCacheYieldDaily].[EDISID], [PeriodCacheSalesDaily].[EDISID]) AS [EDISID]
              ,SUM(ISNULL([PeriodCacheYieldDaily].[Quantity], 0)) AS BeerDispensed
              ,SUM(ISNULL([PeriodCacheYieldDaily].[Quantity], 0) + ISNULL([PeriodCacheYieldDaily].[CleaningWaste], 0)) AS BeerMeasured
              ,SUM(ISNULL([PeriodCacheSalesDaily].[Sold], 0)) AS Sold
        FROM (
	        SELECT	EDISID,
			        CategoryID,
			        SUM(Quantity) AS Quantity,
			        SUM(CleaningWaste) AS CleaningWaste,
			        SUM(Drinks) AS Drinks
	        FROM PeriodCacheYieldDaily
	        WHERE DispenseDay BETWEEN DATEADD(WEEK, -3, @From) AND DATEADD(WEEK, -3, @To)
	        --AND OutsideThreshold = 0
	        GROUP BY EDISID, CategoryID
        ) AS PeriodCacheYieldDaily
        FULL JOIN (
	        SELECT	EDISID,
			        CategoryID,
			        SUM(Sold) AS Sold
	        FROM PeriodCacheSalesDaily
	        WHERE SaleDay BETWEEN DATEADD(WEEK, -3, @From) AND DATEADD(WEEK, -3, @To)
	        GROUP BY EDISID, CategoryID
        ) AS PeriodCacheSalesDaily ON [PeriodCacheSalesDaily].EDISID = [PeriodCacheYieldDaily].[EDISID]
          AND [PeriodCacheSalesDaily].[CategoryID] = [PeriodCacheYieldDaily].[CategoryID]
        JOIN Sites ON Sites.EDISID = PeriodCacheYieldDaily.EDISID
        JOIN Users ON Users.ID = @UserID
        JOIN UserTypes ON UserTypes.ID = Users.UserType
        LEFT JOIN #UserSites AS UserSites ON UserSites.EDISID = Sites.EDISID
        WHERE (@UserID IS NULL OR [UserSites].[UserID] = @UserID) 
        GROUP BY 
            COALESCE([PeriodCacheYieldDaily].[EDISID], [PeriodCacheSalesDaily].[EDISID])
        ) AS [X3]
    ) AS [Rank3] ON [ExecReport].[EDISID] = [Rank3].[EDISID] AND [ExecReport].[DatabaseID] = [Rank3].[DatabaseID]
ORDER BY 
    CASE WHEN @IncludeCleaningWaste = 0
         THEN
            CASE WHEN [BeerDispensed] = 0
                 THEN 0
                 ELSE (([Sold] - [BeerDispensed]) / [BeerDispensed]) + 1
                 END 
         ELSE
            CASE WHEN [BeerMeasured] = 0
                 THEN 0
                 ELSE (([Sold] - [BeerMeasured]) / [BeerMeasured]) + 1
                 END 
         END DESC

DROP TABLE #UserSites
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetExecutiveYieldSummaryReport] TO PUBLIC
    AS [dbo];

