CREATE PROCEDURE [neo].[GetUserLineCleaningSummary]
(
    @UserID INT,
    @From DATE,
    @To DATE,
    @ShowInUseLinesOnly BIT = 1
)
AS

DECLARE    @LocalUserID INT = @UserID
DECLARE    @LocalFrom DATE = @From
DECLARE    @LocalTo DATE = @To
DECLARE    @LocalShowInUseLinesOnly BIT = @ShowInUseLinesOnly

--DECLARE @UserID INT = 1003 -- 36 sites
--DECLARE @UserID INT = 21166 -- 40 sites  /w  multi-cellar
--DECLARE @UserID INT = 21304 -- 42 Sites  /w  multi-cellar
--DECLARE @LocalFrom DATE = '2015-06-08'
--DECLARE @LocalTo DATE = '2015-06-08'
--DECLARE @LocalShowInUseLinesOnly BIT = 1

SET NOCOUNT ON

DECLARE @Sites TABLE([EDISID] INT NOT NULL PRIMARY KEY, [IsIDraught] BIT NOT NULL, [SiteOnline] DATE, [SiteGroupID] INT, [IsPrimary] BIT, [MaxPump] INT, [CellarID] INT NOT NULL IDENTITY(1,1))
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL PRIMARY KEY, PumpOffset INT NOT NULL)
DECLARE @PreviousCleans TABLE([EDISID] INT NOT NULL, [Pump] INT NOT NULL, [ProductID] INT NOT NULL, [LocationID] INT NOT NULL, [MaxCleaned] DATETIME NOT NULL)
DECLARE @PrimaryProducts TABLE(ProductID INT NOT NULL, PrimaryProductID INT NOT NULL)

DECLARE @AllSitePumps TABLE(
    EDISID INT NOT NULL, SitePump INT NOT NULL,
	PumpID INT, LocationID INT NOT NULL, ProductID INT NOT NULL,
	ValidFrom DATETIME NOT NULL, ValidTo DATETIME NOT NULL,
    DaysBeforeAmber INT NOT NULL, DaysBeforeRed INT NOT NULL,  
	PreviousClean DATETIME NOT NULL, PreviousPumpClean DATETIME NOT NULL)

DECLARE @CleaningSetup TABLE (
    EDISID INT NOT NULL, 
    Pump INT, 
	ProductID INT,
    Product VARCHAR(1000) NOT NULL, 
    DaysBeforeAmber INT NOT NULL, 
    DaysBeforeRed INT NOT NULL,
    PreviousClean DATETIME)

IF OBJECT_ID('tempdb.dbo.#LineCleans', 'U') IS NOT NULL
DROP TABLE #LineCleans

CREATE TABLE #LineCleans (EDISID INT, Pump INT, ProductID INT, LocationID INT, [Date] DATETIME, UNIQUE (EDISID, Pump, ProductID, LocationID, [Date]))

INSERT INTO @Sites ([EDISID], [IsIDraught], [SiteOnline], [IsPrimary], [SiteGroupID])
SELECT 
    [US].[EDISID],
    [S].[Quality],
    [S].[SiteOnline],
    [SGS].[IsPrimary],
    [SG].[ID]    
FROM [UserSites] 
  AS [US]
JOIN [Sites] 
  AS [S] ON [US].[EDISID] = [S].[EDISID]
LEFT JOIN [SiteGroupSites]
  AS [SGS] ON [US].[EDISID] = [SGS].[EDISID]
LEFT JOIN [SiteGroups]
  AS [SG] ON [SGS].[SiteGroupID] = [SG].[ID]
WHERE
    [US].[UserID] = @LocalUserID
--AND ([SG].[TypeID] IS NULL OR [SG].[TypeID] = 1) -- Single-Cellar or Multi-Cellar
AND [S].[Hidden] = 0
ORDER BY [SiteID]

--SELECT *
--FROM @Sites
--ORDER BY [SiteGroupID], [CellarID]

-- Unroll ProductGroups so we can work out how to transform ProductIDs to their primaries
INSERT INTO @PrimaryProducts
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

