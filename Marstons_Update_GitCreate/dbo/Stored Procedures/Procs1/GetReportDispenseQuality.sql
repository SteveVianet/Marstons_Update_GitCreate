CREATE PROCEDURE [dbo].[GetReportDispenseQuality]
(
	@UserID					INT,
	@From					DATETIME,
	@To						DATETIME,
	@IncludeCasks			BIT = 1,
	@IncludeKegs			BIT = 1,
	@IncludeMetric			BIT = 1,
	@TemperatureAmberValue	FLOAT = 2,
	@UnderSpecIsInSpec		BIT = 1
)
AS

SET NOCOUNT ON

DECLARE	@InternalUserID					INT
DECLARE	@InternalFrom					DATETIME
DECLARE	@InternalTo						DATETIME
DECLARE	@InternalIncludeCasks			BIT
DECLARE	@InternalIncludeKegs			BIT
DECLARE	@InternalIncludeMetric			BIT
DECLARE	@InternalTemperatureAmberValue	FLOAT
DECLARE	@InternalUnderSpecIsInSpec		BIT

SET @InternalUserID = @UserID
SET @InternalFrom = @From
SET @InternalTo = @To
SET @InternalIncludeCasks = @IncludeCasks
SET @InternalIncludeKegs = @IncludeKegs
SET @InternalIncludeMetric = @IncludeMetric
SET @InternalTemperatureAmberValue = @TemperatureAmberValue
SET @InternalUnderSpecIsInSpec = @UnderSpecIsInSpec

/*
SET @InternalUserID = 79
SET @InternalFrom = '2017-06-09'
SET @InternalTo = '2017-06-15'
SET @InternalIncludeCasks = 1
SET @InternalIncludeKegs = 1
SET @InternalIncludeMetric = 1
SET @InternalTemperatureAmberValue = 2
SET @InternalUnderSpecIsInSpec = 1
*/

--DECLARE @SiteGroupID INT
--DECLARE @Today DATETIME
DECLARE @LowTemperatureSaneThreshold FLOAT
DECLARE @HighTemperatureSaneThreshold FLOAT

DECLARE @UserSites TABLE(EDISID INT NOT NULL)

CREATE TABLE #Sites ([EDISID] INT NOT NULL PRIMARY KEY, [IsIDraught] BIT NOT NULL, [SiteOnline] DATE, [SiteGroupID] INT, [IsPrimary] BIT, [MaxPump] INT, [CellarID] INT NOT NULL IDENTITY(1,1))
CREATE TABLE #SitePumpOffsets (EDISID INT NOT NULL PRIMARY KEY, PumpOffset INT NOT NULL)
CREATE TABLE #AllSitePumps (
    EDISID INT NOT NULL, SitePump INT NOT NULL,
	PumpID INT NOT NULL, LocationID INT NOT NULL, ProductID INT NOT NULL,
	ValidFrom DATETIME NOT NULL, ValidTo DATETIME NOT NULL,
    FlowRateSpecification FLOAT NOT NULL, FlowRateTolerance FLOAT NOT NULL,
    TemperatureSpecification FLOAT NOT NULL, TemperatureTolerance FLOAT NOT NULL)
    

SELECT @LowTemperatureSaneThreshold = CAST(PropertyValue AS FLOAT)
FROM Configuration
WHERE PropertyName = 'Low Sane Product Temperature'

SELECT @HighTemperatureSaneThreshold = CAST(PropertyValue AS FLOAT)
FROM Configuration
WHERE PropertyName = 'High Sane Product Temperature'

INSERT INTO #Sites ([EDISID], [IsIDraught], [SiteOnline], [IsPrimary], [SiteGroupID])
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
    [US].[UserID] = @InternalUserID
AND ([SG].[TypeID] IS NULL OR [SG].[TypeID] = 1) -- Single-Cellar or Multi-Cellar
AND [S].[Hidden] = 0
ORDER BY [SiteID]

