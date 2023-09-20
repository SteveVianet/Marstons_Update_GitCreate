CREATE PROCEDURE [dbo].[GetSiteLineCleaningSummary]
(
    @EDISID INT,
    @From DATE,
    @To DATE,
    @ShowInUseLinesOnly BIT = 1,
    @ShowProductOnly BIT = 0
)
AS

--DECLARE    @EDISID INT = 9531
--DECLARE    @From DATE = '2018-01-11'
--DECLARE    @To DATE = '2018-01-11'
--DECLARE    @ShowInUseLinesOnly BIT = 1
--DECLARE    @ShowProductOnly BIT = 1


DECLARE    @LocalEDISID INT = @EDISID
DECLARE    @LocalFrom DATE = @From
DECLARE    @LocalTo DATE = @To
DECLARE    @LocalShowInUseLinesOnly BIT = @ShowInUseLinesOnly

SET NOCOUNT ON
SET DATEFIRST 1

DECLARE @IgnoreLocalTime BIT = 0

DECLARE @Sites TABLE(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
DECLARE @SitePumpCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL PRIMARY KEY, PumpOffset INT NOT NULL)
DECLARE @PreviousCleans TABLE(EDISID INT NOT NULL, Pump INT NOT NULL, ProductID INT NOT NULL, LocationID INT NOT NULL, MaxCleaned DATETIME NOT NULL)
 
DECLARE @AllSitePumps TABLE(EDISID INT NOT NULL, SitePump INT NOT NULL,
			    	 PumpID INT NOT NULL, LocationID INT NOT NULL, ProductID INT NOT NULL,
			    	 ValidFrom DATETIME NOT NULL, ValidTo DATETIME NOT NULL,
                     DaysBeforeAmber INT NOT NULL, DaysBeforeRed INT NOT NULL,  
					 PreviousClean DATETIME NOT NULL, PreviousPumpClean DATETIME NOT NULL)

DECLARE @SiteGroupID INT
DECLARE @SiteOnline DATETIME
DECLARE @IsIDraught BIT

IF YEAR(@LocalFrom) <= 1900
BEGIN
	SET @LocalFrom = GETDATE()
END

IF YEAR(@LocalTo) <= 1900
BEGIN
	SET @LocalTo = GETDATE()
END

SELECT @IsIDraught = Quality, @SiteOnline = SiteOnline
FROM dbo.Sites
WHERE EDISID = @LocalEDISID

-- Find out which EDISIDs are relevant (plough through SiteGroups)
INSERT INTO @Sites
(EDISID)
SELECT EDISID
FROM Sites
WHERE EDISID = @LocalEDISID
 
SELECT @SiteGroupID = SiteGroupID
FROM SiteGroupSites
JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
WHERE TypeID = 1 AND EDISID = @LocalEDISID
 
INSERT INTO @Sites (EDISID)
SELECT SiteGroupSites.EDISID
FROM SiteGroupSites
JOIN Sites ON Sites.EDISID = SiteGroupSites.EDISID
WHERE SiteGroupSites.SiteGroupID = @SiteGroupID AND SiteGroupSites.EDISID <> @LocalEDISID
 
-- Get pumps for secondary sites (note that 1st EDISID IN @Sites is primary site)
INSERT INTO @SitePumpCounts (EDISID, MaxPump)
SELECT PumpSetup.EDISID, MAX(Pump)
FROM PumpSetup
JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
WHERE (ValidFrom <= @LocalTo)
AND (ISNULL(ValidTo, @LocalTo) >= @LocalFrom)
AND (ISNULL(ValidTo, @LocalTo) >= @SiteOnline)
GROUP BY PumpSetup.EDISID, Sites.CellarID
ORDER BY CellarID