IF EXISTS (
    SELECT * 
    FROM @Sites 
      AS [S]
    JOIN [SiteGroupSites]
      AS [SGS] ON [S].[EDISID] = [SGS].[EDISID]
    JOIN [SiteGroups]
      AS [SG] ON [SGS].[SiteGroupID] = [SG].[ID]
    WHERE
        [SG].[TypeID] = 1
)
BEGIN
    /* Include multi-cellar sites which may not be assigned to the User directly */
    INSERT INTO @Sites
        ([EDISID], [IsIDraught], [SiteOnline], [IsPrimary], [SiteGroupID])
    SELECT 
        [SGS].[EDISID],
        [Ss].[Quality],
        [Ss].[SiteOnline],
        [SGS].[IsPrimary],
        [SGS].[SiteGroupID]
    FROM [SiteGroupSites] 
      AS [SGS]
    JOIN [Sites]
      AS [Ss] ON [SGS].[EDISID] = [Ss].[EDISID]
    LEFT JOIN @Sites 
      AS [S] ON [SGS].[EDISID] = [S].[EDISID]
    WHERE
        [SGS].[SiteGroupID] IN (
            SELECT 
                [SG].[ID]
            FROM [SiteGroups]
                AS [SG]
            JOIN [SiteGroupSites]
                AS [SGS] ON [SG].[ID] = [SGS].[SiteGroupID]
            JOIN @Sites 
                AS [S] ON [SGS].[EDISID] = [S].[EDISID]
            WHERE
                [SG].[TypeID] = 1
            )
    AND [S].[EDISID] IS NULL
    AND [Ss].[Hidden] = 0
    ORDER BY 
        [Ss].[SiteID]
END

--SELECT *
--FROM @Sites [S]
--JOIN Sites [Ss] ON [S].[EDISID] = [Ss].[EDISID]
--ORDER BY [S].[SiteGroupID], [CellarID]

-- Get pumps for secondary sites (note that 1st EDISID IN @Sites is primary site)
UPDATE @Sites
SET [MaxPump] = [Pumps]
FROM @Sites AS [S]
JOIN (
    SELECT 
        [PumpSetup].[EDISID], 
        MAX([Pump]) AS [Pumps]
    FROM [PumpSetup]
    JOIN @Sites AS [Sites] ON [Sites].[EDISID] = [PumpSetup].[EDISID]
    WHERE ([ValidFrom] <= @LocalTo)
    AND (ISNULL([ValidTo], @LocalTo) >= @LocalFrom)
    AND (ISNULL([ValidTo], @LocalTo) >= [Sites].[SiteOnline])
    GROUP BY [PumpSetup].[EDISID], [Sites].[CellarID]
    --ORDER BY [CellarID]
    ) 
    AS [SitePumps]
    ON [S].[EDISID] = [SitePumps].[EDISID]

--SELECT * 
--FROM @Sites

-- Handle Sites with no grouping involved
INSERT INTO @SitePumpOffsets ([EDISID], [PumpOffset])
SELECT [S].[EDISID], 0
FROM @Sites AS [S]
WHERE 
    [SiteGroupID] IS NULL
OR ([SiteGroupID] IS NOT NULL AND [IsPrimary] = 1)

-- Handle "multi-cellar" Sites
;WITH [MultiCellar] AS (
    --Anchor Block
    SELECT 
        [EDISID], 
        [SiteGroupID], 
        [IsPrimary],
        [CellarID],
        [Pumps],
        0 AS [Offset]
    FROM (
        SELECT 
            [S].[EDISID], 
            [S].[SiteGroupID], 
            [S].[IsPrimary],
            [S].[CellarID],
            [S].[MaxPump] AS [Pumps]
        FROM @Sites 
          AS [S]
        WHERE [SiteGroupID] IS NOT NULL
        AND [IsPrimary] = 1
    ) AS [MultiCellarSites]

    UNION ALL

    --Recursive Block
    SELECT 
        [MCS].[EDISID], 
        [MCS].[SiteGroupID], 
        [MCS].[IsPrimary],
        [MCS].[CellarID],
        [MCS].[Pumps],
        [MC].[Pumps] AS [Offset]
    FROM (
        SELECT 
            [S].[EDISID], 
            [S].[SiteGroupID], 
            [S].[IsPrimary],
            [S].[CellarID],
            [S].[MaxPump] AS [Pumps]
        FROM @Sites 
          AS [S]
        WHERE [SiteGroupID] IS NOT NULL
        ) AS [MCS]
    INNER JOIN [MultiCellar] AS [MC] 
        ON [MCS].[SiteGroupID] = [MC].[SiteGroupID]
        AND [MCS].[CellarID] > [MC].[CellarID]
)
INSERT INTO @SitePumpOffsets ([EDISID], [PumpOffset])
SELECT 
    [EDISID], 
    --[SiteGroupID], 
    --[IsPrimary],
    --[CellarID],
    --[Pumps],
    SUM([Offset]) AS [Offset]
FROM [MultiCellar]
WHERE [IsPrimary] = 0
GROUP BY 
    [EDISID], 
    [SiteGroupID], 
    [IsPrimary],
    [CellarID],
    [Pumps]
ORDER BY [SiteGroupID], [CellarID]

