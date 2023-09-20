
CREATE PROCEDURE [dbo].[AddServiceIssueYield]
(
	@CallID				INT = 0,
	@PumpID				INT = 0,
	@ExcludeAllProducts	BIT = 0,
	@StartDate			DATETIME,
	@CallReasonTypeID	INT
)
AS

SET NOCOUNT ON

CREATE TABLE #Sites(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY, POSYieldCashValue FLOAT, CleaningCashValue FLOAT, PouringYieldCashValue FLOAT) 
CREATE TABLE #PrimaryProducts(ProductID INT NOT NULL, PrimaryProductID INT NOT NULL) 
CREATE TABLE #SitePumpCounts (Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
CREATE TABLE #SitePumpOffsets (EDISID INT NOT NULL, PumpOffset INT NOT NULL)

CREATE TABLE #AllSitePumps(PumpID INT NOT NULL, LocationID INT NOT NULL, ProductID INT NOT NULL,
				      DaysBeforeAmber INT NOT NULL, DaysBeforeRed INT NOT NULL,
				      ValidFrom DATETIME NOT NULL, ValidTo DATETIME NULL,
				      EDISID INT NOT NULL, RealPumpID INT NOT NULL, 
				      LastClean DATETIME, Dirty BIT DEFAULT 1,
				      DispenseFrom DATETIME, IsCask BIT, FlowRateSpecification FLOAT, 
				      FlowRateTolerance FLOAT, TemperatureSpecification FLOAT, TemperatureTolerance FLOAT)

DECLARE @EDISID INT
DECLARE @ProductID INT
DECLARE @PrimaryProductID INT
DECLARE @SiteGroupID INT
DECLARE @PrimaryEDISID INT

SELECT @EDISID = EDISID
FROM Calls
WHERE ID = @CallID

SELECT @ProductID = ProductID
FROM PumpSetup
WHERE EDISID = @EDISID 
AND Pump = @PumpID
AND ValidTo IS NULL

SET @PrimaryProductID = @ProductID

INSERT INTO #Sites (EDISID, POSYieldCashValue, CleaningCashValue, PouringYieldCashValue)
SELECT EDISID, POSYieldCashValue, CleaningCashValue, PouringYieldCashValue
FROM Sites
JOIN Owners ON Owners.ID = Sites.OwnerID
WHERE EDISID = @EDISID

SELECT @SiteGroupID = SiteGroupID
FROM SiteGroupSites
JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID WHERE TypeID = 1 AND EDISID = @EDISID

INSERT INTO #Sites (EDISID, POSYieldCashValue, CleaningCashValue, PouringYieldCashValue)
SELECT SiteGroupSites.EDISID, POSYieldCashValue, CleaningCashValue, PouringYieldCashValue
FROM SiteGroupSites
JOIN Sites ON Sites.EDISID = SiteGroupSites.EDISID
JOIN Owners ON Owners.ID = Sites.OwnerID
WHERE SiteGroupSites.SiteGroupID = @SiteGroupID 
AND SiteGroupSites.EDISID <> @EDISID

-- Get pumps for secondary sites (note that 1st EDISID IN #Sites is primary site)
INSERT INTO #SitePumpCounts (EDISID, MaxPump)
SELECT PumpSetup.EDISID, MAX(Pump)
FROM PumpSetup
JOIN #Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
WHERE (ValidTo IS NULL)
GROUP BY PumpSetup.EDISID, Sites.CellarID
ORDER BY CellarID

SELECT @PrimaryEDISID = MAX(PrimaryEDISID)
FROM(
	SELECT SiteGroupID, SiteGroupSites.EDISID AS PrimaryEDISID
	FROM SiteGroupSites 
	WHERE SiteGroupID IN (SELECT ID FROM SiteGroups WHERE TypeID = 1)
	AND IsPrimary = 1
	GROUP BY SiteGroupID, SiteGroupSites.EDISID
) AS PrimarySites
JOIN SiteGroupSites ON SiteGroupSites.SiteGroupID = PrimarySites.SiteGroupID
WHERE SiteGroupSites.EDISID = @EDISID
GROUP BY SiteGroupSites.EDISID

INSERT INTO #SitePumpOffsets (EDISID, PumpOffset)
SELECT MainCounts.EDISID, COALESCE(QuaternaryCounts.MaxPump+TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, SecondaryCounts.MaxPump, 0)
FROM #SitePumpCounts AS MainCounts
LEFT JOIN #SitePumpCounts AS SecondaryCounts ON SecondaryCounts.Counter+1 = MainCounts.Counter
LEFT JOIN #SitePumpCounts AS TertiaryCounts ON TertiaryCounts.Counter+2 = MainCounts.Counter
LEFT JOIN #SitePumpCounts AS QuaternaryCounts ON QuaternaryCounts.Counter+3 = MainCounts.Counter

INSERT INTO #AllSitePumps (PumpID, LocationID, ProductID, DaysBeforeAmber, DaysBeforeRed, ValidFrom, ValidTo, EDISID, RealPumpID, IsCask, FlowRateSpecification, FlowRateTolerance, TemperatureSpecification, TemperatureTolerance)
SELECT Pump+PumpOffset, LocationID, PumpSetup.ProductID,
	COALESCE(SiteProductSpecifications.CleanDaysBeforeAmber, SiteSpecifications.CleanDaysBeforeAmber, Products.LineCleanDaysBeforeAmber),
	COALESCE(SiteProductSpecifications.CleanDaysBeforeRed, SiteSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed),
	ValidFrom,
	ValidTo,
	Sites.EDISID,
	PumpSetup.Pump,
	Products.IsCask,
	ISNULL(SiteProductSpecifications.FlowSpec, Products.FlowRateSpecification),
	ISNULL(SiteProductSpecifications.FlowTolerance, Products.FlowRateTolerance),
	ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification),
	ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance)