INSERT INTO @SitePumpOffsets (EDISID, PumpOffset)
SELECT MainCounts.EDISID, COALESCE(QuaternaryCounts.MaxPump+TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, 
SecondaryCounts.MaxPump, 0)
FROM @SitePumpCounts AS MainCounts
LEFT JOIN @SitePumpCounts AS SecondaryCounts ON SecondaryCounts.Counter+1 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS TertiaryCounts ON TertiaryCounts.Counter+2 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS QuaternaryCounts ON QuaternaryCounts.Counter+3 = MainCounts.Counter


IF @IsIDraught = 1
	BEGIN

	INSERT INTO @PreviousCleans
	(EDISID, Pump, ProductID, LocationID, MaxCleaned)
	SELECT MasterDates.EDISID,
		 PumpSetup.Pump,
		 PumpSetup.ProductID,
		 PumpSetup.LocationID,
		 MAX(CASE WHEN DATEPART(HOUR, CleaningStack.[Time]) < 5 THEN DATEADD(DAY, -1, MasterDates.[Date]) ELSE MasterDates.[Date] END)
	FROM CleaningStack
	JOIN MasterDates ON MasterDates.ID = CleaningStack.CleaningID
    JOIN @Sites AS S ON MasterDates.EDISID = S.EDISID
	JOIN PumpSetup ON MasterDates.EDISID = PumpSetup.EDISID
			AND CleaningStack.Line = PumpSetup.Pump
					 AND MasterDates.[Date] >= PumpSetup.ValidFrom
			AND (MasterDates.[Date] <= PumpSetup.ValidTo OR PumpSetup.ValidTo IS NULL)
	WHERE MasterDates.[Date] <= @LocalFrom
	AND MasterDates.[Date] >= @SiteOnline
	GROUP BY MasterDates.EDISID,
		PumpSetup.Pump,
		PumpSetup.ProductID,
		PumpSetup.LocationID

	END
ELSE
	BEGIN

	INSERT INTO @PreviousCleans
	(EDISID, Pump, ProductID, LocationID, MaxCleaned)

	SELECT EDISID,
		   Pump,
		   ProductID,
		   LocationID,
		   MAX(CASE WHEN DATEPART(HOUR, [Date]) < 5 THEN DATEADD(DAY, -1, CAST([Date] AS DATE)) ELSE CAST([Date] AS DATE) END)
	FROM (
		SELECT MasterDates.EDISID,
			 PumpSetup.Pump,
			 PumpSetup.ProductID,
			 PumpSetup.LocationID,
			 DATEADD(HOUR, DATEPART(HOUR, WaterStack.[Time]), MasterDates.[Date]) AS [Date]
		FROM WaterStack
		JOIN MasterDates ON MasterDates.ID = WaterStack.WaterID
        JOIN @Sites AS S ON MasterDates.EDISID = S.EDISID
		JOIN PumpSetup ON MasterDates.EDISID = PumpSetup.EDISID
				AND WaterStack.Line = PumpSetup.Pump
						 AND MasterDates.[Date] >= PumpSetup.ValidFrom
				AND (MasterDates.[Date] <= PumpSetup.ValidTo OR PumpSetup.ValidTo IS NULL)
		WHERE MasterDates.[Date] <= @LocalFrom
		AND MasterDates.[Date] >= @SiteOnline
		GROUP BY MasterDates.EDISID,
			PumpSetup.Pump,
			PumpSetup.ProductID,
			PumpSetup.LocationID,
			MasterDates.[Date],
			WaterStack.[Time]
		HAVING SUM(WaterStack.Volume) > 4
	) AS PossibleCleans
	GROUP BY EDISID, Pump, ProductID, LocationID
	
	END

INSERT INTO @AllSitePumps (EDISID, SitePump, PumpID, LocationID, ProductID, ValidFrom, ValidTo, DaysBeforeAmber, DaysBeforeRed, PreviousClean, PreviousPumpClean)
SELECT	PumpSetup.EDISID, PumpSetup.Pump,
	PumpSetup.Pump+PumpOffset, PumpSetup.LocationID, PumpSetup.ProductID,
	PumpSetup.ValidFrom,
	ISNULL(PumpSetup.ValidTo, @LocalTo),
	COALESCE(SiteProductSpecifications.CleanDaysBeforeAmber, SiteSpecifications.CleanDaysBeforeAmber, Products.LineCleanDaysBeforeAmber),
	COALESCE(SiteProductSpecifications.CleanDaysBeforeRed, SiteSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed),
	ISNULL(PreviousCleans.MaxCleaned, 0) AS PreviousClean,
	ISNULL(PreviousPumpCleans.MaxCleaned, 0) AS PreviousPumpClean
