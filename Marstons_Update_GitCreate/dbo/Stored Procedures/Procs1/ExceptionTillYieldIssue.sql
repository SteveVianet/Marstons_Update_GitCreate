CREATE PROCEDURE [dbo].[ExceptionTillYieldIssue]
(
	@EDISID INT = NULL,
	@Auditor VARCHAR(255) = NULL
)
AS

/* For Testing */ 
--DECLARE @Auditor VARCHAR(50) = NULL
--DECLARE @EDISID INT = NULL --30
--DECLARE @SiteID VARCHAR (15) = NULL --'00159'
--IF @SiteID IS NOT NULL
--    SELECT @EDISID = [EDISID] FROM [dbo].[Sites] WHERE [SiteID] = @SiteID

DECLARE @EnableLogging BIT = 1
DECLARE @DebugLimitSites INT = 0 -- The maximum number of Sites to process. 0 = no limit
DECLARE @DebugDates BIT = 0
DECLARE @DebugParameters BIT = 0
DECLARE @DebugEPOS BIT = 0
DECLARE @DebugDispense BIT = 0
DECLARE @DebugYield BIT = 0
DECLARE @DebugSales BIT = 0
DECLARE @DebugSites BIT = 0
DECLARE @DebugSitesUS BIT = 0

SET NOCOUNT ON;
SET DATEFIRST 1;

DECLARE @From DATETIME = DATEADD(wk, DATEDIFF(wk, 6, GETDATE()), 0)
DECLARE @To DATETIME = DATEADD(wk, DATEDIFF(wk, 6, GETDATE()), 6)

/* For testing */
--SET @EnableLogging = 0
--SET @DebugLimitSites = 10
--SET @DebugDates = 1
--SET @DebugParameters = 1
--SET @DebugEPOS = 1
--SET @DebugDispense = 1
--SET @DebugYield = 1
--SET @DebugSales = 1
--SET @DebugSites = 1
--SET @DebugSitesUS = 1
--SET @From = DATEADD(WEEK, -1, @From)
--SET @To = DATEADD(WEEK, -1, @To)

-- Unit Conversion
DECLARE @ToGallons FLOAT = 0.125     -- {Pint Value} * @ToGallons
DECLARE @ToLitres FLOAT = 0.568261   -- {Pint Value} * @ToLitres
DECLARE @ToFlOz FLOAT = 19.2152      -- {Pint Value} * @ToFlOz

IF @DebugDates = 1
BEGIN
    SELECT @From, @To
END

IF @EnableLogging = 1
BEGIN
    DECLARE @DatabaseID INT
    SELECT @DatabaseID = [ID] FROM [SQL1\SQL1].[ServiceLogger].[dbo].[EDISDatabases] WHERE [Name] = DB_NAME()
    DECLARE @NotificationTypeID INT
    SELECT @NotificationTypeID = [NotificationTypeID] FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationType] WHERE [StoredProcedure] = OBJECT_NAME(@@PROCID)
    IF @NotificationTypeID IS NOT NULL
    BEGIN
        EXEC [SQL1\SQL1].[Auditing].[dbo].[AddNotificationTypeGenerationLog] @NotificationTypeID, @DatabaseID, @EDISID, @From, @To
    END
END

-- UK
DECLARE @Yield_Percent_Min INT
DECLARE @Yield_Percent_Max INT
DECLARE @Yield_Unit_Limit INT -- UK: Pints

-- US
DECLARE @US_Yield_Percent_Min INT
DECLARE @US_Yield_Percent_Max INT
DECLARE @US_Yield_Unit_Limit INT -- US: FlOz

-- US Sites
DECLARE @IsUS VARCHAR(255) = 'en-US'

DECLARE @US_Sites TABLE ([EDISID] INT NOT NULL)

