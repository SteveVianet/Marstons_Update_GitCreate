CREATE PROCEDURE [dbo].[ExceptionPouringYieldIssue]
(
    @EDISID INT = NULL,
    @Auditor VARCHAR(255) = NULL
)
AS

/* For Testing */ 
--DECLARE @EDISID INT = NULL
--DECLARE @Auditor VARCHAR(255) = NULL

/* Note to RG: This exception works on complete Sites (not individual Systems) so a multi-cellar fix is not required */

DECLARE @EnableLogging BIT = 1
DECLARE @RedOnly BIT = 1  -- 1 = Exclude Amber from end results
DECLARE @DebugLimitSites INT = 0 -- The maximum number of Sites to process. 0 = no limit
DECLARE @DebugDates BIT = 0
DECLARE @DebugParameters BIT = 0
DECLARE @DebugSites BIT = 0
DECLARE @DebugSitesUS BIT = 0
DECLARE @DebugCalRequest BIT = 0
DECLARE @DebugDispense BIT = 0
DECLARE @DebugProductID INT
DECLARE @DebugLiquidType BIT = 0

SET NOCOUNT ON;
SET DATEFIRST 1;

DECLARE @From DATETIME = DATEADD(wk, DATEDIFF(wk, 6, GETDATE()), 0)
DECLARE @To DATETIME = DATEADD(wk, DATEDIFF(wk, 6, GETDATE()), 6)

/* For testing */
--SET @EnableLogging = 0
--SET @DebugLimitSites = 10
--SET @DebugDates = 1
--SET @DebugParameters = 1
--SET @DebugSites = 1
--SET @DebugSitesUS = 1
--SET @DebugCalRequest = 1
--SET @DebugDispense = 1
--SET @DebugProductID = 57 --307
--SET @DebugLiquidType = 1
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

-- Lager, Keg Ale, Smooth & Stout
DECLARE @Keg_Amber_Lower_Min INT
DECLARE @Keg_Amber_Lower_Max INT
DECLARE @Keg_Amber_Higher_Min INT
DECLARE @Keg_Amber_Higher_Max INT

-- Cider & Cask Ale
DECLARE @Cask_Amber_Lower_Min INT
DECLARE @Cask_Amber_Lower_Max INT
DECLARE @Cask_Amber_Higher_Min INT
DECLARE @Cask_Amber_Higher_Max INT

-- US Sites
DECLARE @IsUS VARCHAR(255) = 'en-US'
DECLARE @IsUK VARCHAR(255) = 'en-GB'

DECLARE @US_Sites TABLE ([EDISID] INT NOT NULL)
DECLARE @Other_Sites TABLE ([EDISID] INT NOT NULL)

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

INSERT INTO @Other_Sites ([EDISID])
SELECT [EDISID]
FROM [dbo].[SiteProperties]
WHERE 
    [PropertyID] = @Property_International
AND [Value] <> @IsUS -- Not USA
AND [Value] <> @IsUK -- Not UK

IF @DebugSitesUS = 1
BEGIN
    SELECT [EDISID] AS [US_EDISID] FROM @US_Sites
END

SELECT  @Keg_Amber_Lower_Min      = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] WHERE [ParameterName] = 'PouringLagerKegSmoothStoutLowerLow'
SELECT  @Keg_Amber_Lower_Max      = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] WHERE [ParameterName] = 'PouringLagerKegSmoothStoutLowerHigh'
SELECT  @Keg_Amber_Higher_Min       = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] WHERE [ParameterName] = 'PouringLagerKegSmoothStoutUpperLow'
SELECT  @Keg_Amber_Higher_Max       = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] WHERE [ParameterName] = 'PouringLagerKegSmoothStoutUpperHigh'

SELECT  @Cask_Amber_Lower_Min   = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] WHERE [ParameterName] = 'PouringCiderCaskLowerLow'
SELECT  @Cask_Amber_Lower_Max   = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] WHERE [ParameterName] = 'PouringCiderCaskLowerHigh'
SELECT  @Cask_Amber_Higher_Min    = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] WHERE [ParameterName] = 'PouringCiderCaskUpperLow'
SELECT  @Cask_Amber_Higher_Max    = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] WHERE [ParameterName] = 'PouringCiderCaskUpperHigh'

