CREATE PROCEDURE [dbo].[PeriodCacheYieldRebuild]
(
      @From             DATETIME,
      @To               DATETIME,
      @FirstDayOfWeek   INT = 1
)
AS

--DECLARE      @From             DATETIME = '2017-04-03'
--DECLARE      @To               DATETIME = '2017-08-07'
--DECLARE      @FirstDayOfWeek   INT = 1


SET NOCOUNT ON;
SET DATEFIRST @FirstDayOfWeek;

DELETE FROM PeriodCacheYieldDaily
WHERE (DispenseDay BETWEEN @From AND @To); ----- OR (@From IS NULL AND @To IS NULL)   --- RN: removed

--Merge secondary systems
--DECLARE @PrimaryEDIS TABLE(PrimaryEDISID INT NOT NULL PRIMARY KEY(PrimaryEDISID,EDISID), EDISID INT NOT NULL UNIQUE (EDISID));   
IF OBJECT_ID('tempdb..#PrimaryEDIS') IS NOT NULL DROP TABLE #PrimaryEDIS;			--- RN addition
CREATE TABLE #PrimaryEDIS (ID SMALLINT IDENTITY(1,1) PRIMARY KEY, PrimaryEDISID INT NOT NULL, EDISID INT NOT NULL);   --- RN MOD ...indexed temp table with surrogate key 

INSERT INTO #PrimaryEDIS(PrimaryEDISID,EDISID)
SELECT MAX(PrimaryEDISID) AS PrimaryEDISID, SiteGroupSites.EDISID
FROM(
      SELECT SiteGroupID, SiteGroupSites.EDISID AS PrimaryEDISID
      FROM SiteGroupSites 
      WHERE SiteGroupID IN (SELECT ID FROM SiteGroups WHERE TypeID = 1)
      AND IsPrimary = 1
      GROUP BY SiteGroupID, SiteGroupSites.EDISID
) AS PrimarySites
JOIN SiteGroupSites ON SiteGroupSites.SiteGroupID = PrimarySites.SiteGroupID
LEFT JOIN PumpSetup ON PumpSetup.EDISID = SiteGroupSites.EDISID
GROUP BY SiteGroupSites.EDISID;
----- ORDER BY PrimaryEDISID    --- RN: removed

--BUILD SPEED TABLE
INSERT INTO PeriodCacheYieldDaily(EDISID, DispenseDay, CategoryID, Quantity, CleaningWaste, Drinks, OutsideThreshold)
SELECT 
    ISNULL(CacheTable.EDISID, WasteTable.EDISID), 
    ISNULL(CacheTable.TradingDay, WasteTable.TradingDay), 
    ISNULL(CacheTable.CategoryID, WasteTable.CategoryID), 
    ISNULL(SUM(CacheTable.Quantity),0) AS Quantity, 
    ISNULL(SUM(WasteTable.Quantity),0) AS WastedQuantity, 
    ISNULL(SUM(CacheTable.Drinks),0) AS Drinks, 
    0
FROM (
    SELECT
        CacheTable.EDISID, 
        CacheTable.TradingDay, 
        CacheTable.CategoryID, 
        SUM(CacheTable.Quantity) AS Quantity, 
        SUM(CacheTable.Drinks) AS Drinks, 
        0 AS BadYield
    FROM (
          SELECT 
            ISNULL(PrimaryEDIS.PrimaryEDISID, DispenseActions.EDISID) AS EDISID, 
            TradingDay, 
            Products.ID, 
            Products.CategoryID, 
            SUM(Pints) AS Quantity, 
            SUM(EstimatedDrinks) AS Drinks, 
            CASE SUM(EstimatedDrinks) 
                WHEN 0 
                THEN 0 
                ELSE (SUM(EstimatedDrinks)/SUM(Pints)) 
            END AS Yield, 
            ConfigurationPivot.LowSanePouringYieldPercent, 
            ConfigurationPivot.HighSanePouringYieldPercent,                   
            0 AS BadYield
          FROM DispenseActions
          JOIN Products 
            ON Products.ID = DispenseActions.Product
          LEFT JOIN #PrimaryEDIS AS PrimaryEDIS 
            ON PrimaryEDIS.EDISID = DispenseActions.EDISID
          JOIN Sites 
            ON Sites.EDISID = DispenseActions.EDISID AND Sites.Quality = 1
        FULL JOIN ConfigurationPivot ON 1=1
          WHERE LiquidType = 2
          AND NOT EXISTS
          (
                SELECT siy.ID
                FROM ServiceIssuesYield AS siy
                JOIN Calls ON siy.CallID = Calls.ID
                WHERE 
                siy.DateFrom <= DispenseActions.[TradingDay]
                AND (siy.DateTo IS NULL OR siy.DateTo >= DispenseActions.[TradingDay])
                AND siy.RealEDISID = DispenseActions.EDISID
                AND siy.ProductID = DispenseActions.Product
                AND Calls.AbortReasonID = 0
          )
          AND EstimatedDrinks IS NOT NULL
          AND Products.IsMetric = 0
          AND (TradingDay BETWEEN DATEADD(dd, DATEPART(dw, 7-@From)-1, @From) AND DATEADD(dd, 7-DATEPART(dw, @To), @To))  --RN MOD: to get SARG------ (((DATEADD(dd, -DATEPART(dw, TradingDay) + 1, TradingDay) BETWEEN @From AND @To)) OR (@From IS NULL AND @To IS NULL))
          GROUP BY 
            ISNULL(PrimaryEDIS.PrimaryEDISID, DispenseActions.EDISID), 
            TradingDay, 
            Products.ID, 
            Products.CategoryID, 
            ConfigurationPivot.LowSanePouringYieldPercent, 
            ConfigurationPivot.HighSanePouringYieldPercent
    ) AS CacheTable
    GROUP BY 
        CacheTable.EDISID, 
        CacheTable.TradingDay, 
        CacheTable.CategoryID
    ) AS CacheTable