DECLARE @Property_International INT
SELECT @Property_International = [ID]
FROM [dbo].[Properties]
WHERE [Name] = 'International'  -- Testing: Independent (property exists), Admiral (property doesn't exist)

INSERT INTO @US_Sites ([EDISID])
SELECT [EDISID]
FROM [dbo].[SiteProperties]
WHERE 
    [PropertyID] = @Property_International
AND [Value] = @IsUS -- Is USA

IF @DebugSitesUS = 1
BEGIN
    SELECT [EDISID] AS [US_EDISID] FROM @US_Sites
END

--filtered sites
CREATE TABLE #Sites(EDISID INT, LastDownload Datetime, SiteID varchar(15), SiteOnline DateTime)

INSERT INTO #Sites
(EDISID, LastDownload, SiteID, SiteOnline)
SELECT Sites.EDISID, LastDownload, SiteID, SiteOnline
FROM Sites
WHERE  (@EDISID IS NULL OR Sites.EDISID = @EDISID)
AND (@Auditor IS NULL OR LOWER(SiteUser) = LOWER(@Auditor))

INSERT INTO #Sites --add in second cellar sites that may not have auditor assigned to them in Sites table
(EDISID, LastDownload, SiteID, SiteOnline)
SELECT	s2.EDISID, s2.LastDownload, s2.SiteID, s2.LastDownload 
FROM	#Sites s
INNER JOIN SiteGroupSites sgs ON s.EDISID = sgs.EDISID
INNER JOIN SiteGroups sg ON sgs.SiteGroupID = sg.ID AND sg.TypeID = 1 --(1 = multi cellar)
INNER JOIN SiteGroupSites sgs2 ON sg.ID = sgs2.SiteGroupID AND sgs2.EDISID <> s.EDISID
INNER JOIN Sites s2 ON sgs2.EDISID = s2.EDISID
WHERE s2.EDISID NOT IN (SELECT s.EDISID FROM #Sites)


SELECT  @Yield_Percent_Min      = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] WHERE [ParameterName] = 'TillYieldPercentLow'
SELECT  @Yield_Percent_Max      = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] WHERE [ParameterName] = 'TillYieldPercentHigh'
SELECT  @Yield_Unit_Limit       = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] WHERE [ParameterName] = 'TillYieldQuantityLimit-Pints'

SELECT  @US_Yield_Percent_Min   = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] WHERE [ParameterName] = 'TillYieldPercentLow-US'
SELECT  @US_Yield_Percent_Max   = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] WHERE [ParameterName] = 'TillYieldPercentHigh-US'
SELECT  @US_Yield_Unit_Limit    = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] WHERE [ParameterName] = 'TillYieldQuantityLimit-US-FlOz'

IF @DebugParameters = 1
BEGIN
    SELECT 
        @Yield_Percent_Min [Yield_Percent_Min], 
        @Yield_Percent_Max [Yield_Percent_Max], 
        @Yield_Unit_Limit [Yield_Unit_Limit], 
        
        @US_Yield_Percent_Min [US_Yield_Percent_Min], 
        @US_Yield_Percent_Max [US_Yield_Percent_Max], 
        @US_Yield_Unit_Limit [US_Yield_Unit_Limit]
END

DECLARE @SitesWithSales TABLE ([EDISID] INT NOT NULL)

IF @DebugLimitSites = 0
BEGIN
    INSERT INTO @SitesWithSales ([EDISID])
    SELECT
        #Sites.[EDISID]
    FROM #Sites
    JOIN [dbo].[Sales] ON #Sites.[EDISID] = [Sales].[EDISID]
    WHERE
        #Sites.[LastDownload] >= @From
    AND [Sales].[TradingDate] BETWEEN @From AND @To
    --AND(@Auditor IS NULL OR LOWER(SiteUser) = LOWER(@Auditor))
    GROUP BY #Sites.[EDISID]
    HAVING COUNT([Sales].[ID])> 0
END
ELSE
BEGIN
INSERT INTO @SitesWithSales ([EDISID])
    SELECT TOP (@DebugLimitSites)
        #Sites.[EDISID]
    FROM #Sites
    JOIN [dbo].[Sales] ON #Sites.[EDISID] = [Sales].[EDISID]
    WHERE
        #Sites.[LastDownload] >= @From
    AND [Sales].[TradingDate] BETWEEN @From AND @To
  --  AND(@Auditor IS NULL OR LOWER(SiteUser) = LOWER(@Auditor))
    GROUP BY #Sites.[EDISID]
    HAVING COUNT([Sales].[ID])> 0