IF @DebugParameters = 1
BEGIN
    SELECT 
        @Keg_Amber_Lower_Min [Keg_Amber_Lower_Min], 
        @Keg_Amber_Lower_Max [Keg_Amber_Lower_Max], 
        @Keg_Amber_Higher_Min [Keg_Amber_Higher_Min], 
        @Keg_Amber_Higher_Max [Keg_Amber_Higher_Max],

        @Cask_Amber_Lower_Min [Cask_Amber_Lower_Min], 
        @Cask_Amber_Lower_Max [Cask_Amber_Lower_Max], 
        @Cask_Amber_Higher_Min [Cask_Amber_Higher_Min], 
        @Cask_Amber_Higher_Max [Cask_Amber_Higher_Max]
END

--Merge system groups
DECLARE @PrimaryEDIS TABLE(PrimaryEDISID INT NOT NULL, EDISID INT NOT NULL)
INSERT INTO @PrimaryEDIS
SELECT MAX(PrimaryEDISID) AS PrimaryEDISID, SiteGroupSites.EDISID
FROM(
    SELECT SiteGroupSites.SiteGroupID, SiteGroupSites.EDISID AS PrimaryEDISID
    FROM SiteGroupSites
    JOIN Sites ON Sites.EDISID = SiteGroupSites.EDISID 
    WHERE SiteGroupSites.SiteGroupID IN (SELECT ID FROM SiteGroups WHERE TypeID = 1)
    AND IsPrimary = 1
    GROUP BY SiteGroupSites.SiteGroupID, SiteGroupSites.EDISID
) AS PrimarySites
JOIN SiteGroupSites ON SiteGroupSites.SiteGroupID = PrimarySites.SiteGroupID
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

IF @DebugSites = 1
BEGIN
    --SELECT * 
    --FROM @PrimaryEDIS
    --WHERE 
    --    (@EDISID IS NULL OR [PrimaryEDISID] = @EDISID)

    SELECT
        COALESCE([PEDIS].[EDISID], [Sites].[EDISID]) AS [EDISID],
        COALESCE([PEDIS].[PrimaryEDISID], [Sites].[EDISID]) AS [PrimaryEDISID]
    FROM Sites
    LEFT JOIN @PrimaryEDIS AS [PEDIS] ON [Sites].[EDISID] = [PEDIS].[PrimaryEDISID]
    WHERE 
        (@EDISID IS NULL OR [Sites].[EDISID] = @EDISID)
END

-- Get all non-closed Calls which involve Products, stolen and modified from ExceptionNegativeTrend
DECLARE @CalRequestID INT = 33 -- Calibration request (Audit raised following data query)
DECLARE @CalRequestAllID INT = 63 -- Calibration request (Audit raised following data query)

/*
-- LEGACY LOGGER
DECLARE @ProductStart CHAR = ':'
DECLARE @ProductEnd CHAR = '('

DECLARE @CalibrationRequestForProduct TABLE ([EDISID] INT NOT NULL, [ProductID] INT NOT NULL)

/* Specific Lines */
INSERT INTO @CalibrationRequestForProduct ([EDISID], [ProductID])
SELECT
    [OpenCalls].[EDISID],
    [Products].[ID]
FROM (
    SELECT 
        --[C].[ID] AS [CallID],
        [S].[EDISID],
        --[CR].[AdditionalInfo],
        CASE 
            WHEN
                (CHARINDEX(@ProductStart, [CR].[AdditionalInfo], 0) + 1) <> 1 -- After the Start of the string
                 AND
                (CHARINDEX(@ProductEnd, [CR].[AdditionalInfo], 0) - 1 - CHARINDEX(@ProductStart, [CR].[AdditionalInfo], 0)) > 1 -- Must have found an end point
            THEN
                RTRIM(LTRIM(SUBSTRING(
                    [CR].[AdditionalInfo], 
                    (CHARINDEX(@ProductStart, [CR].[AdditionalInfo], 0) + 1), 
                    (CHARINDEX(@ProductEnd, [CR].[AdditionalInfo], 0) - 1 - CHARINDEX(@ProductStart, [CR].[AdditionalInfo], 0))
                ))) 
            ELSE
                NULL
        END AS [Product]
    FROM [dbo].[Calls] AS [C]
    JOIN [dbo].[Sites] AS [S] ON [C].[EDISID] = [S].[EDISID] 
    JOIN [dbo].[CallReasons] AS [CR]
        ON [C].[ID] = [CR].[CallID]
    WHERE [ClosedOn] IS NULL -- Only Open/Outstanding Calls
    AND [AbortReasonID] = 0 -- Not Aborted
    AND [CR].[ReasonTypeID] = @CalRequestID
    AND (CHARINDEX(@ProductStart, [CR].[AdditionalInfo], 0) + 1) <> 1
    AND (CHARINDEX(@ProductEnd, [CR].[AdditionalInfo], 0) - 1 - CHARINDEX(@ProductStart, [CR].[AdditionalInfo], 0)) > 1
    ) AS [OpenCalls]
