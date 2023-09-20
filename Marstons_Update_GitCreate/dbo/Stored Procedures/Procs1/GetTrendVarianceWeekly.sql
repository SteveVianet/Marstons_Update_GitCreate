CREATE PROCEDURE [dbo].[GetTrendVarianceWeekly]
(
    @EDISID         INT,
    @From           DATE,
    @To             DATE,
    @IncludeCasks   BIT,
    @IncludeKegs    BIT,
    @IncludeMetric  BIT,
    @OnlyTied       BIT = 1
)

AS

/* Values I used during testing */
--DECLARE @EDISID         INT = 1108
--DECLARE @From           DATE = '2015-12-21' --'2016-02-22'
--DECLARE @To             DATE = '2016-04-24' --'2016-02-28'
--DECLARE @IncludeCasks   BIT = 1
--DECLARE @IncludeKegs    BIT = 1
--DECLARE @IncludeMetric  BIT = 1
--DECLARE @OnlyTied       BIT = 0

/* Used GetWebSiteDeliveryVarianceWeekly as a base for the following */
SET NOCOUNT ON

-- Change the first day of the week to Monday (default is Sunday/7)
SET NOCOUNT ON

-- Change the first day of the week to Monday (default is Sunday/7)
SET DATEFIRST 1

DECLARE @ToGallons FLOAT = 0.125     -- {Pint Value} * @ToGallons
DECLARE @ToLitres FLOAT = 0.568261   -- {Pint Value} * @ToLitres

--Adjust Dates appropriately (Monday - Sunday)
SET @From = DATEADD(WEEK, DATEDIFF(WEEK, 0, @From), 0)
-- If To Date *IS NOT* a Sunday, select the previous Sunday
IF DATEPART(WEEKDAY, @To) <> 7
BEGIN
    SET @To = DATEADD(WEEK, DATEDIFF(WEEK,0, @To)-1, 6)
END