END

--SELECT * FROM @SitesWithSales

--Merge system groups
DECLARE @PrimaryEDIS TABLE(PrimaryEDISID INT NOT NULL, EDISID INT NOT NULL)
INSERT INTO @PrimaryEDIS
SELECT MAX(PrimaryEDISID) AS PrimaryEDISID, SiteGroupSites.EDISID
FROM(
	SELECT SiteGroupID, SiteGroupSites.EDISID AS PrimaryEDISID
	FROM SiteGroupSites
	JOIN @SitesWithSales AS Sites ON Sites.EDISID = SiteGroupSites.EDISID 
	WHERE SiteGroupID IN (SELECT ID FROM SiteGroups WHERE TypeID = 1)
	AND IsPrimary = 1
	GROUP BY SiteGroupID, SiteGroupSites.EDISID
) AS PrimarySites
JOIN SiteGroupSites ON SiteGroupSites.SiteGroupID = PrimarySites.SiteGroupID
LEFT JOIN PumpSetup ON PumpSetup.EDISID = SiteGroupSites.EDISID
GROUP BY SiteGroupSites.EDISID
ORDER BY PrimaryEDISID

CREATE TABLE #PrimaryProducts(ProductID INT NOT NULL, PrimaryProductID INT NOT NULL) 
INSERT INTO #PrimaryProducts(ProductID, PrimaryProductID) 
SELECT ProductID, ProductGroupPrimaries.PrimaryProductID
FROM ProductGroupProducts
JOIN ProductGroups 
  ON ProductGroups.ID = ProductGroupProducts.ProductGroupID
JOIN (
	SELECT ProductGroupID, ProductID AS PrimaryProductID
	FROM ProductGroupProducts
	JOIN ProductGroups ON ProductGroups.ID = ProductGroupProducts.ProductGroupID
	WHERE TypeID = 1 AND IsPrimary = 1
	) AS ProductGroupPrimaries 
  ON ProductGroupPrimaries.ProductGroupID = ProductGroups.ID 
WHERE TypeID = 1 
  AND IsPrimary = 0

/* Below based on GetWebSiteYieldDaily */

IF @DebugSites = 1
BEGIN
    --SELECT * FROM @SitesWithSales
    --SELECT * FROM @PrimaryEDIS

    SELECT *
    FROM @SitesWithSales AS [SWS]
    LEFT JOIN @PrimaryEDIS AS [PEDIS] ON [SWS].[EDISID] = [PEDIS].[PrimaryEDISID]

    SELECT
        COALESCE([PEDIS].[EDISID], [SWS].[EDISID]) AS [EDISID],
        COALESCE([PEDIS].[PrimaryEDISID], [SWS].[EDISID]) AS [PrimaryEDISID]
    FROM @SitesWithSales AS [SWS]
    LEFT JOIN @PrimaryEDIS AS [PEDIS] ON [SWS].[EDISID] = [PEDIS].[PrimaryEDISID]
END