IF EXISTS (
    SELECT * 
    FROM #Sites 
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
    INSERT INTO #Sites
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
    LEFT JOIN #Sites 
      AS [S] ON [SGS].[EDISID] = [S].[EDISID]
    WHERE
        [SGS].[SiteGroupID] IN (
            SELECT 
                [SG].[ID]
            FROM [SiteGroups]
                AS [SG]
            JOIN [SiteGroupSites]
                AS [SGS] ON [SG].[ID] = [SGS].[SiteGroupID]
            JOIN #Sites 
                AS [S] ON [SGS].[EDISID] = [S].[EDISID]
            WHERE
                [SG].[TypeID] = 1
            )
    AND [S].[EDISID] IS NULL
    AND [Ss].[Hidden] = 0
    ORDER BY 
        [Ss].[SiteID]
END


-- Get pumps for secondary sites (note that 1st EDISID IN @Sites is primary site)
UPDATE #Sites
SET [MaxPump] = [Pumps]
FROM #Sites AS [S]
JOIN (
    SELECT 
        [PumpSetup].[EDISID], 
        MAX([Pump]) AS [Pumps]
    FROM [PumpSetup]
    JOIN #Sites AS [Sites] ON [Sites].[EDISID] = [PumpSetup].[EDISID]
    WHERE ([ValidFrom] <= @InternalTo)
    AND (ISNULL([ValidTo], @InternalTo) >= @InternalFrom)
    AND (ISNULL([ValidTo], @InternalTo) >= [Sites].[SiteOnline])
    GROUP BY [PumpSetup].[EDISID], [Sites].[CellarID]
    --ORDER BY [CellarID]
    ) 
    AS [SitePumps]
    ON [S].[EDISID] = [SitePumps].[EDISID]


-- Handle Sites with no grouping involved
INSERT INTO #SitePumpOffsets ([EDISID], [PumpOffset])
SELECT [S].[EDISID], 0
FROM #Sites AS [S]
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
        FROM #Sites 
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
        FROM #Sites 
          AS [S]
        WHERE [SiteGroupID] IS NOT NULL
        ) AS [MCS]
    INNER JOIN [MultiCellar] AS [MC] 
        ON [MCS].[SiteGroupID] = [MC].[SiteGroupID]
        AND [MCS].[CellarID] > [MC].[CellarID]
)
INSERT INTO #SitePumpOffsets ([EDISID], [PumpOffset])
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




INSERT INTO #AllSitePumps (EDISID, SitePump, PumpID, LocationID, ProductID, ValidFrom, ValidTo, FlowRateSpecification, FlowRateTolerance, TemperatureSpecification, TemperatureTolerance)
SELECT	PumpSetup.EDISID, PumpSetup.Pump,
	PumpSetup.Pump+PumpOffset, PumpSetup.LocationID, PumpSetup.ProductID,
	PumpSetup.ValidFrom,
	ISNULL(PumpSetup.ValidTo, @InternalTo),
	ISNULL(SiteProductSpecifications.FlowSpec, Products.FlowRateSpecification),
	ISNULL(SiteProductSpecifications.FlowTolerance, Products.FlowRateTolerance),
	ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification),
	ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance)
FROM PumpSetup
JOIN #Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
JOIN #SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = PumpSetup.EDISID
JOIN Products ON Products.[ID] = PumpSetup.ProductID
LEFT JOIN SiteProductSpecifications ON SiteProductSpecifications.EDISID = PumpSetup.EDISID
				   AND SiteProductSpecifications.ProductID = PumpSetup.ProductID
LEFT JOIN SiteSpecifications ON Sites.EDISID = SiteSpecifications.EDISID
WHERE (ValidFrom <= @InternalTo)
AND (ISNULL(ValidTo, @InternalTo) >= @InternalFrom)
AND (ISNULL(ValidTo, @InternalTo) >= Sites.SiteOnline)
AND Products.IsWater = 0
--AND InUse = 1


SELECT
    [EDISID],
    SUM([Quantity]) * 19.2152 AS [Quantity],
    SUM([QuantityOutOfSpec]) * 19.2152 AS [QuantityOutOfSpec]