JOIN [dbo].[Products] ON [OpenCalls].[Product] = [Products].[Description]
*/

-- JOB WATCH
DECLARE @CalibrationRequestForProduct TABLE ([EDISID] INT NOT NULL, [ProductID] INT NOT NULL)
INSERT INTO @CalibrationRequestForProduct (EDISID, ProductID)
SELECT
    [JobWatchCalls].[EdisID],
    [JobWatchCallsData].[ProductID]
FROM [dbo].[JobWatchCalls]
JOIN [dbo].[JobWatchCallsData] ON [JobWatchCalls].[JobId] = [JobWatchCallsData].[JobId]
WHERE [JobWatchCalls].[JobActive] = 1
AND [JobWatchCallsData].[CallReasonTypeID] = @CalRequestID
AND [JobWatchCallsData].[ProductID] IS NOT NULL

IF @DebugCalRequest = 1
BEGIN
    SELECT [EDISID], [ProductID] AS [Cal. Request on Product] FROM @CalibrationRequestForProduct ORDER BY [EDISID]
END


IF @DebugDispense = 1 AND @DebugProductID IS NOT NULL
BEGIN
    IF @DebugLiquidType = 1
    BEGIN
        SELECT 
            [DA].[TradingDay],
            [RelevantSites].[PrimaryEDISID],
            ISNULL([PP].[PrimaryProductID], [P].[ID]) AS [ProductID], 
            [P].[Description] AS [Product],
            [DA].[LiquidType] AS [LiquidTypeID],
            [LT].[Description] AS [LiquidType],
            SUM([DA].[EstimatedDrinks]) AS [Drinks],
            ROUND(SUM([DA].[Pints]),2) AS [Pints]
        FROM [dbo].[DispenseActions] AS [DA]
        JOIN [dbo].[Sites] AS [S] ON [DA].[EDISID] = [S].[EDISID]
        JOIN [dbo].[Products] AS [P] ON [DA].[Product] = [P].[ID]
        JOIN [dbo].[LiquidTypes] AS [LT] ON [DA].[LiquidType] = [LT].[ID]
        JOIN (
            SELECT
                COALESCE([PEDIS].[EDISID], [Sites].[EDISID]) AS [EDISID],
                COALESCE([PEDIS].[PrimaryEDISID], [Sites].[EDISID]) AS [PrimaryEDISID]
            FROM [dbo].[Sites]
            LEFT JOIN @PrimaryEDIS AS [PEDIS] ON [Sites].[EDISID] = [PEDIS].[PrimaryEDISID]
            LEFT JOIN @US_Sites AS [US] ON [Sites].[EDISID] = [US].[EDISID]
            LEFT JOIN @Other_Sites AS [OS] ON [Sites].[EDISID] = [OS].[EDISID]
            WHERE 
                (@EDISID IS NULL OR [Sites].[EDISID] = @EDISID)
            AND [US].[EDISID] IS NULL -- Exclude US
            AND [OS].[EDISID] IS NULL -- Exclude non-UK
            ) AS [RelevantSites] ON [DA].[EDISID] = [RelevantSites].[EDISID]
        FULL OUTER JOIN #PrimaryProducts AS [PP] ON [PP].[ProductID] = [P].[ID]
        JOIN [dbo].[ProductCategories] AS [PC] ON [P].[CategoryID] = [PC].[ID]
        LEFT JOIN @CalibrationRequestForProduct AS [AC] ON [DA].[EDISID] = [AC].[EDISID] AND [P].[ID] = [AC].[ProductID]
        WHERE
            [S].[LastDownload] >= @From
        AND [DA].[TradingDay] BETWEEN @From AND @To
        AND (@Auditor IS NULL OR LOWER([S].[SiteUser]) = LOWER(@Auditor))
        AND [S].[Quality] = 1 -- iDraught
        AND [AC].[ProductID] IS NULL
        AND LOWER([PC].[Description]) IN ('premium lager','standard lager','ale - keg','stout','cider','ale - cask') -- use IDs?
        AND ISNULL([PP].[PrimaryProductID], [P].[ID]) = @DebugProductID
        GROUP BY
            [DA].[TradingDay],
            [RelevantSites].[PrimaryEDISID],
            ISNULL([PP].[PrimaryProductID], [P].[ID]),
            [P].[Description],
            [DA].[LiquidType],
            [LT].[Description]
        ORDER BY 
            [RelevantSites].[PrimaryEDISID],
            [P].[Description],
            [DA].[TradingDay],
            [LT].[Description]
    END
    ELSE
    BEGIN
        SELECT 
            [DA].[TradingDay],
            [S].[EDISID],
            ISNULL([PP].[PrimaryProductID], [P].[ID]) AS [ProductID], 
            [P].[Description] AS [Product],
            SUM([DA].[EstimatedDrinks]) AS [Drinks],
            ROUND(SUM([DA].[Pints]),2) AS [Pints]
        FROM [dbo].[DispenseActions] AS [DA]
        JOIN [dbo].[Sites] AS [S] ON [DA].[EDISID] = [S].[EDISID]
        JOIN [dbo].[Products] AS [P] ON [DA].[Product] = [P].[ID]
        JOIN [dbo].[LiquidTypes] AS [LT] ON [DA].[LiquidType] = [LT].[ID]
        JOIN (
            SELECT
                COALESCE([PEDIS].[EDISID], [Sites].[EDISID]) AS [EDISID],
                COALESCE([PEDIS].[PrimaryEDISID], [Sites].[EDISID]) AS [PrimaryEDISID]
            FROM [dbo].[Sites]
            LEFT JOIN @PrimaryEDIS AS [PEDIS] ON [Sites].[EDISID] = [PEDIS].[PrimaryEDISID]
            LEFT JOIN @US_Sites AS [US] ON [Sites].[EDISID] = [US].[EDISID]
            LEFT JOIN @Other_Sites AS [OS] ON [Sites].[EDISID] = [OS].[EDISID]
            WHERE 
                (@EDISID IS NULL OR [Sites].[EDISID] = @EDISID)
            AND [US].[EDISID] IS NULL -- Exclude US
            AND [OS].[EDISID] IS NULL -- Exclude non-UK
            ) AS [RelevantSites] ON [DA].[EDISID] = [RelevantSites].[EDISID]
        FULL OUTER JOIN #PrimaryProducts AS [PP] ON [PP].[ProductID] = [P].[ID]
        JOIN [dbo].[ProductCategories] AS [PC] ON [P].[CategoryID] = [PC].[ID]
        LEFT JOIN @CalibrationRequestForProduct AS [AC] ON [DA].[EDISID] = [AC].[EDISID] AND [P].[ID] = [AC].[ProductID]
        WHERE
            [S].[LastDownload] >= @From
        AND [DA].[TradingDay] BETWEEN @From AND @To
        AND (@Auditor IS NULL OR LOWER([S].[SiteUser]) = LOWER(@Auditor))
        AND [S].[Quality] = 1 -- iDraught
        AND [DA].[LiquidType] IN (2) -- Product
        AND [AC].[ProductID] IS NULL
        AND LOWER([PC].[Description]) IN ('premium lager','standard lager','ale - keg','stout','cider','ale - cask') -- use IDs?
        AND ISNULL([PP].[PrimaryProductID], [P].[ID]) = @DebugProductID
        GROUP BY
            [DA].[TradingDay],
            [S].[EDISID],
            ISNULL([PP].[PrimaryProductID], [P].[ID]),
            [P].[Description]
        ORDER BY 
            [P].[Description],
            [DA].[TradingDay]
    END