IF @DebugEPOS = 1
BEGIN
    SELECT
        COALESCE([Dispense].[EDISID], [Sales].[EDISID]) AS [EDISID],
        COALESCE([Dispense].[ProductID], [Sales].[ProductID]) AS [ProductID],
        (ISNULL([Sales].[Sold], 0) - ISNULL([Dispense].[Drinks], 0)) AS [Yield],
        (ISNULL([Sales].[Sold], 0) / CASE WHEN ISNULL([Dispense].[Drinks], 0) = 0 THEN 1 ELSE [Dispense].[Drinks] END * 100.0) AS [YieldPercent]
    FROM (    
        SELECT 
            [S].[PrimaryEDISID] AS [EDISID],
            CASE WHEN [P].[IsCask] = 0 
                 THEN ISNULL([PP].[PrimaryProductID], [P].[ID]) 
                 ELSE -1 -- Consolidated Casks
                 END AS [ProductID],
            SUM([DA].[EstimatedDrinks]) AS [Drinks]
        FROM [dbo].[DispenseActions] AS [DA] WITH (NOLOCK)
        JOIN [dbo].[Products] AS [P] ON [DA].[Product] = [P].[ID]
        JOIN (
            SELECT
                COALESCE([PEDIS].[EDISID], [SWS].[EDISID]) AS [EDISID],
                COALESCE([PEDIS].[PrimaryEDISID], [SWS].[EDISID]) AS [PrimaryEDISID]
            FROM @SitesWithSales AS [SWS]
            LEFT JOIN @PrimaryEDIS AS [PEDIS] ON [SWS].[EDISID] = [PEDIS].[PrimaryEDISID]
            ) AS [S] ON [DA].[EDISID] = [S].[EDISID]
        FULL OUTER JOIN #PrimaryProducts AS [PP] ON [PP].[ProductID] = [P].[ID]
        JOIN #Sites AS [X] ON [S].[EDISID] = [X].[EDISID]
        WHERE
            [DA].[TradingDay] BETWEEN @From AND @To
        AND [DA].[TradingDay] >= [X].[SiteOnline]
        AND (@EDISID IS NULL OR [S].[EDISID] = @EDISID)
        AND [DA].[LiquidType] = 2
        --AND [P].[IsCask] = 0
        AND [P].[IsWater] = 0
        GROUP BY
            [S].[PrimaryEDISID],
            CASE WHEN [P].[IsCask] = 0 
                 THEN ISNULL([PP].[PrimaryProductID], [P].[ID]) 
                 ELSE -1 -- Consolidated Casks
                 END
        ) AS [Dispense]
    FULL JOIN (
        SELECT 
            [S].[PrimaryEDISID] AS [EDISID],
            CASE WHEN [P].[IsCask] = 0 
                 THEN ISNULL([PP].[PrimaryProductID], [P].[ID]) 
                 ELSE -1 -- Consolidated Casks
                 END AS [ProductID],
            CASE WHEN [US].[EDISID] IS NULL
                 THEN SUM([SA].[Quantity]) 
                 ELSE SUM([SA].[Quantity]) * @ToFlOz
                 END AS [Sold]
        FROM [dbo].[Sales] AS [SA] WITH (NOLOCK)
        JOIN [dbo].[Products] AS [P] ON [SA].[ProductID] = [P].[ID]
        JOIN (
            SELECT
                COALESCE([PEDIS].[EDISID], [SWS].[EDISID]) AS [EDISID],
                COALESCE([PEDIS].[PrimaryEDISID], [SWS].[EDISID]) AS [PrimaryEDISID]
            FROM @SitesWithSales AS [SWS]
            LEFT JOIN @PrimaryEDIS AS [PEDIS] ON [SWS].[EDISID] = [PEDIS].[PrimaryEDISID]
            ) AS [S] ON [SA].[EDISID] = [S].[EDISID]
        FULL OUTER JOIN #PrimaryProducts AS [PP] ON [PP].[ProductID] = [P].[ID]
        JOIN #Sites AS [X] ON [S].[EDISID] = [X].[EDISID]
        LEFT JOIN @US_Sites AS [US] ON [S].[PrimaryEDISID] = [US].[EDISID]
        WHERE
            [SA].[TradingDate] BETWEEN @From AND @To
        AND [SA].[TradingDate] >= [X].[SiteOnline]
        AND (@EDISID IS NULL OR [S].[EDISID] = @EDISID)
        AND [P].[IsWater] = 0
        GROUP BY
            [S].[PrimaryEDISID],
            [US].[EDISID],
            CASE WHEN [P].[IsCask] = 0 
                 THEN ISNULL([PP].[PrimaryProductID], [P].[ID]) 
                 ELSE -1 -- Consolidated Casks
                 END
        )  AS [Sales] 
           ON [Dispense].[EDISID] = [Sales].[EDISID] AND [Dispense].[ProductID] = [Sales].[ProductID]
END


CREATE TABLE #Exceptions ([EDISID] INT NOT NULL, [Product] VARCHAR(50) NOT NULL, [Yield] FLOAT NOT NULL, [Percent] INT NOT NULL)
INSERT INTO #Exceptions ([EDISID], [Product], [Yield], [Percent])
SELECT 
    [TS].[EDISID],
    CASE WHEN [TS].[ProductID] = -1 
         THEN 'Consolidated Casks'
         ELSE [P].[Description] 
    END AS [Product],
    [TS].[Yield],
    [TS].[YieldPercent]