FROM PumpSetup
JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = PumpSetup.EDISID
JOIN Products ON Products.[ID] = PumpSetup.ProductID
LEFT JOIN SiteProductSpecifications ON SiteProductSpecifications.EDISID = PumpSetup.EDISID
				   AND SiteProductSpecifications.ProductID = PumpSetup.ProductID
LEFT JOIN SiteSpecifications ON Sites.EDISID = SiteSpecifications.EDISID
LEFT JOIN @PreviousCleans AS PreviousCleans ON PreviousCleans.EDISID = PumpSetup.EDISID 
        					          AND PreviousCleans.Pump = PumpSetup.Pump 
					          AND PreviousCleans.ProductID = PumpSetup.ProductID
					          AND PreviousCleans.LocationID = PumpSetup.LocationID
LEFT JOIN 
(
	SELECT EDISID, Pump, MAX(MaxCleaned) AS MaxCleaned
	FROM @PreviousCleans
	GROUP BY EDISID, Pump 
) AS PreviousPumpCleans ON PreviousPumpCleans.EDISID = PumpSetup.EDISID 
        										AND PreviousPumpCleans.Pump = PumpSetup.Pump 
WHERE (ValidFrom <= @LocalTo)
AND (ISNULL(ValidTo, @LocalTo) >= @LocalFrom)
AND (ISNULL(ValidTo, @LocalTo) >= @SiteOnline)
AND Products.IsWater = 0
AND (InUse = 1 OR @LocalShowInUseLinesOnly = 0)

DECLARE @CleaningSetup TABLE (
    EDISID INT NOT NULL, 
    Pump INT NOT NULL, 
    Product VARCHAR(1000) NOT NULL, 
    DaysBeforeAmber INT NOT NULL, 
    DaysBeforeRed INT NOT NULL,
    PreviousClean DATETIME)

INSERT INTO @CleaningSetup
SELECT	PumpSetup.EDISID,
		PumpSetup.PumpID AS Pump,
		Products.[Description] AS Product, 
        --PumpSetup.LocationID, 
		--Locations.[Description] AS Location,
		--ProductDistributors.ShortName AS Distributor,
		--CASE WHEN PumpSetup.ValidFrom < @SiteOnline THEN @SiteOnline ELSE PumpSetup.ValidFrom END AS ValidFrom,
		--CASE WHEN ISNULL(PumpSetup.ValidTo, @LocalTo) < @SiteOnline THEN @SiteOnline ELSE ISNULL(PumpSetup.ValidTo, @LocalTo) END AS ValidTo,
		PumpSetup.DaysBeforeAmber,
		PumpSetup.DaysBeforeRed,
		PumpSetup.PreviousClean
		--PumpSetup.PreviousPumpClean
		--Products.IsMetric,
		--PumpSetup.SitePump AS RealPumpID
FROM @AllSitePumps AS PumpSetup
JOIN Products ON Products.[ID] = PumpSetup.ProductID
JOIN ProductDistributors ON ProductDistributors.[ID] = Products.DistributorID
JOIN Locations ON Locations.[ID] = PumpSetup.LocationID

DECLARE @IsBQM BIT