END

IF @DebugDispense = 1
BEGIN
    SELECT 
        --[DA].[TradingDay],
        [RelevantSites].[PrimaryEDISID],
        [RelevantSites].[EDISID],
        ISNULL([PP].[PrimaryProductID], [P].[ID]) AS [ProductID], 
        [P].[Description] AS [Product],
        SUM(CASE WHEN [DA].[LiquidType] = 2 THEN [DA].[EstimatedDrinks] ELSE NULL END) AS [Drinks],
        ROUND(SUM([DA].[Pints]),2) AS [Pints]
    FROM [dbo].[DispenseActions] AS [DA]
    JOIN [dbo].[Sites] AS [S] ON [DA].[EDISID] = [S].[EDISID]
    JOIN [dbo].[Products] AS [P] ON [DA].[Product] = [P].[ID]
    JOIN (
            SELECT
                COALESCE([PEDIS].[EDISID], [Sites].[EDISID]) AS [EDISID],
                COALESCE([PEDIS].[PrimaryEDISID], [Sites].[EDISID]) AS [PrimaryEDISID]
            FROM [dbo].[Sites]
            LEFT JOIN @PrimaryEDIS AS [PEDIS] ON [Sites].[EDISID] = [PEDIS].[PrimaryEDISID]
            LEFT JOIN @US_Sites AS [US] ON [Sites].[EDISID] = [US].[EDISID]
            LEFT JOIN @Other_Sites AS [OS] ON [Sites].[EDISID] = [OS].[EDISID]
            WHERE 
                (@EDISID IS NULL OR [Sites].[EDISID] = @EDISID)
            AND [US].[EDISID] IS NULL -- Exclude US
            AND [OS].[EDISID] IS NULL -- Exclude non-UK
            ) AS [RelevantSites] ON [DA].[EDISID] = [RelevantSites].[EDISID]
    FULL OUTER JOIN #PrimaryProducts AS [PP] ON [PP].[ProductID] = [P].[ID]
    JOIN [dbo].[ProductCategories] AS [PC] ON [P].[CategoryID] = [PC].[ID]
    LEFT JOIN @US_Sites AS [US] ON [S].[EDISID] = [US].[EDISID]
    LEFT JOIN @Other_Sites AS [OS] ON [S].[EDISID] = [OS].[EDISID]
    LEFT JOIN @CalibrationRequestForProduct AS [AC] ON [DA].[EDISID] = [AC].[EDISID] AND [P].[ID] = [AC].[ProductID]
    WHERE
        [S].[LastDownload] >= @From
    AND [DA].[TradingDay] BETWEEN @From AND @To
    AND (@Auditor IS NULL OR LOWER([S].[SiteUser]) = LOWER(@Auditor))
    AND [S].[Quality] = 1 -- iDraught
    AND [DA].[LiquidType] IN (2) -- Product
    AND [AC].[ProductID] IS NULL
    AND LOWER([PC].[Description]) IN ('premium lager','standard lager','ale - keg','stout','cider','ale - cask') -- use IDs?
    GROUP BY
        --[DA].[TradingDay],
        [RelevantSites].[PrimaryEDISID],
        [RelevantSites].[EDISID],
        [P].[Description],
        ISNULL([PP].[PrimaryProductID], [P].[ID])
    ORDER BY 
        [RelevantSites].[PrimaryEDISID],
        [P].[Description]
        --[DA].[TradingDay]