--SELECT *
--FROM @SitePumpOffsets

/* IDraught Sites */
IF EXISTS (SELECT TOP 1 * FROM @Sites WHERE [IsIDraught] = 1)
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
    AND MasterDates.[Date] >= S.SiteOnline
    AND S.IsIDraught = 1
    GROUP BY MasterDates.EDISID,
	    PumpSetup.Pump,
	    PumpSetup.ProductID,
	    PumpSetup.LocationID
END

/* BMS Sites */
IF EXISTS (SELECT TOP 1 * FROM @Sites WHERE [IsIDraught] = 0)
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
	    AND MasterDates.[Date] >= [S].[SiteOnline]
        AND [S].[IsIDraught] = 0
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

--SELECT *
--FROM @PreviousCleans [PC]
--JOIN @SitePumpOffsets [SPO] ON [PC].[EDISID] = [SPO].[EDISID]
--JOIN @Sites [S] ON [PC].[EDISID] = [S].[EDISID]
--ORDER BY [S].[SiteGroupID], [S].[CellarID], [Pump]

INSERT INTO @AllSitePumps (EDISID, SitePump, PumpID, LocationID, ProductID, ValidFrom, ValidTo, DaysBeforeAmber, DaysBeforeRed, PreviousClean, PreviousPumpClean)
SELECT	PumpSetup.EDISID, PumpSetup.Pump,
	PumpSetup.Pump+PumpOffset,
	 PumpSetup.LocationID, 
	 PumpSetup.ProductID,
	PumpSetup.ValidFrom,
	ISNULL(PumpSetup.ValidTo, @LocalTo),
	COALESCE(SiteProductSpecifications.CleanDaysBeforeAmber, SiteSpecifications.CleanDaysBeforeAmber, Products.LineCleanDaysBeforeAmber),
	COALESCE(SiteProductSpecifications.CleanDaysBeforeRed, SiteSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed),
	ISNULL(PreviousCleans.MaxCleaned, 0) AS PreviousClean,
	ISNULL(PreviousPumpCleans.MaxCleaned, 0) AS PreviousPumpClean
FROM PumpSetup
JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
LEFT JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = PumpSetup.EDISID
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
AND (ISNULL(ValidTo, @LocalTo) >= Sites.SiteOnline)
AND Products.IsWater = 0
AND (InUse = 1 OR @LocalShowInUseLinesOnly = 0)


INSERT INTO @CleaningSetup
SELECT	PumpSetup.EDISID,
		PumpSetup.PumpID AS Pump,
		Products.ID AS ProductID,
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

--SELECT *
--FROM @CleaningSetup

/* IDraught Sites */
IF EXISTS (SELECT TOP 1 * FROM @Sites WHERE [IsIDraught] = 1)
BEGIN
	INSERT INTO #LineCleans
	SELECT
		 DispenseActions.EDISID
		,DispenseActions.Pump
		,DispenseActions.Product AS ProductID
		,DispenseActions.Location AS LocationID
		,DispenseActions.TradingDay AS [Date]
	FROM DispenseActions
	JOIN PumpSetup 
		ON PumpSetup.EDISID = DispenseActions.EDISID
		AND PumpSetup.Pump = DispenseActions.Pump
		AND PumpSetup.ProductID = DispenseActions.Product
		AND PumpSetup.LocationID = DispenseActions.Location
    JOIN @Sites AS S
        ON S.EDISID = PumpSetup.EDISID
    JOIN @CleaningSetup AS CS
        ON CS.EDISID = S.EDISID
        AND CS.Pump = PumpSetup.Pump
	WHERE 
		DispenseActions.TradingDay >= PumpSetup.ValidFrom
	AND (PumpSetup.ValidTo IS NULL OR DispenseActions.TradingDay <= PumpSetup.ValidTo)
	AND DispenseActions.LiquidType IN (3, 4)
    AND DispenseActions.TradingDay >= DATEADD(DAY, -CS.DaysBeforeRed, @LocalFrom)
    AND S.IsIDraught = 1
	GROUP BY DispenseActions.EDISID, DispenseActions.Pump, DispenseActions.Product, DispenseActions.Location, DispenseActions.TradingDay
	ORDER BY EDISID, Pump, ProductID, LocationID, [Date]
END

