CREATE PROCEDURE [dbo].[PeriodCacheTemperatureRebuild]

	@FromDate 		DATETIME,  --- RN removal:   = NULL  --no required
	@ToDate			DATETIME,  --- RN removal:   = NULL  --no required 
	@FirstDayOfWeek INT = 1,
	@AmberValue		INT = 2
AS

SET NOCOUNT ON;
SET DATEFIRST @FirstDayOfWeek;
SET @FromDate = dbo.fnGetMonday(@FromDate);   -- RW: From date really should be a Monday.  To date doesn't matter so much. 


DELETE
FROM PeriodCacheTemperature
WHERE (Date BETWEEN @FromDate AND @ToDate) ------- RN removel:  -- OR (@FromDate IS NULL AND @ToDate IS NULL);  ...helping to simify the query, giving Query Optimiser a better chance, the Data column in PeriodCacheTemperature donesn't allow NULLs, and the values being feed into the PROC are never null.

--- Merge secondary systems ---
---DECLARE @PrimaryEDIS TABLE (PrimaryEDISID INT NOT NULL, EDISID INT NOT NULL);      
IF OBJECT_ID('tempdb..#PrimaryEDIS') IS NOT NULL DROP TABLE #PrimaryEDIS;			--- RN addition
CREATE TABLE #PrimaryEDIS (ID SMALLINT IDENTITY(1,1) PRIMARY KEY, PrimaryEDISID INT NOT NULL, EDISID INT NOT NULL);   --- RN MOD ....indexed temp table with surrogate key to reduce the cardinality estimate issues with such big joins.

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
GROUP BY SiteGroupSites.EDISID
--ORDER BY PrimaryEDISID        -------- RN removed: ORDER BY not need, its a 'hidden cursor' in the database engine, and hurts performance and memory use.
;

--- BUILD SPEED TABLE ---
INSERT INTO PeriodCacheTemperature(EDISID,[Date],CategoryID,TotalDispense,InSpec,InTolerance,OutSpec)
SELECT EDISID, DATEADD(dd, -DATEPART(dw, TradingDay) + 1, TradingDay) AS Date, CategoryID, SUM(Pints) AS Total, SUM(InSpec) AS InSpec, SUM(InTolerance) AS InTolerance, SUM(OutSpec) AS OutSpec
FROM (
	SELECT ISNULL(PrimaryEDIS.PrimaryEDISID, DispenseActions.EDISID) AS EDISID, TradingDay, CategoryID, Pints,
			ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) AS Spec,
			ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance) AS Tolerance,
			CASE WHEN AverageTemperature <= (ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification)+ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance)) THEN Pints ELSE 0 END AS InSpec,
			CASE WHEN AverageTemperature > (ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification)+ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance)) AND MinimumTemperature <= (ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification)+ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance)+@AmberValue) THEN Pints ELSE 0 END AS InTolerance,
			CASE WHEN AverageTemperature > (ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification)+ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance)+@AmberValue) THEN Pints ELSE 0 END AS OutSpec
	FROM DispenseActions
	JOIN Products ON Products.ID = DispenseActions.Product
	LEFT JOIN #PrimaryEDIS AS PrimaryEDIS ON PrimaryEDIS.EDISID = DispenseActions.EDISID
	LEFT JOIN SiteProductSpecifications ON ISNULL(PrimaryEDIS.PrimaryEDISID, DispenseActions.EDISID) = SiteProductSpecifications.EDISID AND DispenseActions.Product = SiteProductSpecifications.ProductID
	JOIN Sites ON Sites.EDISID = DispenseActions.EDISID AND Sites.Quality = 1
	WHERE LiquidType = 2      
	AND NOT EXISTS
	(
		SELECT ID
		FROM ServiceIssuesQuality AS siq
		WHERE siq.DateFrom <= DispenseActions.[TradingDay]
		AND (siq.DateTo IS NULL OR siq.DateTo >= DispenseActions.[TradingDay])
		AND siq.RealEDISID = DispenseActions.EDISID
		AND siq.ProductID = DispenseActions.Product
	)
	AND Products.IsMetric = 0
	--AND CategoryID IN (SELECT ID FROM ProductCategories WHERE IncludeInEstateReporting = 1)
		AND Pints > 0.3
	AND (TradingDay BETWEEN DATEADD(dd, DATEPART(dw, 7-@FromDate)-1, @FromDate) AND DATEADD(dd, 7-DATEPART(dw, @ToDate), @ToDate))     ---- RN MOD: ...to get SARG predicate, giving the Query Optimiser a better chance, and also allowing it to use statistics.
		---- RN: changed from (DATEADD(dd, -DATEPART(dw, TradingDay) + 1, TradingDay) BETWEEN @FromDate AND @ToDate)      ------  OR (@FromDate IS NULL AND @ToDate IS NULL))   --- RN removed: same explanation as above.
) AS Dispense
GROUP BY EDISID, DATEADD(dd, -DATEPART(dw, TradingDay) + 1, TradingDay), CategoryID
---ORDER BY EDISID, DATEADD(dd, -DATEPART(dw, TradingDay) + 1, TradingDay), CategoryID   -------- RN removed: ORDER BY not need and hurts performance and memory use ....also, the PK on the PeriodCacheTemperature table orders it.
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[PeriodCacheTemperatureRebuild] TO PUBLIC
    AS [dbo];