END

CREATE TABLE #Exceptions ([EDISID] INT NOT NULL, [Product] VARCHAR(50) NOT NULL, [Type] VARCHAR(255) NOT NULL, [Status] INT NOT NULL)
INSERT INTO #Exceptions ([EDISID], [Product], [Type], [Status])
SELECT
    [EDISID],
    [Product],
    [Type],
    MIN([Status]) AS [Status]
FROM (
    SELECT 
        [TD].[EDISID],
        [P].[Description] AS [Product], 
        CASE WHEN (LOWER([PC].[Description]) IN ('premium lager','standard lager','ale - keg','stout'))
             THEN 'Lager, Keg Ale, Smooth & Stout'
             WHEN (LOWER([PC].[Description]) IN ('cider','ale - cask'))
             THEN 'Cider, Cask Ale'
             ELSE 'Unknown'
             END + ' (' + CAST([TD].[Yield] AS VARCHAR(10)) + '%)'  AS [Type],
        CASE WHEN (LOWER([PC].[Description]) IN ('premium lager','standard lager','ale - keg','stout'))
             THEN    -- Keg
                 CASE WHEN ([TD].[Yield] < @Keg_Amber_Lower_Min OR [TD].[Yield] > @Keg_Amber_Higher_Max)
                     THEN 1 -- Red
                     ELSE 2 -- Amber
                     END
             WHEN (LOWER([PC].[Description]) IN ('cider','ale - cask'))
             THEN    -- Cask
                 CASE WHEN ([TD].[Yield] < @Cask_Amber_Lower_Min OR [TD].[Yield] > @Cask_Amber_Higher_Max)
                     THEN 1 -- Red
                     ELSE 2 -- Amber
                     END
             END AS [Status]
    FROM (
        SELECT
            [EDISID],
            [ProductID],
            ROUND(([Drinks] / [Pints]) * 100, 0) AS [Yield]
        FROM (
            SELECT 
                [RelevantSites].[PrimaryEDISID] AS [EDISID],
                ISNULL([PP].[PrimaryProductID], [P].[ID]) AS [ProductID], 
                SUM(CASE WHEN [DA].[LiquidType] = 2 THEN [DA].[EstimatedDrinks] ELSE NULL END) AS [Drinks],
                SUM([DA].[Pints]) AS [Pints]
            FROM [dbo].[DispenseActions] AS [DA]
            JOIN [dbo].[Sites] AS [S] ON [DA].[EDISID] = [S].[EDISID]
            JOIN [dbo].[Products] AS [P] ON [DA].[Product] = [P].[ID]
            JOIN (
                SELECT
                    COALESCE([PEDIS].[EDISID], [Sites].[EDISID]) AS [EDISID],
                    COALESCE([PEDIS].[PrimaryEDISID], [Sites].[EDISID]) AS [PrimaryEDISID]
                FROM [dbo].[Sites]
                LEFT JOIN @PrimaryEDIS AS [PEDIS] ON [Sites].[EDISID] = [PEDIS].[PrimaryEDISID]
                LEFT JOIN @US_Sites AS [US] ON [Sites].[EDISID] = [US].[EDISID]
                LEFT JOIN @Other_Sites AS [OS] ON [Sites].[EDISID] = [OS].[EDISID]
                WHERE 
                    (@EDISID IS NULL OR [Sites].[EDISID] = @EDISID)
                AND [US].[EDISID] IS NULL -- Exclude US
                AND [OS].[EDISID] IS NULL -- Exclude non-UK
            ) AS [RelevantSites] ON [DA].[EDISID] = [RelevantSites].[EDISID]
            FULL OUTER JOIN #PrimaryProducts AS [PP] ON [PP].[ProductID] = [P].[ID]
            JOIN [dbo].[ProductCategories] AS [PC] ON [P].[CategoryID] = [PC].[ID]
            LEFT JOIN @US_Sites AS [US] ON [S].[EDISID] = [US].[EDISID]
            LEFT JOIN @Other_Sites AS [OS] ON [S].[EDISID] = [OS].[EDISID]
            LEFT JOIN @CalibrationRequestForProduct AS [AC] ON [DA].[EDISID] = [AC].[EDISID] AND [P].[ID] = [AC].[ProductID]
            WHERE
                [S].[LastDownload] >= @From
            AND [DA].[TradingDay] BETWEEN @From AND @To
            AND (@Auditor IS NULL OR LOWER([S].[SiteUser]) = LOWER(@Auditor))
            AND [S].[Quality] = 1 -- iDraught
            AND [DA].[LiquidType] IN (2) -- Product
            AND [AC].[ProductID] IS NULL
            AND LOWER([PC].[Description]) IN ('premium lager','standard lager','ale - keg','stout','cider','ale - cask') -- use IDs?
            GROUP BY
                [RelevantSites].[PrimaryEDISID],
                ISNULL([PP].[PrimaryProductID], [P].[ID]) 
            ) AS [TotalDispense]
        WHERE [Drinks] <> 0 AND [Pints] <> 0 -- Ignore products that would attempt to divide by zero or calculate 0%
        ) AS [TD]
    JOIN [dbo].[Products] AS [P] ON [TD].[ProductID] = [P].[ID]
    JOIN [dbo].[ProductCategories] AS [PC] ON [P].[CategoryID] = [PC].[ID]
    WHERE
        (
        /* ***************     UK: Keg                                                       *************** */
            ((LOWER([PC].[Description]) IN ('premium lager','standard lager','ale - keg','stout'))    -- Lager, Keg, Smooth, Stout
                AND 
            ([TD].[Yield] <= @Keg_Amber_Lower_Max OR [TD].[Yield] >= @Keg_Amber_Higher_Min))
        /* ***************     UK: Keg                                                       *************** */

        /* ***************     UK: Cask                                                      *************** */
        OR
            ((LOWER([PC].[Description]) IN ('cider','ale - cask'))    -- Cider, Cask
                AND 
            ([TD].[Yield] <= @Cask_Amber_Lower_Max OR [TD].[Yield] >= @Cask_Amber_Higher_Min))
        /* ***************     UK: Cask                                                      *************** */
        )
    ) AS [Exceptions]
