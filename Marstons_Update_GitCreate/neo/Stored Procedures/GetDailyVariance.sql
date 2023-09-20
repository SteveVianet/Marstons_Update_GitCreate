CREATE PROCEDURE [neo].[GetDailyVariance]
(
	@From 				DATETIME = NULL,
	@To					DATETIME = NULL,
	@EDISID				INT,
	@Tied				BIT = NULL
)
AS

BEGIN
--DECLARE	@From 				DATETIME = '2016-04-25 00:00:00.000'
--DECLARE	@To					DATETIME = '2016-07-17'
--DECLARE	@FirstDayOfWeek		INT = 1
--DECLARE	@EDISID				INT = 1632
--DECLARE @Tied				BIT = NULL

SET DATEFIRST 1

DECLARE @Dates TABLE
(
	[Date] DATETIME NOT NULL
)

DECLARE @TempDate datetime = @From

while @TempDate <= @To
begin
	INSERT INTO @Dates VALUES(@TempDate)

	SET @TempDate = DATEADD(day, 1, @TempDate)
end

DECLARE @Variance TABLE
(
	[Date] DATETIME NOT NULL,
	[Dispensed] FLOAT NOT NULL,
	[Delivered] FLOAT NOT NULL,
	[Variance] FLOAT NOT NULL,
	[CumulativeVariance] FLOAT NOT NULL DEFAULT(0),
	[Trending] BIT NOT NULL DEFAULT(0),
    [Trend] FLOAT,
	[TrendTotal] FLOAT,
	[StockValue] FLOAT
)

DECLARE @MinimumTrend INT = 5

;WITH Delivered
AS
(
SELECT SUM(Quantity) AS Delivered, MasterDates.[Date]
FROM dbo.Delivery
JOIN dbo.MasterDates ON MasterDates.[ID] = Delivery.DeliveryID
JOIN dbo.Products ON Products.[ID] = Delivery.Product
LEFT JOIN SiteProductTies ON SiteProductTies.EDISID = @EDISID AND SiteProductTies.ProductID = Products.[ID]
LEFT JOIN SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = @EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
WHERE Sites.EDISID = @EDISID
AND (COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = @Tied OR @Tied IS NULL)
AND MasterDates.[Date] BETWEEN @From AND @To
AND MasterDates.[Date] >= Sites.SiteOnline
GROUP BY MasterDates.[Date]
),
Dispensed
AS
(
SELECT SUM(Quantity) AS Dispensed, MasterDates.[Date]
FROM dbo.DLData
JOIN dbo.MasterDates ON MasterDates.[ID] = DLData.DownloadID
JOIN dbo.Products ON Products.[ID] = DLData.Product
LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = @EDISID AND SiteProductTies.ProductID = Products.[ID]
LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = @EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
WHERE Sites.EDISID = @EDISID
AND (COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = @Tied OR @Tied IS NULL)
AND MasterDates.[Date] BETWEEN @From AND @To
AND MasterDates.[Date] >= Sites.SiteOnline
GROUP BY MasterDates.[Date]
)
INSERT INTO @Variance
(
	[Date],
	[Dispensed],
	[Delivered],
	[Variance]
)
SELECT	
	dat.[Date] AS [Date], 
	ISNULL(dis.Dispensed, 0) As Dispensed,  
	ISNULL(del.Delivered, 0) AS Delivered, 
	ISNULL(del.Delivered * 8, 0) - ISNULL(dis.Dispensed, 0) AS Variance
FROM		@Dates dat
LEFT OUTER JOIN Delivered del ON dat.[Date] = del.[Date]
LEFT OUTER JOIN	Dispensed dis ON dat.[Date] = dis.[Date]
--ORDER BY ISNULL(del.[Date], dis.[Date])

-- Calculate the Cumulative Variance & Trend within a recursive CTE
;WITH [V] AS
(   SELECT 
        [Date],
        [Variance],
        ROW_NUMBER() OVER (ORDER BY [Date]) AS [RowNum]
    FROM @Variance
), [W] AS
(   -- Anchor Definition
    SELECT 
        [Date],
        [Variance],
        [V].[RowNum],
        [CV] = [Variance],
        [Trend] = [Variance]
    FROM [V]
    JOIN (  
        SELECT
            MIN([RowNum]) AS [RowNum]
        FROM [V]
        )
     AS [X] 
        ON [V].[RowNum] = [X].[RowNum]

    UNION ALL 

    -- Recursive Definition   V = Current, W = Previous
    SELECT
        [V].[Date],
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
)
UPDATE @Variance
SET [CumulativeVariance] = [CV].[Cumulative],
    [Trend] = [CV].[Trend],
    [Trending] = CASE WHEN [CV].[Trend] < -@MinimumTrend THEN 1 ELSE 0 END