DECLARE @NonTrendFrom DATE = DATEADD(WEEK, -3, @From)
DECLARE @MinimumTrend INT = 5
DECLARE @Variance TABLE (
    [WeekCommencing] DATE NOT NULL, 
    [Product] VARCHAR(50) NOT NULL,
    [ProductCategory] VARCHAR(255) NOT NULL,
    [IsCask] BIT NOT NULL, 
    [IsKeg] BIT NOT NULL, 
    [IsMetric] BIT NOT NULL, 
    [Dispensed] FLOAT NOT NULL, 
    [Delivered] FLOAT NOT NULL, 
    [Variance] FLOAT NOT NULL, 
    [CumulativeVariance] FLOAT NOT NULL DEFAULT(0),
    [IsTied] BIT NOT NULL,
    [IsConsolidated] BIT NOT NULL DEFAULT(0), 
    [IsAdjusted] BIT NOT NULL DEFAULT (0),
    [Trending] BIT NOT NULL DEFAULT(0),
    [Trend] FLOAT,
    [TrendTotal] FLOAT,
    [ID] INT IDENTITY (1,1), -- Req. to work around SQL Server bug (https://support.microsoft.com/en-gb/kb/960770)
    UNIQUE CLUSTERED ([WeekCommencing], [Product])
    )

DECLARE @ProductTies TABLE (
    [ProductID] INT NOT NULL, 
    [IsTied] BIT NOT NULL
    UNIQUE CLUSTERED ([ProductID], [IsTied])
    )

/* **************************************************************************************************************************************************
   Product Ties

   We calculate what the correct Tie status for each product should be while taking into account and site specific overrides.
   As the existing software/reports have no concept of historical tie, we override the values stored in the PeriodCacheVariance table as 
   it's possible for it to have inconsistent results depending on the date ranges being refreshed versus those being reported on.
*/

INSERT INTO @ProductTies
    ([ProductID], [IsTied])
SELECT
    [P].[ID],
    COALESCE([SP].[Tied], [SPC].[Tied], [P].[Tied]) AS [Tied]
    --[P].[Tied] AS [ProductTied],
    --[SPC].[Tied] AS [SiteCategoryTied],
    --[SP].[Tied] AS [SiteProductTied]
FROM [dbo].[Products] AS [P]
LEFT JOIN [dbo].[SiteProductCategoryTies] AS [SPC] 
    ON [P].[CategoryID] = [SPC].[ProductCategoryID]
    AND [SPC].[EDISID] = @EDISID
LEFT JOIN [dbo].[SiteProductTies] AS [SP]
    ON [P].[ID] = [SP].[ProductID]
    AND [SP].[EDISID] = @EDISID
ORDER BY [P].[Description]

/* Product Ties
   **************************************************************************************************************************************************
*/


/* **************************************************************************************************************************************************
   Per-Product
*/

INSERT INTO @Variance
    ([WeekCommencing], [Product], [ProductCategory], [IsCask], [IsKeg], [IsMetric], [Dispensed], [Delivered], [Variance], [IsTied])
SELECT
    [PeriodCacheVariance].[WeekCommencing] AS [WeekCommencing], 
    [Products].[Description] AS [Product], 
    [ProductCategories].[Description] AS [Category],
	[Products].[IsCask] ,
    CASE WHEN [Products].[IsCask] = 0 AND [Products].[IsMetric] = 0 AND [Products].[IsWater] = 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS [IsKeg], 
	[Products].[IsMetric],
    CASE WHEN [Products].[IsMetric] = 0 THEN [PeriodCacheVariance].[Dispensed] * @ToGallons ELSE [PeriodCacheVariance].[Dispensed] * @ToLitres END AS [Dispensed],
	CASE WHEN [Products].[IsMetric] = 0 THEN [PeriodCacheVariance].[Delivered] * @ToGallons ELSE [PeriodCacheVariance].[Delivered] * @ToLitres END AS [Delivered],
	CASE WHEN [Products].[IsMetric] = 0 THEN [PeriodCacheVariance].[Variance] * @ToGallons ELSE [PeriodCacheVariance].[Variance] * @ToLitres END AS [Variance],
	[ProductTies].[IsTied]
FROM [PeriodCacheVariance]
JOIN [Products] ON [PeriodCacheVariance].[ProductID] = [Products].[ID]
JOIN [ProductCategories] ON [Products].[CategoryID] = [ProductCategories].[ID]
JOIN @ProductTies AS [ProductTies] ON [Products].[ID] = [ProductTies].[ProductID]
WHERE [PeriodCacheVariance].[EDISID] = @EDISID
    AND ([Products].[IsCask] = 0 OR @IncludeCasks = 1) 
    AND (CASE WHEN [Products].[IsCask] = 0 AND [Products].[IsMetric] = 0 AND [Products].[IsWater] = 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END = 1 OR @IncludeKegs = 1) 
    AND ([Products].[IsMetric] = 0 OR @IncludeMetric = 1)
    AND [PeriodCacheVariance].[WeekCommencing] BETWEEN @From AND @To
    AND (@OnlyTied = 0 OR (@OnlyTied = 1 AND [PeriodCacheVariance].[IsTied] = 1))

/* Per-Product
   **************************************************************************************************************************************************
*/


/* **************************************************************************************************************************************************
   Consolidated

   We add variance data for two new "fake" products for "Tied Consolidated Draught" (Cask, Keg) and "Tied Consolidated Post-Mix" (Metric).
   We mark these rows with the IsConsolidated column.
   IsCask/IsKeg cannot be trusted as the data for them is combined. IsMetric can be relied upon.
*/

-- Draught
INSERT INTO @Variance
    ([WeekCommencing], [Product], [ProductCategory], [IsCask], [IsKeg], [IsMetric], [Dispensed], [Delivered], [Variance], [IsTied], [IsConsolidated])
SELECT
    [PeriodCacheVariance].[WeekCommencing] AS [WeekCommencing], 
    'Tied Consolidated Draught' AS [Product], 
    'N/A' AS [Category],
	1 AS [IsCask],
    1 AS [IsKeg], 
	0 AS [IsMetric],
    SUM([PeriodCacheVariance].[Dispensed]) * @ToGallons AS [Dispensed],
	SUM([PeriodCacheVariance].[Delivered]) * @ToGallons AS [Delivered],
	SUM([PeriodCacheVariance].[Variance]) * @ToGallons AS [Variance],
	1 AS [IsTied],
    1 AS [IsConsolidated]
FROM [PeriodCacheVariance]
JOIN [Products] ON [PeriodCacheVariance].[ProductID] = [Products].[ID]
JOIN [ProductCategories] ON [Products].[CategoryID] = [ProductCategories].[ID]
JOIN @ProductTies AS [ProductTies] ON [Products].[ID] = [ProductTies].[ProductID]
WHERE [PeriodCacheVariance].[EDISID] = @EDISID
    AND [Products].[IsMetric] = 0
    AND [PeriodCacheVariance].[WeekCommencing] BETWEEN @From AND @To
    AND [ProductTies].[IsTied] = 1
GROUP BY
    [PeriodCacheVariance].[WeekCommencing]

-- Cask
INSERT INTO @Variance
    ([WeekCommencing], [Product], [ProductCategory], [IsCask], [IsKeg], [IsMetric], [Dispensed], [Delivered], [Variance], [IsTied], [IsConsolidated], [IsAdjusted])
SELECT
    [PeriodCacheVariance].[WeekCommencing] AS [WeekCommencing], 
    'Tied Consolidated Cask' AS [Product], 
    'N/A' AS [Category],
	1 AS [IsCask],
    0 AS [IsKeg], 
	0 AS [IsMetric],
    SUM([PeriodCacheVariance].[Dispensed]) * @ToGallons AS [Dispensed],
	SUM([PeriodCacheVariance].[Delivered]) * @ToGallons AS [Delivered],
	SUM([PeriodCacheVariance].[Variance]) * @ToGallons AS [Variance],
	1 AS [IsTied],
    1 AS [IsConsolidated],
    0 AS [IsAdjusted]
FROM [PeriodCacheVariance]
JOIN [Products] ON [PeriodCacheVariance].[ProductID] = [Products].[ID]
JOIN [ProductCategories] ON [Products].[CategoryID] = [ProductCategories].[ID]
JOIN @ProductTies AS [ProductTies] ON [Products].[ID] = [ProductTies].[ProductID]
WHERE [PeriodCacheVariance].[EDISID] = @EDISID
    AND [Products].[IsCask] = 1
    AND [Products].[IsMetric] = 0
    AND [PeriodCacheVariance].[WeekCommencing] BETWEEN @From AND @To
    AND [ProductTies].[IsTied] = 1
GROUP BY
    [PeriodCacheVariance].[WeekCommencing]

-- Cask -5%
INSERT INTO @Variance
    ([WeekCommencing], [Product], [ProductCategory], [IsCask], [IsKeg], [IsMetric], [Dispensed], [Delivered], [Variance], [IsTied], [IsConsolidated], [IsAdjusted])
SELECT
    [PeriodCacheVariance].[WeekCommencing] AS [WeekCommencing], 
    'Tied Consolidated Cask Minus 5%' AS [Product], 
    'N/A' AS [Category],
	1 AS [IsCask],
    0 AS [IsKeg], 
	0 AS [IsMetric],
    (SUM([PeriodCacheVariance].[Dispensed]) * @ToGallons) * 0.95 AS [Dispensed],    -- -5%
	SUM([PeriodCacheVariance].[Delivered]) * @ToGallons AS [Delivered],
	(SUM([PeriodCacheVariance].[Delivered]) - (SUM([PeriodCacheVariance].[Dispensed]) * 0.95)) * @ToGallons AS [Variance],
	1 AS [IsTied],
    1 AS [IsConsolidated],
    1 AS [IsAdjusted]
FROM [PeriodCacheVariance]
JOIN [Products] ON [PeriodCacheVariance].[ProductID] = [Products].[ID]
JOIN [ProductCategories] ON [Products].[CategoryID] = [ProductCategories].[ID]
JOIN @ProductTies AS [ProductTies] ON [Products].[ID] = [ProductTies].[ProductID]
WHERE [PeriodCacheVariance].[EDISID] = @EDISID
    AND [Products].[IsCask] = 1
    AND [Products].[IsMetric] = 0
    AND [PeriodCacheVariance].[WeekCommencing] BETWEEN @From AND @To
    AND [ProductTies].[IsTied] = 1
GROUP BY
    [PeriodCacheVariance].[WeekCommencing]

-- Metric
INSERT INTO @Variance
    ([WeekCommencing], [Product], [ProductCategory], [IsCask], [IsKeg], [IsMetric], [Dispensed], [Delivered], [Variance], [IsTied], [IsConsolidated])
SELECT
    [PeriodCacheVariance].[WeekCommencing] AS [WeekCommencing], 
    'Tied Consolidated Post-Mix' AS [Product], 
    'N/A' AS [Category],
	0 AS [IsCask],
    0 AS [IsKeg], 
	1 AS [IsMetric],
    SUM([PeriodCacheVariance].[Dispensed]) * @ToLitres AS [Dispensed],
	SUM([PeriodCacheVariance].[Delivered]) * @ToLitres AS [Delivered],
	SUM([PeriodCacheVariance].[Variance]) * @ToLitres AS [Variance],
	1 AS [IsTied],
    1 AS [IsConsolidated]
FROM [PeriodCacheVariance]
JOIN [Products] ON [PeriodCacheVariance].[ProductID] = [Products].[ID]
JOIN [ProductCategories] ON [Products].[CategoryID] = [ProductCategories].[ID]
JOIN @ProductTies AS [ProductTies] ON [Products].[ID] = [ProductTies].[ProductID]
WHERE [PeriodCacheVariance].[EDISID] = @EDISID
    AND [Products].[IsMetric] = 1
    AND [PeriodCacheVariance].[WeekCommencing] BETWEEN @From AND @To
    AND [ProductTies].[IsTied] = 1
GROUP BY
    [PeriodCacheVariance].[WeekCommencing]

/* Consolidated
   **************************************************************************************************************************************************
*/

-- Fill any gaps where Products are missing weeks (Trend Period only)
INSERT INTO @Variance
    ([WeekCommencing], [Product], [ProductCategory], [IsCask], [IsKeg], [IsMetric], [Dispensed], [Delivered], [Variance], [IsTied], [IsConsolidated])
SELECT
    [Complete].[WeekCommencing],
    [Complete].[Product],
    [Complete].[ProductCategory],
    [Complete].[IsCask],
    [Complete].[IsKeg],
    [Complete].[IsMetric],
    0 AS [Dispensed],
    0 AS [Delivered],
    0 AS [Variance],
    [Complete].[IsTied],
    [Complete].[IsConsolidated]
FROM (
    SELECT
        [Calendar].[FirstDateOfWeek] AS [WeekCommencing],
        [Variance].[Product],
        [Variance].[ProductCategory],
        [Variance].[IsCask],
        [Variance].[IsKeg],
        [Variance].[IsMetric],
        [Variance].[IsTied],
        [Variance].[IsConsolidated]
    FROM (
        SELECT DISTINCT 
            [Calendar].[FirstDateOfWeek]
        FROM [Calendar]
        WHERE [FirstDateOfWeek] BETWEEN @From AND @To
        ) AS [Calendar]
    CROSS APPLY  (
        SELECT DISTINCT 
            [Product],
            [ProductCategory],
            [IsCask],
            [IsKeg],
            [IsMetric],
            [IsTied],
            [IsConsolidated]
        FROM @Variance
        ) AS [Variance]
    ) AS [Complete]
LEFT JOIN @Variance AS [Variance]
    ON [Complete].[WeekCommencing] = [Variance].[WeekCommencing]
    AND [Complete].[Product] = [Variance].[Product]
WHERE [Variance].[WeekCommencing] IS NULL

/* **************************************************************************************************************************************************
   Cumulative Variance & Trend
*/

-- Calculate the Cumulative Variance & Trend within a recursive CTE
;WITH [V] AS
(   SELECT 
        [WeekCommencing],
        [Product],
        [Variance],
        ROW_NUMBER() OVER (ORDER BY [Product], [WeekCommencing]) AS [RowNum]
    FROM @Variance
), [W] AS
(   -- Anchor Definition
    SELECT 
        [WeekCommencing],
        [V].[Product],
        [Variance],
        [V].[RowNum],
        [CV] = [Variance],
        [Trend] = [Variance]
    FROM [V]
    JOIN (  
        SELECT
            [Product],
            MIN([RowNum]) AS [RowNum]
        FROM [V]
        GROUP BY [Product]
        )
     AS [X] 
        ON [V].[RowNum] = [X].[RowNum]

    UNION ALL 

    -- Recursive Definition   V = Current, W = Previous
    SELECT
        [V].[WeekCommencing],
        [V].[Product],
        [V].[Variance],
        [V].[RowNum],
        [W].[CV] + [V].[Variance],
        CASE WHEN [V].[Variance] < 0                        -- Current Variance value is negative
             THEN [W].[Trend] + [V].[Variance]              -- Continue the Trend
             ELSE CASE WHEN [W].[Trend] >= 0                -- Positive Trend, detect if it has already been reset
                       THEN [W].[Trend] + [V].[Variance]    -- Previous Trend value was positive, Continue the Trend
                       WHEN [W].[Trend] >= -5               -- Detect if the Trend had reached the threshold
                       THEN [W].[Trend] + [V].[Variance]    -- Previous Trend was negative but above Threshold, Continue the Trend
                       ELSE [V].[Variance]                  -- Previous Trend had passed threshold, Start a new Trend
                       END
             END AS [Trend]
    FROM [W] 
    INNER JOIN [V]
        ON [V].[RowNum] = ([W].[RowNum] + 1)
       AND [V].[Product] = [W].[Product]
)
UPDATE @Variance
SET [CumulativeVariance] = [CV].[Cumulative],
    [Trend] = [CV].[Trend],
    [Trending] = CASE WHEN [CV].[Trend] < -@MinimumTrend THEN 1 ELSE 0 END
FROM @Variance AS [V]
JOIN (  SELECT
            [WeekCommencing],
            [Product],
            [Variance],
            [Cumulative] = [CV],
            [Trend],
            [RowNum]
        FROM [W] )
    AS [CV]
    ON [V].[WeekCommencing] = [CV].[WeekCommencing]
    AND [V].[Product] = [CV].[Product]
OPTION (MAXRECURSION 10000)

-- Set the Trend Totals
UPDATE [V1]
SET [V1].[TrendTotal] = 
        CASE WHEN [V1].[Trending] = 1 AND [V2].[Trending] = 0
             THEN [V1].[Trend]
             ELSE NULL
             END
FROM @Variance AS [V1]
JOIN @Variance AS [V2]
    ON [V1].[WeekCommencing] = DATEADD(DAY, -7, [V2].[WeekCommencing]) -- match to the previous week
    AND [V1].[Product] = [V2].[Product]

/* Cumulative Variance & Trend
   **************************************************************************************************************************************************
*/


/* **************************************************************************************************************************************************
   Per-Product - Prefix Data
*/

-- Add additional 3 week (non-trend impacting) data
INSERT INTO @Variance
    ([WeekCommencing], [Product], [ProductCategory], [IsCask], [IsKeg], [IsMetric], [Dispensed], [Delivered], [Variance], [IsTied])
SELECT
    [PeriodCacheVariance].[WeekCommencing] AS [WeekCommencing], 
    [Products].[Description] AS [Product], 
    [ProductCategories].[Description] AS [Category],
	[Products].[IsCask] ,
    CASE WHEN Products.IsCask = 0 AND [Products].[IsMetric] = 0 AND [Products].[IsWater] = 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS [IsKeg], 
	[Products].[IsMetric],
    CASE WHEN [Products].[IsMetric] = 0 THEN [PeriodCacheVariance].[Dispensed] * @ToGallons ELSE [PeriodCacheVariance].[Dispensed] * @ToLitres END AS [Dispensed],
	CASE WHEN [Products].[IsMetric] = 0 THEN [PeriodCacheVariance].[Delivered] * @ToGallons ELSE [PeriodCacheVariance].[Delivered] * @ToLitres END AS [Delivered],
	CASE WHEN [Products].[IsMetric] = 0 THEN [PeriodCacheVariance].[Variance] * @ToGallons ELSE [PeriodCacheVariance].[Variance] * @ToLitres END AS [Variance],
	[ProductTies].[IsTied]
FROM [PeriodCacheVariance]
JOIN [Products] ON [PeriodCacheVariance].[ProductID] = [Products].[ID]
JOIN [ProductCategories] ON [Products].[CategoryID] = [ProductCategories].[ID]
JOIN @ProductTies AS [ProductTies] ON [Products].[ID] = [ProductTies].[ProductID]
WHERE [PeriodCacheVariance].[EDISID] = @EDISID
    AND ([Products].[IsCask] = 0 OR @IncludeCasks = 1) 
    AND (CASE WHEN [Products].[IsCask] = 0 AND [Products].[IsMetric] = 0 AND [Products].[IsWater] = 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END = 1 OR @IncludeKegs = 1) 
    AND ([Products].[IsMetric] = 0 OR @IncludeMetric = 1)
    AND [PeriodCacheVariance].[WeekCommencing] BETWEEN @NonTrendFrom AND DATEADD(DAY, -1, @From)
    AND (@OnlyTied = 0 OR (@OnlyTied = 1 AND [ProductTies].[IsTied] = 1))

/* Per-Product - Prefix Data
   **************************************************************************************************************************************************
*/


/* **************************************************************************************************************************************************
   Consolidated - Prefix Data
*/

-- Draught
INSERT INTO @Variance
    ([WeekCommencing], [Product], [ProductCategory], [IsCask], [IsKeg], [IsMetric], [Dispensed], [Delivered], [Variance], [IsTied], [IsConsolidated])
SELECT
    [PeriodCacheVariance].[WeekCommencing] AS [WeekCommencing], 
    'Tied Consolidated Draught' AS [Product], 
    'N/A' AS [Category],
	1 AS [IsCask],
    1 AS [IsKeg], 
	0 AS [IsMetric],
    SUM([PeriodCacheVariance].[Dispensed]) * @ToGallons AS [Dispensed],
	SUM([PeriodCacheVariance].[Delivered]) * @ToGallons AS [Delivered],
	SUM([PeriodCacheVariance].[Variance]) * @ToGallons AS [Variance],
	1 AS [IsTied],
    1 AS [IsConsolidated]
FROM [PeriodCacheVariance]
JOIN [Products] ON [PeriodCacheVariance].[ProductID] = [Products].[ID]
JOIN [ProductCategories] ON [Products].[CategoryID] = [ProductCategories].[ID]
JOIN @ProductTies AS [ProductTies] ON [Products].[ID] = [ProductTies].[ProductID]
WHERE [PeriodCacheVariance].[EDISID] = @EDISID
    AND [Products].[IsMetric] = 0
    AND [PeriodCacheVariance].[WeekCommencing] BETWEEN @NonTrendFrom  AND DATEADD(DAY, -1, @From)
    AND [ProductTies].[IsTied] = 1
GROUP BY
    [PeriodCacheVariance].[WeekCommencing]

-- Cask
INSERT INTO @Variance
    ([WeekCommencing], [Product], [ProductCategory], [IsCask], [IsKeg], [IsMetric], [Dispensed], [Delivered], [Variance], [IsTied], [IsConsolidated], [IsAdjusted])
SELECT
    [PeriodCacheVariance].[WeekCommencing] AS [WeekCommencing], 
    'Tied Consolidated Cask' AS [Product], 
    'N/A' AS [Category],
	1 AS [IsCask],
    0 AS [IsKeg], 
	0 AS [IsMetric],
    SUM([PeriodCacheVariance].[Dispensed]) * @ToGallons AS [Dispensed],
	SUM([PeriodCacheVariance].[Delivered]) * @ToGallons AS [Delivered],
	SUM([PeriodCacheVariance].[Variance]) * @ToGallons AS [Variance],
	1 AS [IsTied],
    1 AS [IsConsolidated],
    0 AS [IsAdjusted]
FROM [PeriodCacheVariance]
JOIN [Products] ON [PeriodCacheVariance].[ProductID] = [Products].[ID]
JOIN [ProductCategories] ON [Products].[CategoryID] = [ProductCategories].[ID]
JOIN @ProductTies AS [ProductTies] ON [Products].[ID] = [ProductTies].[ProductID]
WHERE [PeriodCacheVariance].[EDISID] = @EDISID
    AND [Products].[IsCask] = 1
    AND [Products].[IsMetric] = 0
    AND [PeriodCacheVariance].[WeekCommencing] BETWEEN @NonTrendFrom  AND DATEADD(DAY, -1, @From)
    AND [ProductTies].[IsTied] = 1
GROUP BY
    [PeriodCacheVariance].[WeekCommencing]

-- Cask -5%
INSERT INTO @Variance
    ([WeekCommencing], [Product], [ProductCategory], [IsCask], [IsKeg], [IsMetric], [Dispensed], [Delivered], [Variance], [IsTied], [IsConsolidated], [IsAdjusted])
SELECT
    [PeriodCacheVariance].[WeekCommencing] AS [WeekCommencing], 
    'Tied Consolidated Cask Minus 5%' AS [Product], 
    'N/A' AS [Category],
	1 AS [IsCask],
    0 AS [IsKeg], 
	0 AS [IsMetric],
    (SUM([PeriodCacheVariance].[Dispensed]) * @ToGallons) * 0.95 AS [Dispensed],    -- -5%
	SUM([PeriodCacheVariance].[Delivered]) * @ToGallons AS [Delivered],
	(SUM([PeriodCacheVariance].[Delivered]) - (SUM([PeriodCacheVariance].[Dispensed]) * 0.95)) * @ToGallons AS [Variance],
	1 AS [IsTied],
    1 AS [IsConsolidated],
    1 AS [IsAdjusted]
FROM [PeriodCacheVariance]
JOIN [Products] ON [PeriodCacheVariance].[ProductID] = [Products].[ID]
JOIN [ProductCategories] ON [Products].[CategoryID] = [ProductCategories].[ID]
JOIN @ProductTies AS [ProductTies] ON [Products].[ID] = [ProductTies].[ProductID]
WHERE [PeriodCacheVariance].[EDISID] = @EDISID
    AND [Products].[IsCask] = 1
    AND [Products].[IsMetric] = 0
    AND [PeriodCacheVariance].[WeekCommencing] BETWEEN @NonTrendFrom  AND DATEADD(DAY, -1, @From)
    AND [ProductTies].[IsTied] = 1
GROUP BY
    [PeriodCacheVariance].[WeekCommencing]

-- Metric
INSERT INTO @Variance
    ([WeekCommencing], [Product], [ProductCategory], [IsCask], [IsKeg], [IsMetric], [Dispensed], [Delivered], [Variance], [IsTied], [IsConsolidated])
SELECT
    [PeriodCacheVariance].[WeekCommencing] AS [WeekCommencing], 
    'Tied Consolidated Post-Mix' AS [Product], 
    'N/A' AS [Category],
	0 AS [IsCask],
    0 AS [IsKeg], 
	1 AS [IsMetric],
    SUM([PeriodCacheVariance].[Dispensed]) * @ToLitres AS [Dispensed],
	SUM([PeriodCacheVariance].[Delivered]) * @ToLitres AS [Delivered],
	SUM([PeriodCacheVariance].[Variance]) * @ToLitres AS [Variance],
	1 AS [IsTied],
    1 AS [IsConsolidated]
FROM [PeriodCacheVariance]
JOIN [Products] ON [PeriodCacheVariance].[ProductID] = [Products].[ID]
JOIN [ProductCategories] ON [Products].[CategoryID] = [ProductCategories].[ID]
JOIN @ProductTies AS [ProductTies] ON [Products].[ID] = [ProductTies].[ProductID]
WHERE [PeriodCacheVariance].[EDISID] = @EDISID
    AND [Products].[IsMetric] = 1
    AND [PeriodCacheVariance].[WeekCommencing] BETWEEN @NonTrendFrom AND DATEADD(DAY, -1, @From)
    AND [ProductTies].[IsTied] = 1
GROUP BY
    [PeriodCacheVariance].[WeekCommencing]

/* Consolidated - Prefix Data
   **************************************************************************************************************************************************
*/

DECLARE @ExpectedWeekCount INT = 0
SELECT @ExpectedWeekCount = COUNT(DISTINCT [FirstDateOfWeek])
FROM [Calendar]
WHERE [CalendarDate] BETWEEN @NonTrendFrom AND @To

-- Fill any gaps where Products are missing weeks (for products affected by 3 week prefix)
INSERT INTO @Variance
    ([WeekCommencing], [Product], [ProductCategory], [IsCask], [IsKeg], [IsMetric], [Dispensed], [Delivered], [Variance], [IsTied], [IsConsolidated])
SELECT
    [Complete].[WeekCommencing],
    [Complete].[Product],
    [Complete].[ProductCategory],
    [Complete].[IsCask],
    [Complete].[IsKeg],
    [Complete].[IsMetric],
    0 AS [Dispensed],
    0 AS [Delivered],
    0 AS [Variance],
    [Complete].[IsTied],
    [Complete].[IsConsolidated]
FROM (  SELECT
            [Calendar].[FirstDateOfWeek] AS [WeekCommencing],
            [Variance].[Product],
            [Variance].[ProductCategory],
            [Variance].[IsCask],
            [Variance].[IsKeg],
            [Variance].[IsMetric],
            [Variance].[IsTied],
            [Variance].[IsConsolidated]
        FROM (
            SELECT DISTINCT 
                [Calendar].[FirstDateOfWeek]
            FROM [Calendar]
            WHERE [FirstDateOfWeek] BETWEEN @NonTrendFrom AND @To
            ) AS [Calendar]
        CROSS APPLY  (
            SELECT DISTINCT 
                [IncompleteVariance].[Product],
                [ProductCategory],
                [IsCask],
                [IsKeg],
                [IsMetric],
                [IsTied],
                [IsConsolidated]
            FROM @Variance AS [IncompleteVariance]
            JOIN (  SELECT 
                        [Product],
                        COUNT([WeekCommencing]) AS [Weeks]
                    FROM @Variance
                    GROUP BY [Product]
                    HAVING COUNT([WeekCommencing]) < @ExpectedWeekCount
                ) AS [IncompleteProducts]
                ON [IncompleteVariance].[Product] = [IncompleteProducts].[Product]
            ) AS [Variance]
    ) AS [Complete]
LEFT JOIN @Variance AS [Variance]
    ON [Complete].[WeekCommencing] = [Variance].[WeekCommencing]
    AND [Complete].[Product] = [Variance].[Product]
WHERE [Variance].[WeekCommencing] IS NULL

/*  Close hanging Trends
    Where the Trend hasn't "completed" as it's still ongoing, we manually complete the final week for the selected period.
    This could be done at the initial point of calculation but for simplicity (avoiding nested CASE statements) I'm doing it here instead
*/


UPDATE [Variance]
SET [TrendTotal] = [Trend]
FROM @Variance AS [Variance]
JOIN (  SELECT
            [PotentialHanging].[HangingTrendWeek],
            [PotentialHanging].[Product]
        FROM (  SELECT
                    MAX([WeekCommencing]) AS [HangingTrendWeek],
                    [Product]
                FROM @Variance AS [Variance]
                WHERE
                    [Trending] = 1
                AND [TrendTotal] IS NULL
                AND [WeekCommencing] = DATEADD(WEEK, DATEDIFF(WEEK, 6, @To), 0)
                GROUP BY 
                    [Product]
            ) AS [PotentialHanging]
        LEFT JOIN (  SELECT
                    MAX([WeekCommencing]) AS [CompletedTrendWeek],
                    [Product]
                FROM @Variance
                WHERE
                    [Trending] = 1
                AND [TrendTotal] IS NOT NULL
                GROUP BY 
                    [Product]
            ) AS [CompletedTrends]
            ON [PotentialHanging].[Product] = [CompletedTrends].[Product]
            AND DATEADD(WEEK, 1, [PotentialHanging].[HangingTrendWeek]) = [CompletedTrends].[CompletedTrendWeek]
        WHERE 
            [CompletedTrends].[CompletedTrendWeek] IS NULL
    ) AS [TrendsToClose]
    ON [Variance].[Product] = [TrendsToClose].[Product]
    AND [Variance].[WeekCommencing] = [TrendsToClose].[HangingTrendWeek]

-- Final Results
SELECT
    [WeekCommencing], 
    [Product], 
    [ProductCategory],
    [IsCask], 
    [IsKeg], 
    [IsMetric], 
    ROUND([Dispensed],2) AS Dispensed, 
    ROUND([Delivered],2) AS Delivered, 
    ROUND([Variance],2) AS Variance, 
    ROUND([CumulativeVariance], 2) AS CumulativeVariance,
    [IsTied],
    [IsConsolidated],
    [IsAdjusted],
    [Trending],     -- If true, report colour should be purple. Otherwise use standard colouring.
    [Trend],        -- Calculated trend value, handy for testing if we are calculating it correctly but never display on a report.
    [TrendTotal],   -- Only populated when we have a 'Final' Trend value to display on report. Shows the last negative Trend total.
    RANK() OVER (PARTITION BY [Product] ORDER BY [WeekCommencing] ASC) AS [WeekNumber]
FROM @Variance
ORDER BY 
    [Product], 
    [WeekCommencing]
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTrendVarianceWeekly] TO PUBLIC
    AS [dbo];