FROM (
    SELECT
        COALESCE([Dispense].[EDISID], [Sales].[EDISID]) AS [EDISID],
        COALESCE([Dispense].[ProductID], [Sales].[ProductID]) AS [ProductID],
        (ISNULL([Sales].[Sold], 0) - ISNULL([Dispense].[Drinks], 0)) AS [Yield],
        (ISNULL([Sales].[Sold], 0) / CASE WHEN ISNULL([Dispense].[Drinks], 0) = 0 THEN 1 ELSE [Dispense].[Drinks] END * 100.0) AS [YieldPercent]
    FROM (    
        SELECT 
            [S].[PrimaryEDISID] AS [EDISID],
            CASE WHEN [P].[IsCask] = 0 
                 THEN ISNULL([PP].[PrimaryProductID], [P].[ID]) 
                 ELSE -1 -- Consolidated Casks
                 END AS [ProductID],
            SUM([DA].[EstimatedDrinks]) AS [Drinks]
        FROM [dbo].[DispenseActions] AS [DA] WITH (NOLOCK)
        JOIN [dbo].[Products] AS [P] ON [DA].[Product] = [P].[ID]
        JOIN (
            SELECT
                COALESCE([PEDIS].[EDISID], [SWS].[EDISID]) AS [EDISID],
                COALESCE([PEDIS].[PrimaryEDISID], [SWS].[EDISID]) AS [PrimaryEDISID]
            FROM @SitesWithSales AS [SWS]
            LEFT JOIN @PrimaryEDIS AS [PEDIS] ON [SWS].[EDISID] = [PEDIS].[PrimaryEDISID]
            ) AS [S] ON [DA].[EDISID] = [S].[EDISID]
        FULL OUTER JOIN #PrimaryProducts AS [PP] ON [PP].[ProductID] = [P].[ID]
        JOIN #Sites AS [X] ON [S].[EDISID] = [X].[EDISID]
        WHERE
            [DA].[TradingDay] BETWEEN @From AND @To
        AND [DA].[TradingDay] >= [X].[SiteOnline]
       -- AND (@Auditor IS NULL OR LOWER([X].[SiteUser]) = LOWER(@Auditor))
        AND (@EDISID IS NULL OR [S].[EDISID] = @EDISID)
        AND [DA].[LiquidType] = 2
        AND [P].[IsWater] = 0
        GROUP BY
            [S].[PrimaryEDISID],
            CASE WHEN [P].[IsCask] = 0 
                 THEN ISNULL([PP].[PrimaryProductID], [P].[ID]) 
                 ELSE -1 -- Consolidated Casks
                 END
        ) AS [Dispense]
    FULL JOIN (
        SELECT 
            [S].[PrimaryEDISID] AS [EDISID],
            CASE WHEN [P].[IsCask] = 0 
                 THEN ISNULL([PP].[PrimaryProductID], [P].[ID]) 
                 ELSE -1 -- Consolidated Casks
                 END AS [ProductID],
            CASE WHEN [US].[EDISID] IS NULL
                 THEN SUM([SA].[Quantity]) 
                 ELSE SUM([SA].[Quantity]) * @ToFlOz
                 END AS [Sold]
        FROM [dbo].[Sales] AS [SA] WITH (NOLOCK)
        JOIN [dbo].[Products] AS [P] ON [SA].[ProductID] = [P].[ID]
        JOIN (
            SELECT
                COALESCE([PEDIS].[EDISID], [SWS].[EDISID]) AS [EDISID],
                COALESCE([PEDIS].[PrimaryEDISID], [SWS].[EDISID]) AS [PrimaryEDISID]
            FROM @SitesWithSales AS [SWS]
            LEFT JOIN @PrimaryEDIS AS [PEDIS] ON [SWS].[EDISID] = [PEDIS].[PrimaryEDISID]
            ) AS [S] ON [SA].[EDISID] = [S].[EDISID]
        FULL OUTER JOIN #PrimaryProducts AS [PP] ON [PP].[ProductID] = [P].[ID]
        JOIN #Sites AS [X] ON [S].[EDISID] = [X].[EDISID]
        LEFT JOIN @US_Sites AS [US] ON [S].[PrimaryEDISID] = [US].[EDISID]
        WHERE
            [SA].[TradingDate] BETWEEN @From AND @To
        AND [SA].[TradingDate] >= [X].[SiteOnline]
       -- AND (@Auditor IS NULL OR LOWER([X].[SiteUser]) = LOWER(@Auditor))
       -- AND (@EDISID IS NULL OR [S].[EDISID] = @EDISID)
        AND [P].[IsWater] = 0
        GROUP BY
            [S].[PrimaryEDISID],
            [US].[EDISID],
            CASE WHEN [P].[IsCask] = 0 
                 THEN ISNULL([PP].[PrimaryProductID], [P].[ID]) 
                 ELSE -1 -- Consolidated Casks
                 END
        )  AS [Sales] 
            ON [Dispense].[EDISID] = [Sales].[EDISID] AND [Dispense].[ProductID] = [Sales].[ProductID]
    ) AS [TS]