GROUP BY
    [EDISID],
    [Product],
    [Type]
ORDER BY 
    [EDISID],
    [Product],
    [Type]

IF @DebugSites = 0
BEGIN
    SELECT 
        [EDISID],
        (CASE
            WHEN [Status] = 1 THEN 'Red'
            WHEN [Status] = 2 THEN 'Amber'
         END) + ' - ' + [EquipmentList] AS [Detail]
    FROM (
        SELECT
            [E].[EDISID],
            MIN([Status]) AS [Status],
            MIN([Info].[EquipmentList]) AS [EquipmentList]
        FROM #Exceptions AS [E]
        JOIN (
            SELECT DISTINCT
                [EDISID],
                SUBSTRING(
                    (   SELECT ';' + [Product] + '|' + [Type] + '|' + (CASE WHEN [Status] = 1 THEN 'Red' WHEN [Status] = 2 THEN 'Amber' END) 
                        FROM #Exceptions
                        WHERE [EDISID] = [E].[EDISID]
                        AND (@RedOnly = 0 OR (@RedOnly = 1 AND [Status] = 1)) 
                        FOR XML PATH (''), TYPE).value('.','VARCHAR(4000)')
                    ,2, 4000) AS [EquipmentList]
            FROM #Exceptions AS [E]
            ) AS [Info] ON [E].[EDISID] = [Info].[EDISID]
        GROUP BY 
            [E].[EDISID]
        ) AS [Exceptions]
    WHERE
        (CASE
            WHEN [Status] = 1 THEN 'Red'
            WHEN [Status] = 2 THEN 'Amber'
         END) + ' - ' + [EquipmentList] IS NOT NULL