FROM @Variance AS [V]
JOIN (  SELECT
            [Date],
            [Variance],
            [Cumulative] = [CV],
            [Trend],
            [RowNum]
        FROM [W] )
    AS [CV]
    ON [V].[Date] = [CV].[Date]
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
    ON [V1].[Date] = DATEADD(DAY, -1, [V2].[Date]) -- match to the previous day

UPDATE [Variance]
SET [TrendTotal] = [Trend]
FROM @Variance AS [Variance]
JOIN (  SELECT
            [PotentialHanging].[HangingTrendDate]
        FROM (  SELECT
                    MAX([Date]) AS [HangingTrendDate]
                FROM @Variance AS [Variance]
                WHERE
                    [Trending] = 1
                AND [TrendTotal] IS NULL
                AND [Date] = @To
            ) AS [PotentialHanging]
        LEFT JOIN (  SELECT
                    MAX([Date]) AS [CompletedTrendDate]
                FROM @Variance
                WHERE
                    [Trending] = 1
                AND [TrendTotal] IS NOT NULL
            ) AS [CompletedTrends]
            ON DATEADD(DAY, 1, [PotentialHanging].[HangingTrendDate]) = [CompletedTrends].[CompletedTrendDate]
        WHERE 
            [CompletedTrends].[CompletedTrendDate] IS NULL
    ) AS [TrendsToClose]
    ON [Variance].[Date] = [TrendsToClose].[HangingTrendDate]


UPDATE	@Variance
SET		StockValue = StockQuantity.Quantity + Delivered - Dispensed
FROM	@Variance v
INNER JOIN
(
SELECT	maxmd.MaxDate, SUM(Quantity) AS Quantity
FROM	Stock s
INNER JOIN MasterDates md on s.MasterDateID = md.ID AND (md.EDISID = @EDISID OR @EDISID IS NULL)
INNER JOIN (
	SELECT	MAX([Date]) AS MaxDate
	FROM	Stock s
	INNER JOIN MasterDates md on s.MasterDateID = md.ID AND (md.EDISID = @EDISID OR @EDISID IS NULL)
	WHERE md.[Date] BETWEEN @From AND @To
) AS maxmd ON md.[Date] = maxmd.MaxDate
GROUP BY maxmd.MaxDate
) AS StockQuantity ON StockQuantity.MaxDate = v.[Date]

;WITH OrderedStock (
	RowNumber,
	[Date],
	[Dispensed],
	[Delivered],
	[StockValue]
) AS
(
	SELECT 
		ROW_NUMBER() OVER (ORDER BY [Date]) AS RowNumber,
		[Date],
		[Dispensed],
		[Delivered],
		[StockValue]
	FROM @Variance
), CalculatedStock (
	[Date],
	[Dispensed],
	[Delivered],
	[StockValue],
	[RowNumber]
) AS
(
	SELECT 
		[Date],
		[Dispensed],
		[Delivered],
		[StockValue],
		[RowNumber] 
	FROM OrderedStock
	WHERE StockValue IS NOT NULL
	UNION ALL
	SELECT 
		os.[Date],
		os.[Dispensed],
		os.[Delivered],
		os2.[StockValue] + os.Delivered - os.Dispensed,
		os.[RowNumber] 
	FROM
		OrderedStock os
	INNER JOIN
		CalculatedStock os2 ON os2.RowNumber = os.RowNumber - 1
)
UPDATE	@Variance
SET		StockValue = cs.StockValue
FROM	@Variance v
INNER JOIN CalculatedStock cs on v.[Date] = cs.[Date]
OPTION (MAXRECURSION 10000);  

SELECT 
	[Date],
	'Consolidated' AS [Product],
	[Dispensed],
	[Delivered] * 8 AS Delivered, -- Convert gallons to pints
	[Variance],
	[CumulativeVariance],
	CAST(0 AS BIT) AS IsCask,			-- |
	CAST(0 AS BIT) AS IsMetric,			-- | QUICK FIX: Should be removed  and Fusion / Portal refactored
	CAST(0 AS BIT) AS IsKeg,			-- |			(See TFS Task 9206)
	[Trending],
    [Trend],
	[TrendTotal],
	0 AS [Stock],   -- Procedure need rewriting to correct this value (see GetWeeklyVariance)
    CAST(0 AS BIT) AS [Visit],   -- To match columns with Columns from GetWeeklyVariance
    CAST(0 AS BIT) AS [COT],     -- To match columns with Columns from GetWeeklyVariance
    CAST(0 AS BIT) AS [ServiceCall],
    0 AS [WeekNumber]   -- To match columns with Columns from GetWeeklyVariance
FROM @Variance
ORDER BY [Date]
END
GO
GRANT EXECUTE
    ON OBJECT::[neo].[GetDailyVariance] TO PUBLIC
    AS [dbo];