FULL JOIN (
    SELECT EDISID, TradingDay, CategoryID, SUM(Quantity) AS Quantity
    FROM (
          SELECT 
            ISNULL(PrimaryEDIS.PrimaryEDISID, DispenseActions.EDISID) AS EDISID, 
            TradingDay, 
            Products.ID, 
            Products.CategoryID, 
            SUM(Pints) AS Quantity
          FROM DispenseActions
          JOIN Products 
            ON Products.ID = DispenseActions.Product
          LEFT JOIN #PrimaryEDIS AS PrimaryEDIS 
            ON PrimaryEDIS.EDISID = DispenseActions.EDISID
          JOIN Sites 
            ON Sites.EDISID = DispenseActions.EDISID AND Sites.Quality = 1
          WHERE LiquidType = 5
          AND NOT EXISTS
          (
                SELECT siy.ID
                FROM ServiceIssuesYield AS siy
                JOIN Calls ON siy.CallID = Calls.ID
                WHERE 
                siy.DateFrom <= DispenseActions.[TradingDay]
                AND (siy.DateTo IS NULL OR siy.DateTo >= DispenseActions.[TradingDay])
                AND siy.RealEDISID = DispenseActions.EDISID
                AND siy.ProductID = DispenseActions.Product
                AND Calls.AbortReasonID = 0
          )
          AND EstimatedDrinks IS NOT NULL
          AND Products.IsMetric = 0
          AND (TradingDay BETWEEN @From AND @To) ----- OR (@From IS NULL AND @To IS NULL))  --- RN: removed
          GROUP BY 
            ISNULL(PrimaryEDIS.PrimaryEDISID, DispenseActions.EDISID), 
            TradingDay, 
            Products.ID, 
            Products.CategoryID
    ) AS WasteTable
    GROUP BY 
        EDISID, 
        TradingDay, 
        CategoryID
    )
AS WasteTable ON 
    WasteTable.EDISID = CacheTable.EDISID AND 
    WasteTable.TradingDay = CacheTable.TradingDay AND 
    WasteTable.CategoryID = CacheTable.CategoryID
GROUP BY 
    ISNULL(CacheTable.EDISID, WasteTable.EDISID), 
    ISNULL(CacheTable.TradingDay, WasteTable.TradingDay),
    ISNULL(CacheTable.CategoryID, WasteTable.CategoryID);

DELETE FROM PeriodCacheYield
WHERE (DispenseDay BETWEEN @From AND @To); ------- OR (@From IS NULL AND @To IS NULL)  --- RN: removed

INSERT INTO  PeriodCacheYield(EDISID, DispenseDay, CategoryID, Quantity, Drinks, OutsideThreshold, CleaningWaste)
SELECT	EDISID,
		DATEADD(dd, -DATEPART(dw, DispenseDay) + 1, DispenseDay),
		CategoryID,
		SUM(Quantity),
		SUM(Drinks),
		0 AS BadYield,
		SUM(CleaningWaste)
FROM PeriodCacheYieldDaily
FULL JOIN ConfigurationPivot ON 1=1
WHERE (DispenseDay BETWEEN @From AND @To) ------- OR (@From IS NULL AND @To IS NULL))  --- RN: removed
	-- RN comment: I needed to use the below on EDISTESTSQL2 to shift the 'sliding window', avoid misalignment & duplicate PK violation. NB: The PeriodCacheCleaningDispenseRebuild PROC uses the below logic.
		--WHERE(DispenseDay BETWEEN DATEADD(dd, DATEPART(dw, 7-@From)-1, @From) AND DATEADD(dd, 7-DATEPART(dw, @To), @To))
GROUP BY EDISID,
		DATEADD(dd, -DATEPART(dw, DispenseDay) + 1, DispenseDay),
		CategoryID,
		ConfigurationPivot.LowSanePouringYieldPercent, 
        ConfigurationPivot.HighSanePouringYieldPercent;

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[PeriodCacheYieldRebuild] TO PUBLIC
    AS [dbo];