END
ELSE
BEGIN
    SELECT 
        [Exceptions].[EDISID],
        [SiteID],
        (CASE
            WHEN [Exceptions].[Status] = 1 THEN 'Red'
            WHEN [Exceptions].[Status] = 2 THEN 'Amber'
         END) + ' - ' + [EquipmentList] AS [Detail]
    FROM (
        SELECT
            [E].[EDISID],
            MIN([Status]) AS [Status],
            MIN([Info].[EquipmentList]) AS [EquipmentList]
        FROM #Exceptions AS [E]
        JOIN (
            SELECT DISTINCT
                [EDISID],
                SUBSTRING(
                    (   SELECT ';' + [Product] + '|' + [Type] + '|' + (CASE WHEN [Status] = 1 THEN 'Red' WHEN [Status] = 2 THEN 'Amber' END) 
                        FROM #Exceptions
                        WHERE [EDISID] = [E].[EDISID]
                        AND (@RedOnly = 0 OR (@RedOnly = 1 AND [Status] = 1)) 
                        FOR XML PATH (''), TYPE).value('.','VARCHAR(4000)')
                    ,2, 4000) AS [EquipmentList]
            FROM #Exceptions AS [E]
            ) AS [Info] ON [E].[EDISID] = [Info].[EDISID]
        GROUP BY 
            [E].[EDISID]
        ) AS [Exceptions]
        JOIN [dbo].[Sites] AS [S] ON [Exceptions].[EDISID] = [S].[EDISID]
    WHERE
        (CASE
            WHEN [Exceptions].[Status] = 1 THEN 'Red'
            WHEN [Exceptions].[Status] = 2 THEN 'Amber'
         END) + ' - ' + [EquipmentList] IS NOT NULL
END

DROP TABLE #Exceptions
DROP TABLE #PrimaryProducts

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ExceptionPouringYieldIssue] TO PUBLIC
    AS [dbo];