/* BMS Sites */
IF EXISTS (SELECT TOP 1 * FROM @Sites WHERE [IsIDraught] = 0)
BEGIN
    INSERT INTO #LineCleans
	SELECT MasterDates.EDISID,
		 PumpSetup.Pump,
		 PumpSetup.ProductID,
		 PumpSetup.LocationID,
		 MasterDates.[Date]
	FROM CleaningStack
	JOIN MasterDates ON MasterDates.ID = CleaningStack.CleaningID
	JOIN PumpSetup ON MasterDates.EDISID = PumpSetup.EDISID
			AND CleaningStack.Line = PumpSetup.Pump
         				AND MasterDates.[Date] >= PumpSetup.ValidFrom
			AND (MasterDates.[Date] <= PumpSetup.ValidTo OR PumpSetup.ValidTo IS NULL)
    JOIN @Sites AS S
        ON S.EDISID = PumpSetup.EDISID
        AND S.EDISID = MasterDates.EDISID
    JOIN @CleaningSetup AS CS
        ON CS.EDISID = S.EDISID
        AND CS.Pump = PumpSetup.Pump
    WHERE
        MasterDates.[Date] >= DATEADD(DAY, -CS.DaysBeforeRed, @LocalFrom)
    AND S.IsIDraught = 0
	GROUP BY MasterDates.EDISID,
		 PumpSetup.Pump,
		 PumpSetup.ProductID,
		 PumpSetup.LocationID,
		 MasterDates.[Date]
END

/*
    Doesn't handle BMS Dispense
*/

SELECT 
    ISNULL([SGS].[EDISID], [CleaningSetup].[EDISID]) AS [EDISID],
	[CleaningSetup].[ProductID] AS [ChildProdID],
	COALESCE(pp.PrimaryProductID, [CleaningSetup].[ProductID]) AS [ProductID],
    [Product] AS [Description],
	MastProds.Description AS [Product],
    --[DaysBeforeAmber],
    --[DaysBeforeRed],
    --[PreviousClean],
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
    ISNULL([InToleranceQuantity], 0) + ISNULL([DirtyQuantity], 0) AS [UncleanDispense]
FROM @CleaningSetup AS [CleaningSetup]
JOIN @Sites AS S ON [CleaningSetup].EDISID = S.EDISID
LEFT JOIN @PrimaryProducts AS pp ON pp.ProductID = [CleaningSetup].[ProductID]
LEFT JOIN Products AS [MastProds] ON MastProds.ID = COALESCE(pp.PrimaryProductID, [CleaningSetup].[ProductID])
LEFT JOIN (
    SELECT 
        SiteGroupID, EDISID
    FROM SiteGroupSites
    WHERE IsPrimary = 1
    ) AS [SGS]
    ON S.[SiteGroupID] = [SGS].[SiteGroupID]
LEFT JOIN (
    SELECT EDISID, 
           Pump,
	       SUM(Volume) AS Total,
	       SUM(CASE WHEN DATEDIFF(DAY, CleanDate, TradingDay) < DaysBeforeAmber THEN Volume ELSE 0 END) AS CleanQuantity, 
	       SUM(CASE WHEN DATEDIFF(DAY, CleanDate, TradingDay) BETWEEN DaysBeforeAmber AND DaysBeforeRed THEN Volume ELSE 0 END) AS InToleranceQuantity,
	       SUM(CASE WHEN DATEDIFF(DAY, CleanDate, TradingDay) > DaysBeforeRed OR CleanDate IS NULL THEN Volume ELSE 0 END) AS DirtyQuantity
    FROM (
	    SELECT S.EDISID,
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
        JOIN @Sites AS S ON DispenseActions.EDISID = S.EDISID
	    --LEFT JOIN #PrimaryEDIS AS PrimaryEDIS ON PrimaryEDIS.EDISID = DispenseActions.EDISID
	    LEFT JOIN #LineCleans AS LineCleans ON LineCleans.EDISID = DispenseActions.EDISID
										    AND LineCleans.[Date] <= DispenseActions.TradingDay
										    AND LineCleans.ProductID = DispenseActions.Product
										    AND LineCleans.Pump = DispenseActions.Pump
										    AND LineCleans.LocationID = DispenseActions.Location
	    LEFT JOIN SiteProductSpecifications ON (DispenseActions.Product = SiteProductSpecifications.ProductID AND DispenseActions.EDISID = SiteProductSpecifications.EDISID)
	    LEFT JOIN SiteSpecifications ON DispenseActions.EDISID = SiteSpecifications.EDISID
	    WHERE Products.IsMetric = 0
	    AND DispenseActions.TradingDay BETWEEN @LocalFrom AND @LocalTo 
	    --AND DispenseActions.EDISID = @LocalEDISID
	    AND DispenseActions.TradingDay >= S.SiteOnline
	    GROUP BY 
               S.EDISID,
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
ORDER BY 
    [EDISID]

DROP TABLE #LineCleans

GO
GRANT EXECUTE
    ON OBJECT::[neo].[GetUserLineCleaningSummary] TO PUBLIC
    AS [dbo];

