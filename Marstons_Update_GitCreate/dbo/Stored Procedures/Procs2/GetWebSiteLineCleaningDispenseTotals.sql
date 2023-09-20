
CREATE PROCEDURE [dbo].[GetWebSiteLineCleaningDispenseTotals] 
(
	@EDISID	INT,
	@From	DATETIME,
	@To		DATETIME
)
AS

SET NOCOUNT ON

--TESTING GUFF
--DECLARE @From 	DATETIME = '2011-08-01'
--DECLARE @To		DATETIME = '2011-09-04'
--DECLARE @EDISID		INT = 1471
--/TESTING GUFF

DECLARE @First AS INT
SET @First = 1
SET DATEFIRST @First

DECLARE @SiteOnline DATETIME
DECLARE @IsBQM BIT

SELECT @IsBQM = Quality, @SiteOnline = SiteOnline
FROM dbo.Sites
WHERE EDISID = @EDISID

--Merge secondarry systems
CREATE TABLE #PrimaryEDIS (PrimaryEDISID INT NOT NULL, EDISID INT NOT NULL, UNIQUE(PrimaryEDISID, EDISID) )
INSERT INTO #PrimaryEDIS
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
ORDER BY PrimaryEDISID

CREATE TABLE #LineCleans (EDISID INT, Pump INT, ProductID INT, LocationID INT, [Date] DATETIME, UNIQUE (EDISID, Pump, ProductID, LocationID, [Date]))


IF @IsBQM = 1
BEGIN
	INSERT INTO #LineCleans
	SELECT
		 DispenseActions.EDISID
		,DispenseActions.Pump
		,DispenseActions.Product AS ProductID
		,DispenseActions.Location AS LocationID
		,DispenseActions.TradingDay AS [Date]
	FROM
		DispenseActions
	JOIN PumpSetup 
		ON PumpSetup.EDISID = DispenseActions.EDISID
		AND PumpSetup.Pump = DispenseActions.Pump
		AND PumpSetup.ProductID = DispenseActions.Product
		AND PumpSetup.LocationID = DispenseActions.Location
	WHERE 
		DispenseActions.EDISID = @EDISID
		AND DispenseActions.TradingDay >= PumpSetup.ValidFrom
		AND (PumpSetup.ValidTo IS NULL OR DispenseActions.TradingDay <= PumpSetup.ValidTo)
		AND DispenseActions.LiquidType IN (3, 4)
	GROUP BY DispenseActions.EDISID, DispenseActions.Pump, DispenseActions.Product, DispenseActions.Location, DispenseActions.TradingDay
	ORDER BY EDISID, Pump, ProductID, LocationID, [Date]
END
ELSE
BEGIN
	INSERT INTO #LineCleans
	SELECT MasterDates.EDISID,
		 PumpSetup.Pump,
		 PumpSetup.ProductID,
		 PumpSetup.LocationID,
		 MasterDates.[Date]
	FROM CleaningStack
	JOIN MasterDates ON MasterDates.ID = CleaningStack.CleaningID AND EDISID = @EDISID
	JOIN Sites ON Sites.EDISID = MasterDates.EDISID
	JOIN PumpSetup ON MasterDates.EDISID = PumpSetup.EDISID
			AND CleaningStack.Line = PumpSetup.Pump
         				AND MasterDates.[Date] >= PumpSetup.ValidFrom
			AND (MasterDates.[Date] <= PumpSetup.ValidTo OR PumpSetup.ValidTo IS NULL)
	GROUP BY MasterDates.EDISID,
		 PumpSetup.Pump,
		 PumpSetup.ProductID,
		 PumpSetup.LocationID,
		 MasterDates.[Date]
END

SELECT EDISID, 
	   SUM(Volume) AS Total,
	   SUM(CASE WHEN DATEDIFF(DAY, CleanDate, TradingDay) < DaysBeforeAmber THEN Volume ELSE 0 END) AS CleanQuantity, 
	   SUM(CASE WHEN DATEDIFF(DAY, CleanDate, TradingDay) BETWEEN DaysBeforeAmber AND DaysBeforeRed THEN Volume ELSE 0 END) AS InToleranceQuantity,
	   SUM(CASE WHEN DATEDIFF(DAY, CleanDate, TradingDay) > DaysBeforeRed OR CleanDate IS NULL THEN Volume ELSE 0 END) AS DirtyQuantity
FROM (
	SELECT ISNULL(PrimaryEDIS.PrimaryEDISID, DispenseActions.EDISID) AS EDISID,
		   DispenseActions.StartTime,
		   DispenseActions.TradingDay,
		   DispenseActions.Product,
		   DispenseActions.Pump,
		   DispenseActions.Location,
		   COALESCE(SiteProductSpecifications.CleanDaysBeforeAmber, SiteSpecifications.CleanDaysBeforeAmber, Products.LineCleanDaysBeforeAmber) AS DaysBeforeAmber,
		   COALESCE(SiteProductSpecifications.CleanDaysBeforeRed, SiteSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed) AS DaysBeforeRed,
		   DispenseActions.Pints AS Volume,
		   MAX(LineCleans.[Date]) AS CleanDate
	FROM DispenseActions AS DispenseActions
	JOIN Products ON Products.[ID] = DispenseActions.Product
	LEFT JOIN #PrimaryEDIS AS PrimaryEDIS ON PrimaryEDIS.EDISID = DispenseActions.EDISID
	LEFT JOIN #LineCleans AS LineCleans ON LineCleans.EDISID = DispenseActions.EDISID
										AND LineCleans.[Date] <= DispenseActions.TradingDay
										AND LineCleans.ProductID = DispenseActions.Product
										AND LineCleans.Pump = DispenseActions.Pump
										AND LineCleans.LocationID = DispenseActions.Location
	LEFT JOIN SiteProductSpecifications ON (DispenseActions.Product = SiteProductSpecifications.ProductID AND DispenseActions.EDISID = SiteProductSpecifications.EDISID)
	LEFT JOIN SiteSpecifications ON DispenseActions.EDISID = SiteSpecifications.EDISID
	WHERE Products.IsMetric = 0
	AND DispenseActions.TradingDay BETWEEN @From AND @To 
	AND DispenseActions.EDISID = @EDISID
	AND DispenseActions.TradingDay >= @SiteOnline
	GROUP BY ISNULL(PrimaryEDIS.PrimaryEDISID, DispenseActions.EDISID),
		   DispenseActions.TradingDay,
		   DispenseActions.StartTime,
		   DispenseActions.Product,
		   DispenseActions.Pump,
		   DispenseActions.Location,
		   COALESCE(SiteProductSpecifications.CleanDaysBeforeAmber, SiteSpecifications.CleanDaysBeforeAmber, Products.LineCleanDaysBeforeAmber),
		   COALESCE(SiteProductSpecifications.CleanDaysBeforeRed, SiteSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed),
		   DispenseActions.Pints

) AS Dispense
GROUP BY EDISID
ORDER BY EDISID

DROP TABLE #LineCleans
DROP TABLE #PrimaryEDIS

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteLineCleaningDispenseTotals] TO PUBLIC
    AS [dbo];