SELECT @IsBQM = Quality, @SiteOnline = SiteOnline
FROM dbo.Sites
WHERE EDISID = @LocalEDISID

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
    PRINT 'BQM'
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
		DispenseActions.EDISID = @LocalEDISID
		AND DispenseActions.TradingDay >= PumpSetup.ValidFrom
		AND (PumpSetup.ValidTo IS NULL OR DispenseActions.TradingDay <= PumpSetup.ValidTo)
		AND DispenseActions.LiquidType IN (3, 4)
	GROUP BY DispenseActions.EDISID, DispenseActions.Pump, DispenseActions.Product, DispenseActions.Location, DispenseActions.TradingDay
	ORDER BY EDISID, Pump, ProductID, LocationID, [Date]
END
ELSE
BEGIN
    PRINT 'BMS'
	INSERT INTO #LineCleans
	SELECT MasterDates.EDISID,
		 PumpSetup.Pump,
		 PumpSetup.ProductID,
		 PumpSetup.LocationID,
		 MasterDates.[Date]
	FROM WaterStack
	JOIN MasterDates ON MasterDates.ID = WaterStack.WaterID AND EDISID = @LocalEDISID
	JOIN Sites ON Sites.EDISID = MasterDates.EDISID
	JOIN PumpSetup ON MasterDates.EDISID = PumpSetup.EDISID
			AND WaterStack.Line = PumpSetup.Pump
         				AND MasterDates.[Date] >= PumpSetup.ValidFrom
			AND (MasterDates.[Date] <= PumpSetup.ValidTo OR PumpSetup.ValidTo IS NULL)
    GROUP BY MasterDates.EDISID,
		 PumpSetup.Pump,
		 PumpSetup.ProductID,
		 PumpSetup.LocationID,
		 MasterDates.[Date]
    HAVING SUM(WaterStack.Volume) > 4
END

SELECT 
    [CleaningSetup].[EDISID],
    [CleaningSetup].[Pump],
    [Product],
    --[DaysBeforeAmber],
    --[DaysBeforeRed],
    [PreviousClean],
    CASE 
        WHEN @LocalFrom >= DATEADD(DAY, [DaysBeforeRed], [PreviousClean])
        THEN 2 -- Red
        WHEN @LocalFrom >= DATEADD(DAY, [DaysBeforeAmber], [PreviousClean])
        THEN 1 -- Amber
        ELSE 0 -- Green
    END AS [CleanState],
    ISNULL([Total], 0) AS [Dispense],
    --ISNULL([InToleranceQuantity], 0) AS [AmberQuantity],
    --ISNULL([DirtyQuantity], 0) AS [RedQuantity],
    ISNULL([DirtyQuantity], 0) AS [UncleanDispense]
FROM @CleaningSetup AS [CleaningSetup]
LEFT JOIN (
    SELECT EDISID, 
           Pump,
	       SUM(Volume) AS Total,
	       SUM(CASE WHEN DATEDIFF(DAY, CleanDate, TradingDay) < DaysBeforeAmber THEN Volume ELSE 0 END) AS CleanQuantity, 
	       SUM(CASE WHEN DATEDIFF(DAY, CleanDate, TradingDay) >= DaysBeforeAmber AND DATEDIFF(DAY, CleanDate, TradingDay) < DaysBeforeRed THEN Volume ELSE 0 END) AS InToleranceQuantity,
	       SUM(CASE WHEN DATEDIFF(DAY, CleanDate, TradingDay) >= DaysBeforeRed OR CleanDate IS NULL THEN Volume ELSE 0 END) AS DirtyQuantity
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
	    AND DispenseActions.TradingDay BETWEEN @LocalFrom AND @LocalTo 
	    AND DispenseActions.EDISID = @LocalEDISID
	    AND DispenseActions.TradingDay >= @SiteOnline
        AND (@ShowProductOnly = 0 OR DispenseActions.LiquidType IN (2, 3, 5))
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
    GROUP BY EDISID, Pump
    ) AS [Dispense] 
      ON [CleaningSetup].[EDISID] = [Dispense].[EDISID]
      AND [CleaningSetup].[Pump] = [Dispense].[Pump]
--ORDER BY [Pump]

DROP TABLE #LineCleans
DROP TABLE #PrimaryEDIS


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteLineCleaningSummary] TO PUBLIC
    AS [dbo];