FROM PumpSetup
JOIN #Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
JOIN #SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = PumpSetup.EDISID
JOIN Products ON Products.[ID] = PumpSetup.ProductID
LEFT JOIN SiteProductSpecifications ON Products.ID = SiteProductSpecifications.ProductID AND PumpSetup.EDISID = SiteProductSpecifications.EDISID
LEFT JOIN SiteSpecifications ON Sites.EDISID = SiteSpecifications.EDISID
WHERE (ValidTo IS NULL)
AND Products.IsWater = 0
AND Products.IsMetric = 0

INSERT INTO #PrimaryProducts
(ProductID, PrimaryProductID)
SELECT ProductID, ProductGroupPrimaries.PrimaryProductID
FROM ProductGroupProducts
JOIN ProductGroups ON ProductGroups.ID = ProductGroupProducts.ProductGroupID
JOIN (
      SELECT ProductGroupID, ProductID AS PrimaryProductID
      FROM ProductGroupProducts
      JOIN ProductGroups ON ProductGroups.ID = ProductGroupProducts.ProductGroupID
      WHERE TypeID = 1 AND IsPrimary = 1
) AS ProductGroupPrimaries ON ProductGroupPrimaries.ProductGroupID = ProductGroups.ID
WHERE TypeID = 1 AND IsPrimary = 0

SELECT @PrimaryProductID = PrimaryProductID
FROM #PrimaryProducts
WHERE ProductID = @ProductID

INSERT INTO dbo.ServiceIssuesYield
(EDISID, CallID, ProductID, PrimaryProductID, DateFrom, DateTo, RealEDISID, CallReasonTypeID)
SELECT	ISNULL(@PrimaryEDISID, @EDISID) AS EDISID,
		@CallID AS CallID,
		PumpSetup.ProductID,
		ISNULL(PrimaryProducts.PrimaryProductID, PumpSetup.ProductID) AS PrimaryProductID,
		@StartDate AS DateFrom,
		NULL AS DateTo,
		Sites.EDISID AS RealEDISID,
		@CallReasonTypeID AS CallReasonTypeID
FROM #AllSitePumps AS PumpSetup
JOIN #Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
LEFT OUTER JOIN #PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = PumpSetup.ProductID
LEFT JOIN ServiceIssuesYield AS CurrentIssues ON CurrentIssues.EDISID = @EDISID
												AND CurrentIssues.CallID = @CallID
												AND CurrentIssues.ProductID = PumpSetup.ProductID
												AND CurrentIssues.PrimaryProductID = ISNULL(PrimaryProducts.PrimaryProductID, PumpSetup.ProductID)
WHERE CurrentIssues.EDISID IS NULL
AND ValidTo IS NULL
AND (ISNULL(PrimaryProducts.PrimaryProductID, PumpSetup.ProductID) = @PrimaryProductID OR @ExcludeAllProducts = 1)
GROUP BY PumpSetup.ProductID,
		ISNULL(PrimaryProducts.PrimaryProductID, PumpSetup.ProductID),
		Sites.EDISID

DROP TABLE #Sites
DROP TABLE #PrimaryProducts
DROP TABLE #SitePumpCounts
DROP TABLE #SitePumpOffsets
DROP TABLE #AllSitePumps

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddServiceIssueYield] TO PUBLIC
    AS [dbo];