FROM (
    SELECT  AllSitePumps.EDISID AS EDISID,
            AllSitePumps.PumpID AS Pump,
		    Products.Description AS Product,
		    Products.Description + '  ' + CAST(AllSitePumps.PumpID AS VARCHAR) AS PumpAndProduct,
		    Locations.Description AS Location,
		    ISNULL(SUM(DispenseSummary.Quantity),0) AS Quantity,
		    ISNULL(SUM(DispenseSummary.QuantityInSpec),0) AS QuantityInSpec,
		    ISNULL(SUM(DispenseSummary.QuantityInAmber),0) AS QuantityInAmber,
		    ISNULL(SUM(DispenseSummary.QuantityOutOfSpec),0) AS QuantityOutOfSpec,
		    ISNULL(AVG(DispenseSummary.AverageFlowRate),0) AS AverageFlowRate,
		    MIN(AllSitePumps.FlowRateSpecification) AS FlowRateSpecification,
		    MIN(AllSitePumps.FlowRateTolerance) AS FlowRateTolerance,
		    MIN(AllSitePumps.TemperatureSpecification) AS TemperatureSpecification,
		    MIN(AllSitePumps.TemperatureTolerance) AS TemperatureTolerance,
		    ISNULL(AVG(DispenseSummary.AverageTemperature), 0) AS AverageTemperature
    FROM #AllSitePumps AS AllSitePumps
    LEFT JOIN (
	    SELECT  DispenseActions.EDISID,
			    TradingDay,
			    Pump,
			    Product AS ProductID,
			    Location AS LocationID,
			    SUM(Pints) AS Quantity,
			    SUM(CASE WHEN (AverageTemperature >= ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) - ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance) OR @InternalUnderSpecIsInSpec = 1)
				      AND AverageTemperature <= ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) + ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance) THEN Pints ELSE 0 END) AS QuantityInSpec,
			    SUM(CASE WHEN (AverageTemperature < ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) - ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance)
				      AND AverageTemperature >= ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) - ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance) - @InternalTemperatureAmberValue
				      AND @InternalUnderSpecIsInSpec = 0)
				      OR (AverageTemperature > ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) + ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance)
				      AND AverageTemperature <= ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) + ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance) + @InternalTemperatureAmberValue)
				     THEN Pints ELSE 0 END) AS QuantityInAmber,
			    SUM(CASE WHEN (AverageTemperature < ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) - ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance) - @InternalTemperatureAmberValue
				      AND @InternalUnderSpecIsInSpec = 0)
				      OR AverageTemperature > ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) + ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance) + @InternalTemperatureAmberValue THEN Pints ELSE 0 END) AS QuantityOutOfSpec,
			    ISNULL(AVG(Duration/dbo.fnConvertSiteDispenseVolume(DispenseActions.EDISID, Pints)),0) AS AverageFlowRate,
			    ISNULL(AVG(AverageTemperature), 0) AS AverageTemperature
	    FROM DispenseActions WITH (INDEX ([IX_DispenseActions_ForQuality]))
	    JOIN Products ON Products.[ID] = DispenseActions.Product
        JOIN #Sites AS Sites ON DispenseActions.EDISID = Sites.EDISID
	    LEFT JOIN SiteProductSpecifications ON SiteProductSpecifications.ProductID = DispenseActions.Product AND SiteProductSpecifications.EDISID = DispenseActions.EDISID
	    WHERE DispenseActions.EDISID IN (SELECT EDISID FROM #Sites) AND
		      TradingDay BETWEEN @InternalFrom AND @InternalTo AND
		      TradingDay >= Sites.SiteOnline AND
		      LiquidType = 2 AND
		      Pints >= 0.3 AND
		      Location IS NOT NULL AND
		      AverageTemperature IS NOT NULL AND
		      (AverageTemperature BETWEEN @LowTemperatureSaneThreshold AND @HighTemperatureSaneThreshold)
	    GROUP BY DispenseActions.EDISID,
			     TradingDay,
			     Pump,
			     Product,
			     Location

    ) AS DispenseSummary ON (AllSitePumps.EDISID = DispenseSummary.EDISID AND
						     AllSitePumps.SitePump = DispenseSummary.Pump AND
						     AllSitePumps.LocationID = DispenseSummary.LocationID AND
						     AllSitePumps.ProductID = DispenseSummary.ProductID AND
						     DispenseSummary.TradingDay BETWEEN AllSitePumps.ValidFrom AND AllSitePumps.ValidTo)
    JOIN Locations ON (Locations.ID = AllSitePumps.LocationID)
    JOIN Products ON (Products.ID = AllSitePumps.ProductID)
    LEFT JOIN SiteProductSpecifications ON (Products.ID = SiteProductSpecifications.ProductID AND DispenseSummary.EDISID = SiteProductSpecifications.EDISID)
    GROUP BY 
        AllSitePumps.EDISID,
        AllSitePumps.PumpID,
	    Products.Description,
	    Products.Description + '  ' + CAST(AllSitePumps.PumpID AS VARCHAR),
	    Locations.Description
) AS [QualityResults]
GROUP BY [EDISID]

DROP TABLE #Sites
DROP TABLE #SitePumpOffsets
DROP TABLE #AllSitePumps
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetReportDispenseQuality] TO PUBLIC
    AS [dbo];