LEFT JOIN @US_Sites AS [US] ON [TS].[EDISID] = [US].[EDISID]
LEFT JOIN [dbo].[Products] AS [P] ON [TS].[ProductID] = [P].[ID]
WHERE
    (
    /* ***************     UK                                                            *************** */
        (([US].[EDISID] IS NULL)
            AND 
        ([TS].[YieldPercent] < @Yield_Percent_Min OR [TS].[YieldPercent] > @Yield_Percent_Max)
            AND
        (ABS([TS].[Yield]) >= @Yield_Unit_Limit))
    /* ***************     UK                                                            *************** */

    /* ***************     US                                                            *************** */
    OR
        (([US].[EDISID] IS NOT NULL)
            AND 
        ([TS].[YieldPercent] < @US_Yield_Percent_Min OR [TS].[YieldPercent] > @US_Yield_Percent_Max)
            AND
        (ABS([TS].[Yield]) >= @US_Yield_Unit_Limit))
    /* ***************     US                                                            *************** */
    )

IF @DebugYield = 1
BEGIN
    SELECT * FROM #Exceptions
END

IF @DebugSites = 0
BEGIN
    SELECT DISTINCT
        [E].[EDISID],
        SUBSTRING(
            (   SELECT ';' + [Product] + '|' + CAST(ROUND([Yield], 2) AS VARCHAR(10)) + CASE WHEN [US].[EDISID] IS NOT NULL THEN ' FlOz' ELSE ' Pints' END + ' (' + CAST([Percent] AS VARCHAR(10)) + '%)'
                FROM #Exceptions AS [Ex]
                LEFT JOIN @US_Sites AS [US] ON [Ex].[EDISID] = [US].[EDISID]
                WHERE [Ex].[EDISID] = [E].[EDISID]
                FOR XML PATH (''), TYPE).value('.','VARCHAR(4000)')
            ,2, 4000) AS [ProductList]
    FROM #Exceptions AS [E]
END
ELSE
BEGIN
    SELECT DISTINCT
        [E].[EDISID],
        [SiteID],
        SUBSTRING(
            (   SELECT ';' + [Product] + '|' + CAST(ROUND([Yield], 2) AS VARCHAR(10)) + CASE WHEN [US].[EDISID] IS NOT NULL THEN ' FlOz' ELSE ' Pints' END + ' (' + CAST([Percent] AS VARCHAR(10)) + '%)'
                FROM #Exceptions AS [Ex]
                LEFT JOIN @US_Sites AS [US] ON [Ex].[EDISID] = [US].[EDISID]
                WHERE [Ex].[EDISID] = [E].[EDISID]
                FOR XML PATH (''), TYPE).value('.','VARCHAR(4000)')
            ,2, 4000) AS [ProductList]
    FROM #Exceptions AS [E]
    JOIN #Sites AS [S] ON [E].[EDISID] = [S].[EDISID]
END

DROP TABLE #PrimaryProducts
DROP TABLE #Exceptions

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ExceptionTillYieldIssue] TO PUBLIC
    AS [dbo];

