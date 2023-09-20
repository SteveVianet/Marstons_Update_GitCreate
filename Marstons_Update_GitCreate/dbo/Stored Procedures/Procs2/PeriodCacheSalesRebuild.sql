CREATE PROCEDURE [dbo].[PeriodCacheSalesRebuild]
(
	@From	DATETIME,
	@To	DATETIME,
	@FirstDayOfWeek INT = 1
)
AS

SET NOCOUNT ON;
SET DATEFIRST @FirstDayOfWeek;

DELETE FROM PeriodCacheSalesDaily
WHERE (SaleDay BETWEEN @From AND @To); ------ OR (@From IS NULL AND @To IS NULL)  --- RN: removed

--Merge secondary systems
-----DECLARE @PrimaryEDIS TABLE(PrimaryEDISID INT NOT NULL PRIMARY KEY(PrimaryEDISID,EDISID), EDISID INT NOT NULL UNIQUE (EDISID));   
IF OBJECT_ID('tempdb..#PrimaryEDIS') IS NOT NULL DROP TABLE #PrimaryEDIS;			--- RN addition
CREATE TABLE #PrimaryEDIS (ID SMALLINT IDENTITY(1,1) PRIMARY KEY, PrimaryEDISID INT NOT NULL, EDISID INT NOT NULL);   --- RN MOD ....indexed temp table with surrogate key 

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
------ ORDER BY PrimaryEDISID;    --- RN: removed

--BUILD SPEED TABLE
INSERT INTO PeriodCacheSalesDaily(EDISID,SaleDay,CategoryID,Sold)
SELECT	ISNULL(PrimaryEDIS.PrimaryEDISID, Sales.EDISID) AS EDISID, 
		TradingDate, 
		CategoryID, 
		SUM(Sales.Quantity) AS Sales
FROM Sales
JOIN Products ON Products.ID = Sales.ProductID
LEFT JOIN #PrimaryEDIS AS PrimaryEDIS ON PrimaryEDIS.EDISID = Sales.EDISID
JOIN Sites 
  ON Sites.EDISID = Sales.EDISID
 AND Sites.Quality = 1
WHERE Products.IsMetric = 0
--AND CategoryID IN (SELECT ID FROM ProductCategories WHERE [ID] IN (18, 19, 21, 23, 25, 26))
AND (TradingDate BETWEEN @From AND @To)     ------ OR (@From IS NULL AND @To IS NULL))   --- RN: removed
AND NOT EXISTS
(
    SELECT ID
    FROM ServiceIssuesYield AS siy
    WHERE siy.DateFrom <= Sales.TradingDate
    AND (siy.DateTo IS NULL OR siy.DateTo >= Sales.TradingDate)
    AND siy.RealEDISID = Sales.EDISID
    AND siy.ProductID = Sales.ProductID
)
GROUP BY ISNULL(PrimaryEDIS.PrimaryEDISID, Sales.EDISID), TradingDate, CategoryID;

DELETE FROM PeriodCacheSales
WHERE (SaleDay BETWEEN @From AND @To);   -------  OR (@From IS NULL AND @To IS NULL)  --- RN: removed

INSERT INTO PeriodCacheSales(EDISID, SaleDay, CategoryID, Sold)
SELECT	EDISID,
		DATEADD(dd, -DATEPART(dw, SaleDay) + 1, SaleDay),
		CategoryID,
		SUM(Sold)
FROM PeriodCacheSalesDaily
WHERE (SaleDay BETWEEN @From AND @To)   -------- OR (@From IS NULL AND @To IS NULL))  --- RN: removed
	-- RN comment: I needed to use the below on EDISTESTSQL2 to shift the 'sliding window', avoid misalignment & duplicate PK violation. NB: The PeriodCacheCleaningDispenseRebuild PROC uses the below logic.
		--WHERE(SaleDay BETWEEN DATEADD(dd, DATEPART(dw, 7-@From)-1, @From) AND DATEADD(dd, 7-DATEPART(dw, @To), @To)) 
GROUP BY EDISID,  
		DATEADD(dd, -DATEPART(dw, SaleDay) + 1, SaleDay),
		CategoryID;


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[PeriodCacheSalesRebuild] TO PUBLIC
    AS [dbo];

