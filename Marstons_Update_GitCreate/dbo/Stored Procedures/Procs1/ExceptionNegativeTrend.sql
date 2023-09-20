CREATE PROCEDURE [dbo].[ExceptionNegativeTrend] 
(
    @EDISID INT = NULL,
	@Auditor varchar(255) = NULL
)
AS

/* For Testing */ 
--DECLARE @Auditor VARCHAR(50) = NULL
--DECLARE @EDISID INT = NULL --30
--DECLARE @SiteID VARCHAR (15) = NULL --'201865'
--IF @SiteID IS NOT NULL
--    SELECT @EDISID = [EDISID] FROM [dbo].[Sites] WHERE [SiteID] = @SiteID

SET NOCOUNT ON;
SET DATEFIRST 1;

DECLARE @EnableLogging BIT = 1
DECLARE @EnableComments BIT = 1
DECLARE @EnableRankings BIT = 1
DECLARE @DebugProduct VARCHAR(50) = ''
DECLARE @DebugSite BIT = 0
DECLARE @DebugParameters BIT = 0
DECLARE @DebugAverage BIT = 0
DECLARE @DebugVariance BIT = 0
DECLARE @DebugDates BIT = 0
DECLARE @DebugNewProduct BIT = 0
DECLARE @DebugCalRequest BIT = 0
DECLARE @DebugVisitRecord BIT = 0
DECLARE @DebugComments BIT = 0

DECLARE @AuditWeeksBack INT = 1
SELECT @AuditWeeksBack = ISNULL(CAST([PropertyValue] AS INTEGER), 1) FROM [dbo].[Configuration] WHERE [PropertyName] = 'AuditWeeksBehind'

--Get Audit Day for customer, the day in which the audit period will be classed as an extra week forward
DECLARE @AuditDay INT
SELECT @AuditDay = ISNULL(CAST([PropertyValue] AS INTEGER), NULL) FROM [dbo].[Configuration] WHERE [PropertyName] = 'AuditDay'

DECLARE @BaseFrom DATETIME
DECLARE @BaseTo DATETIME

-- Calculate the latest week (used to generate proper date ranges later)
IF @AuditDay IS NOT NULL
BEGIN
	--Get Current Day
	DECLARE @CurrentDay INT
	SET @CurrentDay = DATEPART(dw,GETDATE())

	IF @CurrentDay >= @AuditDay
		BEGIN
            SET @BaseFrom = DATEADD(WEEK, -(@AuditWeeksBack-2), DATEADD(WEEK, DATEDIFF(WEEK, 6, GETDATE()), 0))
            SET @BaseTo = DATEADD(WEEK, -(@AuditWeeksBack-2), DATEADD(WEEK, DATEDIFF(WEEK, 6, GETDATE()), 6))
			--SET @CurrentWeekFrom = DATEADD(WEEK, -(@AuditWeeksBack-2), DATEADD(WEEK, DATEDIFF(WEEK, 6, GETDATE()), 0)) --take back 1 and a half weeks
		END
	ELSE
		BEGIN 
            SET @BaseFrom = DATEADD(WEEK, -(@AuditWeeksBack-1), DATEADD(WEEK, DATEDIFF(WEEK, 6, GETDATE()), 0))
            SET @BaseTo = DATEADD(WEEK, -(@AuditWeeksBack-1), DATEADD(WEEK, DATEDIFF(WEEK, 6, GETDATE()), 6))
			--SET @CurrentWeekFrom = DATEADD(WEEK, -(@AuditWeeksBack-1), DATEADD(WEEK, DATEDIFF(WEEK, 6, GETDATE()), 0)) -- take back 2 weeks
		END
END
ELSE
BEGIN 
    SET @BaseFrom = DATEADD(WEEK, -(@AuditWeeksBack-1), DATEADD(WEEK, DATEDIFF(WEEK, 6, GETDATE()), 0))
    SET @BaseTo = DATEADD(WEEK, -(@AuditWeeksBack-1), DATEADD(WEEK, DATEDIFF(WEEK, 6, GETDATE()), 6))
	--SET @CurrentWeekFrom = DATEADD(WEEK, -(@AuditWeeksBack-1), DATEADD(WEEK, DATEDIFF(WEEK, 6, GETDATE()), 0))
END

/* For testing */
--SET @EnableLogging = 0
--SET @EnableComments = 0
--SET @EnableRankings = 0
--SET @DebugSite = 1
--SET @DebugDates = 1
--SET @DebugParameters = 1
--SET @DebugAverage = 1
--SET @DebugVariance = 1
--SET @DebugProduct = 'Kronenbourg 1664'
--SET @DebugNewProduct = 1
--SET @DebugCalRequest = 1
--SET @DebugVisitRecord = 1
--SET @DebugComments = 1
--SET @BaseFrom = DATEADD(WEEK, -1, @BaseFrom) 
--SET @BaseTo = DATEADD(WEEK, -1, @BaseTo)

/* Moved out of IF for easier access and to remove debugging variable interference (@EnableComments=0 would invalidate these previously) */
DECLARE @CommentTemplateNA VARCHAR(4000) = 'N/A'
DECLARE @CommentTemplateGood VARCHAR(4000) = 'No current Issues at site'
DECLARE @CommentTemplateBad VARCHAR(4000) = 'Negative variance on {products}'
DECLARE @CommentTemplateUgly VARCHAR(4000) = 'Significant Negative variance on {products}'

DECLARE @EndDate DATE = @BaseTo
DECLARE @MinNewProd DATE = DATEADD(WEEK, -2, @BaseFrom) -- New Product Exception (examine 3 Weeks)
DECLARE @MinData DATE = DATEADD(WEEK, -3, @BaseFrom) -- New Installs (req. 4 Weeks min.), Otherwise (up to 18 weeks)
DECLARE @MaxData DATE = DATEADD(WEEK, -17, @BaseFrom)
DECLARE @ExtendedData DATE = DATEADD(WEEK, -20, @BaseFrom)
DECLARE @MinStock DATE
DECLARE @StockWeeksBack INT
DECLARE @TrendThreshold INT = -5 -- Defines when a Trend begins/ends

SELECT @StockWeeksBack = [PropertyValue] FROM [dbo].[Configuration] WHERE [PropertyName] = 'Oldest Stock Weeks Back'

SET @MinStock = DATEADD(WEEK, -@StockWeeksBack, @MaxData)

--SELECT @MaxData

IF @EnableLogging = 1
BEGIN
    DECLARE @DatabaseID INT
    SELECT @DatabaseID = [ID] FROM [SQL1\SQL1].[ServiceLogger].[dbo].[EDISDatabases] WHERE [Name] = DB_NAME()
    DECLARE @NotificationTypeID INT
    SELECT @NotificationTypeID = [NotificationTypeID] FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationType] WHERE [StoredProcedure] = OBJECT_NAME(@@PROCID)
    IF @NotificationTypeID IS NOT NULL
    BEGIN
        EXEC [SQL1\SQL1].[Auditing].[dbo].[AddNotificationTypeGenerationLog] @NotificationTypeID, @DatabaseID, @EDISID, @MaxData, @EndDate
    END
END

IF @DebugDates = 1
BEGIN
    SELECT 
        @ExtendedData AS [ExtendedFromDate], 
        @MaxData AS [StandardFromDate], 
        @MinData AS [MinimumFromDate], 
        @EndDate AS [ToDate],
    --    --@MinNewProd AS [MinimumNewProductFromDate]
    --    --@MinStock AS [MinimumStockFromDate]
        DATEADD(DAY, -6, @EndDate) AS [ToWC]
END

CREATE TABLE #Variance (
    [EDISID] INT NOT NULL,
    [WeekCommencing] DATE NOT NULL, 
    [Product] VARCHAR(50) NOT NULL,
    [ProductCategory] VARCHAR(255) NOT NULL,
    [IsCask] BIT NOT NULL, 
    [IsKeg] BIT NOT NULL, 
    [IsMetric] BIT NOT NULL, 
    [Dispensed] FLOAT NOT NULL, 
    [Delivered] FLOAT NOT NULL, 
    [Variance] FLOAT NOT NULL, 
    [ExtendedCumulativeVariance] FLOAT NOT NULL DEFAULT(0),
    [StandardCumulativeVariance] FLOAT NOT NULL DEFAULT(0),
    [IsAdjusted] BIT NOT NULL DEFAULT (0),
    [ExtendedTrending] BIT NOT NULL DEFAULT(0), -- Up to 21 Week Period
    [ExtendedTrend] FLOAT,                      -- Up to 21 Week Period
    [ExtendedTrendTotal] FLOAT,                 -- Up to 21 Week Period
    [StandardTrending] BIT NOT NULL DEFAULT(0), -- Up to 18 Week Period
    [StandardTrend] FLOAT,                      -- Up to 18 Week Period
    [StandardTrendTotal] FLOAT,                 -- Up to 18 Week Period
    [ID] INT IDENTITY (1,1), -- Req. to work around SQL Server bug (https://support.microsoft.com/en-gb/kb/960770)
    UNIQUE CLUSTERED ([EDISID], [WeekCommencing], [Product])
    )

-- Unit Conversion
DECLARE @ToGallons FLOAT = 0.125     -- {Pint Value} * @ToGallons
DECLARE @ToLitres FLOAT = 0.568261   -- {Pint Value} * @ToLitres

-- Configuration
DECLARE @Amber_KegGallons INT
DECLARE @Amber_CaskGallons INT
DECLARE @Amber_SyrupLitres INT
DECLARE @Amber_Percent INT
DECLARE @Amber_PercentHigh INT
DECLARE @Amber_AverageDispense INT
DECLARE @Amber_TotalGallons INT

DECLARE @Red_KegGallons INT
DECLARE @Red_CaskGallons INT
DECLARE @Red_SyrupLitres INT
DECLARE @Red_Percent INT
DECLARE @Red_PercentHigh INT
DECLARE @Red_AverageDispense INT
DECLARE @Red_TotalGallons INT

SELECT  @Amber_KegGallons = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'AmberTrendKeg-Gallons'
SELECT  @Amber_CaskGallons = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'AmberTrendCask-Gallons'
SELECT  @Amber_SyrupLitres = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'AmberTrendSyrup-Litres'

SELECT  @Amber_Percent = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'AmberTrendTotal-Percent'
SELECT  @Amber_PercentHigh = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'AmberTrendTotal-PercentHigh'

SELECT  @Red_KegGallons = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'RedTrendKeg-Gallons'
SELECT  @Red_CaskGallons = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'RedTrendCask-Gallons'
SELECT  @Red_SyrupLitres = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'RedTrendSyrup-Litres'

SELECT  @Red_Percent = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'RedTrendTotal-Percent'
SELECT  @Red_PercentHigh = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'RedTrendTotal-PercentHigh'

SELECT  @Amber_AverageDispense = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'AmberDispenseAverage-Gallons'
SELECT  @Red_AverageDispense = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'RedDispenseAverage-Gallons'
SELECT  @Amber_TotalGallons = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'AmberTrendTotal-Gallons'
SELECT  @Red_TotalGallons = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'RedTrendTotal-Gallons'


--SELECT 
--    @Amber_KegGallons =  CASE WHEN [ParameterName] = 'AmberTrendKeg-Gallons'        THEN CAST([NP].[ParameterValue] AS INT) ELSE @Amber_KegGallons   END,
--    @Amber_CaskGallons =  CASE WHEN [ParameterName] = 'AmberTrendCask-Gallons'      THEN CAST([NP].[ParameterValue] AS INT) ELSE @Amber_CaskGallons   END,
--    @Amber_SyrupLitres = CASE WHEN [ParameterName] = 'AmberTrendSyrup-Litres'       THEN CAST([NP].[ParameterValue] AS INT) ELSE @Amber_SyrupLitres  END,
--    @Amber_Percent = CASE WHEN [ParameterName] = 'AmberTrendTotal-Percent'          THEN CAST([NP].[ParameterValue] AS INT) ELSE @Amber_Percent  END,

--    @Red_KegGallons =  CASE WHEN [ParameterName] = 'RedTrendKeg-Gallons'     THEN CAST([NP].[ParameterValue] AS INT) ELSE @Red_KegGallons   END,
--    @Red_CaskGallons =  CASE WHEN [ParameterName] = 'RedTrendCask-Gallons'    THEN CAST([NP].[ParameterValue] AS INT) ELSE @Red_CaskGallons   END,
--    @Red_SyrupLitres = CASE WHEN [ParameterName] = 'RedTrendSyrup-Litres'     THEN CAST([NP].[ParameterValue] AS INT) ELSE @Red_SyrupLitres  END,
--    @Red_Percent = CASE WHEN [ParameterName] = 'RedTrendTotal-Percent'     THEN CAST([NP].[ParameterValue] AS INT) ELSE @Red_Percent  END

--FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP]

IF @DebugParameters = 1
BEGIN
SELECT 
    @Amber_KegGallons AS Amber_KegGallons, 
    @Amber_CaskGallons AS Amber_CaskGallons, 
    @Amber_SyrupLitres AS Amber_SyrupLitres, 
    @Amber_Percent AS Amber_Percent,
    @Amber_PercentHigh AS Amber_PercentHigh,
    @Amber_AverageDispense AS Amber_AverageDispense,
    @Amber_TotalGallons AS Amber_TotalGallons,
    @Red_KegGallons AS Red_KegGallons, 
    @Red_CaskGallons AS Red_CaskGallons, 
    @Red_SyrupLitres AS Red_SyrupLitres, 
    @Red_Percent AS Red_Percent,
    @Red_PercentHigh AS Red_PercentHigh,
    @Red_AverageDispense AS Red_AverageDispense,
    @Red_TotalGallons AS Red_TotalGallons
END

/* **************************************************************************************************************************************************
    Site List

    As each Site will have it's own conditions that could affect the Date Range we need to work on, we need to generate a
    list of From & To dates that are custom for every Site.
    Some Sites will gain NULL values for their From/To dates, this indicates that something about the Site makes it unusable.
*/
CREATE TABLE #Sites ([EDISID] INT NOT NULL PRIMARY KEY, [SuperFromDate] DATE, [FromDate] DATE, [ToDate] DATE, [VisitDate] DATE, [COTDate] DATE)

/* ************************************************************* */
/* See Service Desk Ticket 20488 for why this abomination exists */

DECLARE @DatabaseHack VARCHAR(200)
SET @DatabaseHack = DB_NAME()

IF @DatabaseHack = 'Punch'
BEGIN
    -- Punch Exclusive Logic
    --  Prevents VRS/COT from having any meaningful impact on the site selection
    INSERT INTO #Sites ([EDISID], [SuperFromDate], [FromDate], [ToDate], [VisitDate], [COTDate])
    SELECT 
        [S].[EDISID],
        CASE    -- If Site Online is after Minimum From, we cannot use this Site
                WHEN [S].[SiteOnline] > @MinData THEN NULL
                -- If Site Online is after the Extended From date, set it to be the new "Extended From"
                WHEN [S].[SiteOnline] >= @ExtendedData THEN CAST([S].[SiteOnline] AS DATE)
                ELSE @ExtendedData
                END AS [SuperFromDate], -- Calculate the Extended From Date taking the Site Online and Visit Dates into account
        CASE    -- If Site Online is after Minimum From, we cannot use this Site
                WHEN [S].[SiteOnline] > @MinData THEN NULL
                -- If Site Online is after the From date, set it to be the new "From"
                WHEN [S].[SiteOnline] >= @MaxData THEN CAST([S].[SiteOnline] AS DATE)
                ELSE @MaxData
                END AS [FromDate], -- Calculate the Standard From Date taking the Site Online and Visit Dates into account
        CASE    -- If Site Online is after Minimum From, we cannot use this Site
                WHEN [S].[SiteOnline] > @MinData THEN NULL
                -- If VRS Visit is later than all other dates, we cannot use this Site
                WHEN [VR].[WeekCommencing] IS NOT NULL AND [VR].[WeekCommencing] > @EndDate THEN NULL
                -- If COT is later than all other dates, we cannot use this Site
                WHEN [COT].[WeekCommencing] IS NOT NULL AND [COT].[WeekCommencing] > @EndDate THEN NULL
                -- Nothing can override the To date
                ELSE @EndDate 
                END AS [ToDate],
        [VR].[WeekCommencing] AS [VisitDate],	-- Not used for Punch
        [COT].[WeekCommencing] AS [COTDate]--,	-- Not used for Punch
        --[Excluded].[StockDate] AS [DebugStockDate]
    FROM [dbo].[Sites] AS [S]
    LEFT JOIN (
        SELECT
            [VR].[EDISID],
            --COUNT([VD].DamagesID) AS [Damages],
            --MAX([VR].[VisitDate]) AS [LatestVisit],
            MAX(CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, [VR].[VisitDate]), 0) AS DATE)) AS [WeekCommencing]
        FROM [dbo].[VisitRecords] AS [VR]
        JOIN [dbo].[VisitDamages] AS [VD] ON [VR].[ID] = [VD].[VisitRecordID]
        JOIN [dbo].[Sites] AS [S] ON [VR].[EDISID] = [S].[EDISID]
        WHERE 
            --[VR].[DamagesObtained] = 1
        --AND [VR].[Deleted] = 0
            [S].[SiteOnline] <= [VR].[VisitDate]
        --AND (@EDISID IS NULL OR [S].[EDISID] = @EDISID)
        AND [VR].[VisitOutcomeID] IN 
            (1,2,7,9,11) /*
             1  - Buying-out - full admission (lessee), 
             2  - Buying-out - full admission (not lessee), 
             7  - Tampering found - full admission, 
             9  - Tampering found - no admission (admitted buying out), 
             11 - Buying-out & Tampering - Full admission
             */
        AND [VR].[VisitDate] >= @MaxData -- Anything earlier is irrelevant 
        AND [VR].[VisitDate] <= @EndDate -- Anything later is not yet relevant
        GROUP BY 
            [VR].[EDISID]
        ) AS [VR] ON [S].[EDISID] = [VR].[EDISID]
    LEFT JOIN (
        SELECT
            [SC].[EDISID],
            MAX(CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, [SC].[Date]), 0) AS DATE)) AS [WeekCommencing]
        FROM [dbo].[SiteComments] AS [SC]
        WHERE 
            [SC].[HeadingType] IN (3004) -- Change of Tenancy  (16 also exists, but doesn't appear to be used anymore?)
        AND [SC].[Date] >= @MaxData -- Anything earlier is irrelevant6
        AND [SC].[Date] <= @EndDate -- Anything later is not yet relevant
        GROUP BY 
            [SC].[EDISID]
        ) AS [COT] ON [S].[EDISID] = [COT].[EDISID]
    LEFT JOIN (
        SELECT 
            [S].[EDISID],
            MAX([MD].[Date]) AS [LatestStock]
        FROM [dbo].[Sites] AS [S]
        JOIN [dbo].[MasterDates] AS [MD] ON [S].[EDISID] = [MD].[EDISID]
        JOIN [dbo].[Stock] AS [St] ON [MD].[ID] = [St].[MasterDateID] 
        WHERE ([MD].[Date] >= @MinStock AND [MD].[Date] <= @EndDate)
	    AND [MD].[Date] >= [S].[SiteOnline]
        GROUP BY [S].[EDISID]
        ) AS [Excluded] ON [S].[EDISID] = [Excluded].[EDISID]
    WHERE 
        [S].[Hidden] = 0
    AND (@EDISID IS NULL OR [S].[EDISID] = @EDISID)
    AND	(@Auditor IS NULL OR LOWER([S].[SiteUser]) = LOWER(@Auditor))
    AND [S].[Status] IN (1,2,3,10) -- Active, Closed, Legals & Free-of-Tie
    AND [Excluded].[EDISID] IS NULL -- If a Site has Stock within the last 18 weeks, WE DON'T WANT IT!
END
/* See Service Desk Ticket 20488 for why this abomination exists */
/* ************************************************************* */
ELSE
BEGIN
    -- Standard Logic
    INSERT INTO #Sites ([EDISID], [SuperFromDate], [FromDate], [ToDate], [VisitDate], [COTDate])
    SELECT 
        [S].[EDISID],
        --[S].[SiteOnline],
        --[VR].[LatestVisit],
        --@ExtendedData AS [BigDaddyFrom],
        --@MaxData AS [BasicFrom],
        --@MinData AS [BabyFrom],
        CASE    -- If Site Online is after Minimum From, we cannot use this Site
                WHEN [S].[SiteOnline] > @MinData THEN NULL
                -- If VRS Visit is later than all other dates, we cannot use this Site
                WHEN [VR].[WeekCommencing] IS NOT NULL AND [VR].[WeekCommencing] > @EndDate THEN NULL
                -- If COT is later than all other dates, we cannot use this Site
                WHEN [COT].[WeekCommencing] IS NOT NULL AND [COT].[WeekCommencing] > @EndDate THEN NULL
                -- If Site Online is after the Extended From date, set it to be the new "Extended From"
                WHEN [S].[SiteOnline] >= @ExtendedData THEN CAST([S].[SiteOnline] AS DATE)
                -- No overriding conditions detected, use "Extended From" (unless VRS Visit or COT override)
                --ELSE CASE WHEN @ExtendedData >= COALESCE([VR].[WeekCommencing], @ExtendedData) AND @ExtendedData >= COALESCE([COT].[WeekCommencing], @ExtendedData) THEN @ExtendedData
                --          WHEN COALESCE([COT].[WeekCommencing], @ExtendedData) >= COALESCE([VR].[WeekCommencing], COALESCE([COT].[WeekCommencing], @ExtendedData)) THEN COALESCE([COT].[WeekCommencing], @ExtendedData)
                --          ELSE COALESCE([VR].[WeekCommencing], @ExtendedData)
                --          END
                ELSE @ExtendedData
                END AS [SuperFromDate], -- Calculate the Extended From Date taking the Site Online and Visit Dates into account
        CASE    -- If Site Online is after Minimum From, we cannot use this Site
                WHEN [S].[SiteOnline] > @MinData THEN NULL
                -- If VRS Visit is later than all other dates, we cannot use this Site
                WHEN [VR].[WeekCommencing] IS NOT NULL AND [VR].[WeekCommencing] > @EndDate THEN NULL
                -- If COT is later than all other dates, we cannot use this Site
                WHEN [COT].[WeekCommencing] IS NOT NULL AND [COT].[WeekCommencing] > @EndDate THEN NULL
                -- If Site Online is after the From date, set it to be the new "From"
                WHEN [S].[SiteOnline] >= @MaxData THEN CAST([S].[SiteOnline] AS DATE)
                -- No overriding conditions detected, use "Extended From"
                --ELSE CASE WHEN @MaxData >= COALESCE([VR].[WeekCommencing], @MaxData) AND @MaxData >= COALESCE([COT].[WeekCommencing], @MaxData) THEN @MaxData
                --          WHEN COALESCE([COT].[WeekCommencing], @MaxData) >= COALESCE([VR].[WeekCommencing], COALESCE([COT].[WeekCommencing], @MaxData)) THEN COALESCE([COT].[WeekCommencing], @MaxData)
                --          ELSE COALESCE([VR].[WeekCommencing], @MaxData)
                --          END
                ELSE @MaxData
                END AS [FromDate], -- Calculate the Standard From Date taking the Site Online and Visit Dates into account
        CASE    -- If Site Online is after Minimum From, we cannot use this Site
                WHEN [S].[SiteOnline] > @MinData THEN NULL
                -- If VRS Visit is later than all other dates, we cannot use this Site
                WHEN [VR].[WeekCommencing] IS NOT NULL AND [VR].[WeekCommencing] > @EndDate THEN NULL
                -- If COT is later than all other dates, we cannot use this Site
                WHEN [COT].[WeekCommencing] IS NOT NULL AND [COT].[WeekCommencing] > @EndDate THEN NULL
                -- Nothing can override the To date
                ELSE @EndDate 
                END AS [ToDate],
        [VR].[WeekCommencing] AS [VisitDate],
        [COT].[WeekCommencing] AS [COTDate]--,
        --[Excluded].[StockDate] AS [DebugStockDate]
    FROM [dbo].[Sites] AS [S]
    LEFT JOIN (
        SELECT
            [VR].[EDISID],
            --COUNT([VD].DamagesID) AS [Damages],
            --MAX([VR].[VisitDate]) AS [LatestVisit],
            MAX(CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, [VR].[VisitDate]), 0) AS DATE)) AS [WeekCommencing]
        FROM [dbo].[VisitRecords] AS [VR]
        JOIN [dbo].[VisitDamages] AS [VD] ON [VR].[ID] = [VD].[VisitRecordID]
        JOIN [dbo].[Sites] AS [S] ON [VR].[EDISID] = [S].[EDISID]
        WHERE 
            --[VR].[DamagesObtained] = 1
        --AND [VR].[Deleted] = 0
            [S].[SiteOnline] <= [VR].[VisitDate]
        --AND (@EDISID IS NULL OR [S].[EDISID] = @EDISID)
        AND [VR].[VisitOutcomeID] IN 
            (1,2,7,9,11) /*
             1  - Buying-out - full admission (lessee), 
             2  - Buying-out - full admission (not lessee), 
             7  - Tampering found - full admission, 
             9  - Tampering found - no admission (admitted buying out), 
             11 - Buying-out & Tampering - Full admission
             */
        AND [VR].[VisitDate] >= @MaxData -- Anything earlier is irrelevant 
        AND [VR].[VisitDate] <= @EndDate -- Anything later is not yet relevant
        GROUP BY 
            [VR].[EDISID]
        ) AS [VR] ON [S].[EDISID] = [VR].[EDISID]
    LEFT JOIN (
        SELECT
            [SC].[EDISID],
            MAX(CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, [SC].[Date]), 0) AS DATE)) AS [WeekCommencing]
        FROM [dbo].[SiteComments] AS [SC]
        WHERE 
            [SC].[HeadingType] IN (3004) -- Change of Tenancy  (16 also exists, but doesn't appear to be used anymore?)
        AND [SC].[Date] >= @MaxData -- Anything earlier is irrelevant6
        AND [SC].[Date] <= @EndDate -- Anything later is not yet relevant
        GROUP BY 
            [SC].[EDISID]
        ) AS [COT] ON [S].[EDISID] = [COT].[EDISID]
    LEFT JOIN (
        SELECT 
            [S].[EDISID],
            MAX([MD].[Date]) AS [LatestStock]
        FROM [dbo].[Sites] AS [S]
        JOIN [dbo].[MasterDates] AS [MD] ON [S].[EDISID] = [MD].[EDISID]
        JOIN [dbo].[Stock] AS [St] ON [MD].[ID] = [St].[MasterDateID] 
        WHERE ([MD].[Date] >= @MinStock AND [MD].[Date] <= @EndDate)
	    AND [MD].[Date] >= [S].[SiteOnline]
        GROUP BY [S].[EDISID]
        ) AS [Excluded] ON [S].[EDISID] = [Excluded].[EDISID]
    WHERE 
        [S].[Hidden] = 0
    AND (@EDISID IS NULL OR [S].[EDISID] = @EDISID)
    AND	(@Auditor IS NULL OR LOWER([S].[SiteUser]) = LOWER(@Auditor))
    AND [S].[Status] IN (1,2,3,10) -- Active, Closed, Legals & Free-of-Tie
    AND ([Excluded].[EDISID] IS NULL -- If a Site has Stock within the last 18 weeks, WE DON'T WANT IT!
        OR
        [Excluded].[LatestStock] < 
            CASE    -- If Site Online is after the from date, set it to be the new "From"
                WHEN [S].[SiteOnline] > @MaxData THEN [S].[SiteOnline]
                -- If VRS Visit is after the from date, set it to be the new "From"
                WHEN [VR].[WeekCommencing] IS NOT NULL AND [VR].[WeekCommencing] >= @MaxData THEN [VR].[WeekCommencing]
                -- If COT is after the from date, set it to be the new "From"
                WHEN [COT].[WeekCommencing] IS NOT NULL AND [COT].[WeekCommencing] >= @MaxData THEN [COT].[WeekCommencing]
                -- No overriding conditions detected
                ELSE @MinStock
                END)
END

/* For Testing */
IF @DebugSite = 1
BEGIN
    SELECT *
    FROM #Sites
END

IF @DebugVisitRecord = 1
BEGIN
    SELECT
        [VR].[EDISID],
        --COUNT([VD].DamagesID) AS [Damages],
        --MAX([VR].[VisitDate]) AS [LatestVisit],
        MAX(CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, [VR].[VisitDate]), 0) AS DATE)) AS [Visit WeekCommencing]
    FROM [dbo].[VisitRecords] AS [VR]
    JOIN [dbo].[VisitDamages] AS [VD] ON [VR].[ID] = [VD].[VisitRecordID]
    JOIN [dbo].[Sites] AS [S] ON [VR].[EDISID] = [S].[EDISID]
    WHERE 
        --[VR].[DamagesObtained] = 1
    --AND [VR].[Deleted] = 0
        [S].[SiteOnline] <= [VR].[VisitDate]
    AND (@EDISID IS NULL OR [S].[EDISID] = @EDISID)
    AND [VR].[VisitOutcomeID] IN 
        (1,2,7,9,11) /*
         1  - Buying-out - full admission (lessee), 
         2  - Buying-out - full admission (not lessee), 
         7  - Tampering found - full admission, 
         9  - Tampering found - no admission (admitted buying out), 
         11 - Buying-out & Tampering - Full admission
         */
    AND [VR].[VisitDate] >= @MaxData -- Anything earlier is irrelevant 
    AND [VR].[VisitDate] <= @EndDate -- Anything later is not yet relevant
    GROUP BY 
        [VR].[EDISID]

    SELECT 
        [CAMID],
        [FormSaved],
        [CustomerID],
        [VR].[EDISID],
        [VisitDate],
        [VisitReasonID],
        [VisitOutcomeID]
    FROM [dbo].[VisitRecords] AS [VR]
    JOIN [dbo].[VisitDamages] AS [VD] ON [VR].[ID] = [VD].[VisitRecordID]
    JOIN [dbo].[Sites] AS [S] ON [VR].[EDISID] = [S].[EDISID]
    WHERE 
        --[VR].[DamagesObtained] = 1
    --AND [VR].[Deleted] = 0
        [S].[SiteOnline] <= [VR].[VisitDate]
    AND (@EDISID IS NULL OR [S].[EDISID] = @EDISID)
    --AND [VR].[VisitOutcomeID] IN 
    --    (1,2,7,9,11) 
    /*
         1  - Buying-out - full admission (lessee), 
         2  - Buying-out - full admission (not lessee), 
         7  - Tampering found - full admission, 
         9  - Tampering found - no admission (admitted buying out), 
         11 - Buying-out & Tampering - Full admission
         */
    --AND [VR].[VisitDate] >= @MaxData -- Anything earlier is irrelevant 
    --AND [VR].[VisitDate] <= @EndDate -- Anything later is not yet relevant
    GROUP BY
        [CAMID],
        [FormSaved],
        [CustomerID],
        [VR].[EDISID],
        [VisitDate],
        [VisitReasonID],
        [VisitOutcomeID]
    ORDER BY [VR].[VisitDate] DESC
END

--SELECT
--    [VR].[EDISID],
--    --COUNT([VD].DamagesID) AS [Damages],
--    --MAX([VR].[VisitDate]) AS [LatestVisit],
--    MAX(CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, [VR].[VisitDate]), 0) AS DATE)) AS [WeekCommencing]
--FROM [dbo].[VisitRecords] AS [VR]
--JOIN [dbo].[VisitDamages] AS [VD] ON [VR].[ID] = [VD].[VisitRecordID]
--JOIN [dbo].[Sites] AS [S] ON [VR].[EDISID] = [S].[EDISID]
--WHERE 
--    --[VR].[DamagesObtained] = 1
----AND [VR].[Deleted] = 0
--    [S].[SiteOnline] <= [VR].[VisitDate]
--AND (@EDISID IS NULL OR [S].[EDISID] = @EDISID)
--AND [VR].[VisitOutcomeID] IN 
--    (1,2,3,11,12) -- Buying Out
--GROUP BY 
--    [VR].[EDISID],
--    [VR].[DamagesObtained],
--    [VR].[Deleted]
----HAVING 
--    --COUNT([VD].DamagesID) > 0

/* For Testing */
--SELECT
--    [SC].[EDISID],
--    MAX(CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, [SC].[Date]), 0) AS DATE)) AS [WeekCommencing]
--FROM [dbo].[SiteComments] AS [SC]
--WHERE 
--    [SC].[HeadingType] IN (3004) -- Change of Tenancy  (16 also exists, but doesn't appear to be used anymore?)
--AND [SC].[EDISID] = @EDISID
--GROUP BY 
--    [SC].[EDISID]

--SELECT 
--    *,
--    CASE WHEN @MaxData >= COALESCE([S].[VisitDate], @MaxData) AND @MaxData >= COALESCE([S].[COTDate], @MaxData)
--         THEN @MaxData
--         WHEN [S].[VisitDate] >= COALESCE([S].[COTDate], [S].[VisitDate])
--         THEN [S].[VisitDate]
--         ELSE [S].[COTDate]
--         END AS [TrendDate]
--FROM #Sites AS [S]
--JOIN [dbo].[Sites] AS [Si] ON [Si].[EDISID] = [S].[EDISID] 
--WHERE [S].[SiteID] = '15029402'
--SELECT * FROM Sites WHERE [SiteID] = '15029402'
----SELECT * FROM #Sites WHERE [SuperFromDate] IS NOT NULL AND [FromDate] IS NOT NULL AND [ToDate] IS NOT NULL

/*
    Site List
    **************************************************************************************************************************************************
*/

/* **************************************************************************************************************************************************
    Calibration Requests

    Retrieve the details of any active Service Calls with Calibration Requests
*/
DECLARE @CalRequestID INT = 33 -- Calibration request (Audit raised following data query)
DECLARE @CalRequestAllID INT = 63 -- Calibration request (Audit raised following data query)

/*
-- LEGACY LOGGER
DECLARE @ProductStart CHAR = ':'
DECLARE @ProductEnd CHAR = '('

DECLARE @CalibrationRequestForAll TABLE ([EDISID] INT NOT NULL)
DECLARE @CalibrationRequestForProduct TABLE ([EDISID] INT NOT NULL, [Product] VARCHAR (50) NOT NULL)

/* All Lines */
INSERT INTO @CalibrationRequestForAll ([EDISID])
SELECT 
    --[C].[ID] AS [CallID],
    [C].[EDISID]
FROM [dbo].[Calls] AS [C]
JOIN #Sites AS [S] ON [C].[EDISID] = [S].[EDISID]
JOIN [dbo].[CallReasons] AS [CR]
    ON [C].[ID] = [CR].[CallID]
WHERE [ClosedOn] IS NULL -- Only Open/Outstanding Calls
AND [AbortReasonID] = 0 -- Not Aborted
AND [CR].[ReasonTypeID] = @CalRequestAllID

/* Specific Lines */
INSERT INTO @CalibrationRequestForProduct ([EDISID], [Product])
SELECT 
    --[C].[ID] AS [CallID],
    [C].[EDISID],
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
JOIN #Sites AS [S] ON [C].[EDISID] = [S].[EDISID]
JOIN [dbo].[CallReasons] AS [CR]
    ON [C].[ID] = [CR].[CallID]
WHERE [ClosedOn] IS NULL -- Only Open/Outstanding Calls
AND [AbortReasonID] = 0 -- Not Aborted
AND [CR].[ReasonTypeID] = @CalRequestID
AND (CHARINDEX(@ProductStart, [CR].[AdditionalInfo], 0) + 1) <> 1
AND (CHARINDEX(@ProductEnd, [CR].[AdditionalInfo], 0) - 1 - CHARINDEX(@ProductStart, [CR].[AdditionalInfo], 0)) > 1
*/

-- JOB WATCH
DECLARE @CalibrationRequestForAll TABLE ([EDISID] INT NOT NULL)
INSERT INTO @CalibrationRequestForAll (EDISID)
SELECT
    [JobWatchCalls].[EdisID]
FROM [dbo].[JobWatchCalls]
JOIN [dbo].[JobWatchCallsData] ON [JobWatchCalls].[JobId] = [JobWatchCallsData].[JobId]
WHERE [JobWatchCalls].[JobActive] = 1
AND [JobWatchCallsData].[CallReasonTypeID] = @CalRequestAllID

DECLARE @CalibrationRequestForProduct TABLE ([EDISID] INT NOT NULL, [Product] VARCHAR (50) NOT NULL)
INSERT INTO @CalibrationRequestForProduct (EDISID, Product)
SELECT
    [JobWatchCalls].[EdisID],
    [Products].[Description]
FROM [dbo].[JobWatchCalls]
JOIN [dbo].[JobWatchCallsData] ON [JobWatchCalls].[JobId] = [JobWatchCallsData].[JobId]
JOIN [dbo].[Products] ON [JobWatchCallsData].[ProductID] = [Products].[ID]
WHERE [JobWatchCalls].[JobActive] = 1
AND [JobWatchCallsData].[CallReasonTypeID] = @CalRequestID
AND [JobWatchCallsData].[ProductID] IS NOT NULL

IF @DebugCalRequest = 1
BEGIN
    SELECT [EDISID] AS [Cal. Request on Site] FROM @CalibrationRequestForAll ORDER BY [EDISID]
    SELECT [EDISID], [Product] AS [Cal. Request on Product] FROM @CalibrationRequestForProduct ORDER BY [EDISID]
END

/*
    Calibration Requests
    **************************************************************************************************************************************************
*/


/* **************************************************************************************************************************************************
    New Products Exception (custom)

    Based on the standard New Product Keg/Syrup Exception
*/

DECLARE @NewProductsEx TABLE
(
    [EDISID] INT NOT NULL,
    [Product] VARCHAR(50) NOT NULL,
    [ProductID] INT NOT NULL
    PRIMARY KEY ([EDISID], [Product], [ProductID])
)

INSERT INTO @NewProductsEx ([EDISID], [Product], [ProductID])
SELECT DISTINCT 
    [S].[EDISID],
    [P].[Description],
    [P].[ID] AS [ProductID]
FROM #Sites AS [S]
INNER JOIN [dbo].[MasterDates] AS [MD] 
    ON [S].[EDISID] = [MD].[EDISID]
INNER JOIN [dbo].[Delivery] AS [DEL] 
    ON [MD].[ID] = [DEL].[DeliveryID]
INNER JOIN [dbo].[Products] AS [P] 
    ON [DEL].[Product] = [P].[ID]
LEFT JOIN [dbo].[PumpSetup] AS [PS] 
    ON [S].[EDISID] = [PS].[EDISID] AND [PS].[ValidTo] IS NULL AND [P].[ID] = [PS].[ProductID]
LEFT JOIN [dbo].[SiteProductTies] AS [SPT] 
    ON [P].[ID] = [SPT].[ProductID] AND [MD].[EDISID] = [SPT].[EDISID]
LEFT JOIN [dbo].[SiteProductCategoryTies] AS [SPCT] 
    ON [P].[CategoryID] = [SPCT].[ProductCategoryID] AND [MD].[EDISID] = [SPCT].[EDISID]
WHERE 
    ([MD].[Date] BETWEEN @MinNewProd AND @EndDate)
AND [P].[IsCask] = 0 -- Guest Cask products would constantly be included if enabled
--AND [P].[IsGuestAle] = 0 -- Exclude products marked specifically as Guest
AND	[P].[IsWater] = 0
AND	[PS].[Pump] IS NULL -- Not On Font Setup
AND	COALESCE([SPT].[Tied], [SPCT].[Tied], [P].[Tied]) = 1

IF @DebugNewProduct = 1
BEGIN
    SELECT
        [Sites].[EDISID],
        [Sites].[SiteID],
        [Ex].[ProductID],
        [Ex].[Product] AS [New Product]
    FROM @NewProductsEx AS [Ex]
    JOIN [dbo].[Sites] ON [Ex].[EDISID] = [Sites].[EDISID]
    ORDER BY [SiteID], [Product]
END

/*
    New Products Exception (custom)
    **************************************************************************************************************************************************
*/


/* **************************************************************************************************************************************************
    Date Table
*/
DECLARE @Dates TABLE
(
    [EDISID] INT NOT NULL,
    [Date] DATETIME NOT NULL,
    [ProductID] INT NOT NULL
    UNIQUE CLUSTERED ([EDISID], [Date], [ProductID])
)

DECLARE @TempDate DATE
SELECT @TempDate = MIN([SuperFromDate]) FROM #Sites

DECLARE @Products TABLE
(
    [EDISID] INT NOT NULL,
    [ProductID] INT NOT NULL
)

INSERT INTO @Products ([EDISID], [ProductID])
SELECT DISTINCT [Sites].[EDISID], [PeriodCacheVarianceInternal].[ProductID]
FROM [dbo].[PeriodCacheVarianceInternal]
JOIN #Sites AS [Sites] ON [PeriodCacheVarianceInternal].[EDISID] = [Sites].[EDISID]
UNION
SELECT DISTINCT Sites.EDISID, ProductID
FROM dbo.PumpSetup AS PumpSetup
JOIN #Sites AS Sites ON PumpSetup.EDISID = Sites.EDISID

WHILE @TempDate <= @EndDate
BEGIN
    INSERT INTO @Dates ([EDISID], [Date], [ProductID])
    SELECT [EDISID], @TempDate, [ProductID]
    FROM @Products

    SET @TempDate = DATEADD(WEEK, 1, @TempDate)
END

--SELECT * FROM @Dates ORDER BY [EDISID], [Date], [ProductID]

--SELECT 
--    [EDISID],
--    [ProductID],
--    MIN([Date]) AS [MinDate],
--    MAX([Date]) AS [MaxDate]
--FROM @Dates 
--GROUP BY 
--    [EDISID],
--    [ProductID]
--ORDER BY 
--    [EDISID],
--    [ProductID]

/*
    Date Table
    **************************************************************************************************************************************************
*/



/* **************************************************************************************************************************************************
    Per-Product (excluding Casks)
*/
INSERT INTO #Variance
(
    [EDISID],
    [WeekCommencing],
    [Product],
    [ProductCategory],
    [Dispensed],
    [Delivered],
    [Variance],
    [IsCask], 
    [IsKeg], 
    [IsMetric]
)
SELECT 
    [S].[EDISID],
    [PCVI].[WeekCommencing],
    [P].[Description] AS [Product],
    [PC].[Description] AS [Category],
    [PCVI].[Dispensed] * CASE WHEN [P].[IsMetric] = 1 THEN @ToLitres ELSE @ToGallons END,
    [PCVI].[Delivered] * CASE WHEN [P].[IsMetric] = 1 THEN @ToLitres ELSE @ToGallons END,
    [PCVI].[Variance] * CASE WHEN [P].[IsMetric] = 1 THEN @ToLitres ELSE @ToGallons END,
    [P].[IsCask],
    CAST(CASE WHEN [P].[IsCask] = 0 AND [P].[IsMetric] = 0 AND [P].[IsWater] = 0 THEN 1 ELSE 0 END AS BIT) AS [Iskeg],
    [P].[IsMetric]
FROM [dbo].[PeriodCacheVarianceInternal] AS [PCVI]
JOIN #Sites AS [S] ON [PCVI].[EDISID] = [S].[EDISID]
JOIN [dbo].[Sites] AS [Si] ON [S].[EDISID] = [Si].[EDISID]
JOIN [dbo].[Products] AS [P] ON [P].[ID] = [PCVI].[ProductID]
JOIN [dbo].[ProductCategories] AS [PC] ON [P].[CategoryID] = [PC].[ID]
LEFT JOIN [dbo].[SiteProductCategoryTies] AS [SPC] 
    ON [P].[CategoryID] = [SPC].[ProductCategoryID]
    AND [SPC].[EDISID] = [S].[EDISID]
LEFT JOIN [dbo].[SiteProductTies] AS [SP]
    ON [P].[ID] = [SP].[ProductID]
    AND [SP].[EDISID] = [S].[EDISID]
WHERE [PCVI].[WeekCommencing] BETWEEN [S].[SuperFromDate] AND [S].[ToDate]
AND [P].[IsCask] = 0
AND COALESCE([SP].[Tied], [SPC].[Tied], [P].[Tied]) = 1
AND [Si].[Status] NOT IN (2,10) -- Exclude Closed & Free-of-Tie
--ORDER BY 
--    [P].[Description],
--    [PCVI].[WeekCommencing]

/* Per-Product
    **************************************************************************************************************************************************
*/



/* **************************************************************************************************************************************************
    Consolidated Cask
*/
INSERT INTO #Variance
(
    [EDISID],
    [WeekCommencing],
    [Product],
    [ProductCategory],
    [Dispensed],
    [Delivered],
    [Variance],
    [IsCask], 
    [IsKeg], 
    [IsMetric]
)
SELECT 
    [S].[EDISID],
    [PCVI].[WeekCommencing],
    'Consolidated Casks' AS [Product],
    '' AS [Category],
    SUM([PCVI].[Dispensed]) * @ToGallons,
    SUM([PCVI].[Delivered]) * @ToGallons,
    SUM([PCVI].[Variance]) * @ToGallons,
    1 AS [IsCask],
    0 AS [Iskeg],
    0 AS [IsMetric]
FROM [dbo].[PeriodCacheVarianceInternal] AS [PCVI]
JOIN #Sites AS [S] ON [PCVI].[EDISID] = [S].[EDISID]
JOIN [dbo].[Products] AS [P] ON [P].[ID] = [PCVI].[ProductID]
LEFT JOIN [dbo].[SiteProductCategoryTies] AS [SPC] 
    ON [P].[CategoryID] = [SPC].[ProductCategoryID]
    AND [SPC].[EDISID] = [S].[EDISID]
LEFT JOIN [dbo].[SiteProductTies] AS [SP]
    ON [P].[ID] = [SP].[ProductID]
    AND [SP].[EDISID] = [S].[EDISID]
WHERE [PCVI].[WeekCommencing] BETWEEN [S].[SuperFromDate] AND [S].[ToDate]
AND [P].[IsCask] = 1
AND COALESCE([SP].[Tied], [SPC].[Tied], [P].[Tied]) = 1
GROUP BY
    [S].[EDISID],
    [PCVI].[WeekCommencing]
--ORDER BY 
--    [PCVI].[WeekCommencing]

/* Consolidated Cask
    **************************************************************************************************************************************************
*/

--SELECT * 
--FROM #Variance
--WHERE [EDISID] = 3553
--ORDER BY [EDISID], [WeekCommencing], [Product]

/* **************************************************************************************************************************************************
    Fill Gaps

    Fill any gaps where Products are missing weeks (Trend Period only)
*/

DECLARE @StartDate DATE
SELECT @StartDate = MIN([SuperFromDate]) FROM #Sites

--SELECT @EndDate

--SELECT DISTINCT 
--    [Calendar].[FirstDateOfWeek]
--FROM [Calendar]
--WHERE [FirstDateOfWeek] BETWEEN @StartDate AND @EndDate

INSERT INTO #Variance
    ([EDISID], [WeekCommencing], [Product], [ProductCategory], [IsCask], [IsKeg], [IsMetric], [Dispensed], [Delivered], [Variance], [IsAdjusted])
SELECT
    [Complete].[EDISID],
    [Complete].[WeekCommencing],
    [Complete].[Product],
    [Complete].[ProductCategory],
    [Complete].[IsCask],
    [Complete].[IsKeg],
    [Complete].[IsMetric],
    0 AS [Dispensed],
    0 AS [Delivered],
    0 AS [Variance],
    [Complete].[IsAdjusted]
FROM (
    SELECT
        [Variance].[EDISID],
        [Calendar].[FirstDateOfWeek] AS [WeekCommencing],
        [Variance].[Product],
        [Variance].[ProductCategory],
        [Variance].[IsCask],
        [Variance].[IsKeg],
        [Variance].[IsMetric],
        [Variance].[IsAdjusted]
    FROM (
        SELECT DISTINCT 
            [Calendar].[FirstDateOfWeek]
        FROM [Calendar]
        WHERE [FirstDateOfWeek] BETWEEN @StartDate AND @EndDate
        ) AS [Calendar]
    CROSS APPLY (
        SELECT DISTINCT 
            [EDISID],
            [Product],
            [ProductCategory],
            [IsCask],
            [IsKeg],
            [IsMetric],
            [IsAdjusted]
        FROM #Variance
        ) AS [Variance]
    ) AS [Complete]
LEFT JOIN #Variance AS [Variance]
    ON [Complete].[WeekCommencing] = [Variance].[WeekCommencing]
    AND [Complete].[Product] = [Variance].[Product]
    AND [Complete].[EDISID] = [Variance].[EDISID]
WHERE [Variance].[WeekCommencing] IS NULL
--AND [Complete].[EDISID] = 174

/* Fill Gaps
    **************************************************************************************************************************************************
*/

--SELECT * 
--FROM #Variance
--WHERE [EDISID] = 3451
----AND [Product] = 'John Smiths Extra Smooth'
--ORDER BY [EDISID], [Product], [WeekCommencing]

/* **************************************************************************************************************************************************
    Cumulative Variance & Trend
*/

DECLARE @CurrentEDISID INT
DECLARE @CurrentSiteStatus INT
DECLARE @CurrentWC DATE
DECLARE @CurrentProduct VARCHAR(50)
DECLARE @CurrentVariance FLOAT
DECLARE @CurrentFrom DATE
DECLARE @CurrentSuperFrom DATE
DECLARE @CurrentVisitFrom DATE
DECLARE @CurrentStandardCV FLOAT
DECLARE @CurrentExtendedCV FLOAT
DECLARE @CurrentStandardTrend FLOAT
DECLARE @CurrentExtendedTrend FLOAT
DECLARE @CurrentVisitDate DATE
DECLARE @CurrentCOTDate DATE

DECLARE @PreviousEDISID INT
DECLARE @PreviousWC DATE
DECLARE @PreviousProduct VARCHAR(50)
DECLARE @PreviousStandardCV FLOAT
DECLARE @PreviousExtendedCV FLOAT
DECLARE @PreviousStandardTrend FLOAT
DECLARE @PreviousExtendedTrend FLOAT

DECLARE Cursor_Variance CURSOR LOCAL FAST_FORWARD FOR
SELECT 
    [V].[EDISID],
    [V].[WeekCommencing],
    [V].[Product],
    [V].[Variance],
    [S].[FromDate],
    [S].[SuperFromDate],
    [S].[VisitDate],
    [S].[COTDate]
FROM #Variance AS [V] 
JOIN #Sites AS [S] ON [V].[EDISID] = [S].[EDISID]
ORDER BY EDISID, Product, WeekCommencing

OPEN Cursor_Variance

FETCH NEXT FROM Cursor_Variance INTO @CurrentEDISID, @CurrentWC, @CurrentProduct, @CurrentVariance, @CurrentFrom, @CurrentSuperFrom, @CurrentVisitDate, @CurrentCOTDate

WHILE @@FETCH_STATUS = 0
BEGIN
    IF ((@PreviousEDISID IS NULL OR @PreviousEDISID <> @CurrentEDISID) OR (@PreviousProduct IS NULL OR @PreviousProduct <> @CurrentProduct))
    BEGIN
        SELECT  @PreviousEDISID = NULL, 
                @PreviousWC = NULL, 
                @PreviousProduct = NULL, 
                @PreviousStandardCV = 0,
                @PreviousExtendedCV = 0,
                @PreviousStandardTrend = 0,
                @PreviousExtendedTrend = 0,
                @CurrentStandardCV = 0,
                @CurrentExtendedCV = 0,
                @CurrentStandardTrend = 0,
                @CurrentExtendedTrend = 0
    END
        
    IF @CurrentWC >= @CurrentFrom
    BEGIN
        SELECT
            @CurrentStandardCV = @PreviousStandardCV + @CurrentVariance
        
        -- We are within the Standard period
        UPDATE #Variance 
        SET [StandardCumulativeVariance] = @CurrentStandardCV
        WHERE
            [EDISID] = @CurrentEDISID
        AND [WeekCommencing] = @CurrentWC
        AND [Product] = @CurrentProduct

        -- Trend only calculates from the latest potential "From" date
        IF @CurrentWC >= ISNULL(@CurrentVisitDate, @CurrentWC) AND @CurrentWC >= ISNULL(@CurrentCOTDate, @CurrentWC)
        BEGIN
            SELECT
                @CurrentStandardTrend = CASE WHEN @CurrentVariance < 0                              -- Current Variance value is negative
                                             THEN @PreviousStandardTrend + @CurrentVariance         -- Continue the Trend
                                        ELSE CASE WHEN @PreviousStandardTrend >= 0                  -- Positive Trend, detect if it has already been reset
								                  THEN @PreviousStandardTrend + @CurrentVariance    -- Previous Trend value was positive, Continue the Trend
                                                  WHEN @PreviousStandardTrend > @TrendThreshold    -- Detect if the Trend had reached the threshold
                                                  THEN @PreviousStandardTrend + @CurrentVariance    -- Previous Trend was negative but above Threshold, Continue the Trend
                                             ELSE @CurrentVariance                                  -- Previous Trend had passed threshold, Start a new Trend
                                             END
                                        END 
            
            -- We are within the Standard period
            UPDATE #Variance 
            SET [StandardTrend] = @CurrentStandardTrend,
                --[StandardTrending] = CASE WHEN @CurrentStandardTrend < 0 THEN 1 ELSE 0 END
                [StandardTrending] = CASE WHEN @CurrentStandardTrend <= @TrendThreshold THEN 1 ELSE 0 END
            WHERE
                [EDISID] = @CurrentEDISID
            AND [WeekCommencing] = @CurrentWC
            AND [Product] = @CurrentProduct
        END
    END
    
    IF @CurrentWC >= @CurrentSuperFrom
    BEGIN
        SELECT
            @CurrentExtendedCV = @PreviousExtendedCV + @CurrentVariance

        UPDATE #Variance 
        SET [ExtendedCumulativeVariance] = @CurrentExtendedCV
        WHERE
            [EDISID] = @CurrentEDISID
        AND [WeekCommencing] = @CurrentWC
        AND [Product] = @CurrentProduct

        -- Trend only calculates from the latest potential "From" date
        IF @CurrentWC >= ISNULL(@CurrentVisitDate, @CurrentWC) AND @CurrentWC >= ISNULL(@CurrentCOTDate, @CurrentWC)
        BEGIN
            SELECT
                @CurrentExtendedTrend = CASE WHEN @CurrentVariance < 0                              -- Current Variance value is negative
                                                THEN @PreviousExtendedTrend + @CurrentVariance         -- Continue the Trend
                                        ELSE CASE WHEN @PreviousExtendedTrend >= 0                  -- Positive Trend, detect if it has already been reset
							                        THEN @PreviousExtendedTrend + @CurrentVariance    -- Previous Trend value was positive, Continue the Trend
                                                    WHEN @PreviousExtendedTrend > @TrendThreshold    -- Detect if the Trend had reached the threshold
                                                    THEN @PreviousExtendedTrend + @CurrentVariance    -- Previous Trend was negative but above Threshold, Continue the Trend
                                                ELSE @CurrentVariance                                  -- Previous Trend had passed threshold, Start a new Trend
                                                END
                                        END 

            UPDATE #Variance 
            SET [ExtendedTrend] = @CurrentExtendedTrend,
                --[ExtendedTrending] = CASE WHEN @CurrentExtendedTrend < 0 THEN 1 ELSE 0 END
                [ExtendedTrending] = CASE WHEN @CurrentExtendedTrend <= @TrendThreshold THEN 1 ELSE 0 END
            WHERE
                [EDISID] = @CurrentEDISID
            AND [WeekCommencing] = @CurrentWC
            AND [Product] = @CurrentProduct
        END
    END

    /* For Testing */
    --IF @CurrentProduct = 'Bulmers Strongbow'
    --BEGIN
    --    SELECT  @CurrentEDISID AS EDISID, 
    --            @CurrentWC AS WC, 
    --            @CurrentProduct AS Product, 
    --            @CurrentVariance AS CV,
    --            @CurrentStandardCV AS StdCV,
    --            @PreviousStandardCV AS PrevStdCV,
    --            @CurrentExtendedCV AS ExtCV,
    --            @PreviousExtendedCV AS PrevExtCV,
    --            @CurrentStandardTrend AS StdTrend,
    --            @CurrentExtendedTrend AS ExtTrend
    --END

    SELECT  @PreviousEDISID = @CurrentEDISID, 
            @PreviousWC = @CurrentWC, 
            @PreviousProduct = @CurrentProduct, 
            @PreviousStandardCV = @CurrentStandardCV,
            @PreviousExtendedCV = @CurrentExtendedCV,
            @PreviousStandardTrend = @CurrentStandardTrend,
            @PreviousExtendedTrend = @CurrentExtendedTrend

    FETCH NEXT FROM Cursor_Variance INTO @CurrentEDISID, @CurrentWC, @CurrentProduct, @CurrentVariance, @CurrentFrom, @CurrentSuperFrom, @CurrentVisitDate, @CurrentCOTDate
END

CLOSE Cursor_Variance
DEALLOCATE Cursor_Variance

--SELECT * 
--FROM #Variance
--WHERE [EDISID] = 3451
----AND [Product] = 'John Smiths Extra Smooth'
--ORDER BY [EDISID], [Product], [WeekCommencing]

-- Set the Trend Totals
UPDATE [V1]
SET [V1].[StandardTrendTotal] = 
        CASE WHEN [V1].[WeekCommencing] >=
            (CASE WHEN @MaxData >= COALESCE([S].[VisitDate], @MaxData) AND @MaxData >= COALESCE([S].[COTDate], @MaxData)
                  THEN @MaxData
                  WHEN [S].[VisitDate] >= COALESCE([S].[COTDate], [S].[VisitDate])
                  THEN [S].[VisitDate]
                  ELSE [S].[COTDate]
                  END) -- "Trend From" Date (adjusting for VRS Visit / Change of Tenancy)
             THEN CASE WHEN [V1].[StandardTrending] = 1 AND [V2].[StandardTrending] = 0
                       THEN [V1].[StandardTrend]
                       ELSE NULL END
             ELSE NULL END,
    [V1].[ExtendedTrendTotal] = 
        CASE WHEN [V1].[WeekCommencing] >= 
            (CASE WHEN @MaxData >= COALESCE([S].[VisitDate], @MaxData) AND @MaxData >= COALESCE([S].[COTDate], @MaxData)
                  THEN @MaxData -- We still only care about trends occurring within the 18 week period (or less depending on VRS/COT), but still based on a 21 week starting point
                  WHEN [S].[VisitDate] >= COALESCE([S].[COTDate], [S].[VisitDate])
                  THEN [S].[VisitDate]
                  ELSE [S].[COTDate]
                  END) -- "Trend From" Date (adjusting for VRS Visit / Change of Tenancy)
             THEN CASE WHEN [V1].[ExtendedTrending] = 1 AND [V2].[ExtendedTrending] = 0
                       THEN [V1].[ExtendedTrend]
                       ELSE NULL END
             ELSE NULL END
FROM #Variance AS [V1]
JOIN #Variance AS [V2]
    ON [V1].[WeekCommencing] = DATEADD(DAY, -7, [V2].[WeekCommencing]) -- match to the previous week
    AND [V1].[Product] = [V2].[Product]
    AND [V1].[EDISID] = [V2].[EDISID]
JOIN #Sites AS [S] 
    ON [V1].[EDISID] = [S].[EDISID]


--SELECT * 
--FROM #Variance
--WHERE [EDISID] = 3451
----AND [Product] = 'John Smiths Extra Smooth'
--ORDER BY [EDISID], [Product], [WeekCommencing]


/*  Close hanging Trends
    Where the Trend hasn't "completed" as it's still ongoing, we manually complete the final week for the selected period.
    This could be done at the initial point of calculation but for simplicity (avoiding nested CASE statements) I'm doing it here instead
*/


UPDATE [Variance]
SET [StandardTrendTotal] = [StandardTrend]
FROM #Variance AS [Variance]
JOIN (  SELECT
            [PotentialHanging].[HangingTrendWeek],
            [PotentialHanging].[Product],
            [PotentialHanging].[EDISID]
        FROM (  SELECT
                    MAX([WeekCommencing]) AS [HangingTrendWeek],
                    [Product],
                    [EDISID]
                FROM #Variance AS [Variance]
                WHERE
                    [StandardTrending] = 1
                AND [StandardTrendTotal] IS NULL
                AND [WeekCommencing] = DATEADD(WEEK, DATEDIFF(WEEK, 6, @EndDate), 0)
                GROUP BY 
                    [Product],
                    [EDISID]
            ) AS [PotentialHanging]
        LEFT JOIN ( SELECT
                        MAX([WeekCommencing]) AS [CompletedTrendWeek],
                        [Product],
                        [EDISID]
                    FROM #Variance
                    WHERE
                        [StandardTrending] = 1
                    AND [StandardTrendTotal] IS NOT NULL
                    GROUP BY 
                        [Product],
                        [EDISID]
            ) AS [CompletedTrends]
            ON [PotentialHanging].[Product] = [CompletedTrends].[Product]
            AND DATEADD(WEEK, 1, [PotentialHanging].[HangingTrendWeek]) = [CompletedTrends].[CompletedTrendWeek]
            AND [PotentialHanging].[EDISID] = [CompletedTrends].[EDISID]
        WHERE 
            [CompletedTrends].[CompletedTrendWeek] IS NULL
    ) AS [TrendsToClose]
    ON [Variance].[Product] = [TrendsToClose].[Product]
    AND [Variance].[WeekCommencing] = [TrendsToClose].[HangingTrendWeek]
    AND [Variance].[EDISID] = [TrendsToClose].[EDISID]

UPDATE [Variance]
SET [ExtendedTrendTotal] = [ExtendedTrend]
FROM #Variance AS [Variance]
JOIN (  SELECT
            [PotentialHanging].[HangingTrendWeek],
            [PotentialHanging].[Product],
            [PotentialHanging].[EDISID]
        FROM (  SELECT
                    MAX([WeekCommencing]) AS [HangingTrendWeek],
                    [Product],
                    [EDISID]
                FROM #Variance AS [Variance]
                WHERE
                    [ExtendedTrending] = 1
                AND [ExtendedTrendTotal] IS NULL
                AND [WeekCommencing] = DATEADD(WEEK, DATEDIFF(WEEK, 6, @EndDate), 0)
                GROUP BY 
                    [Product],
                    [EDISID]
            ) AS [PotentialHanging]
        LEFT JOIN (  SELECT
                    MAX([WeekCommencing]) AS [CompletedTrendWeek],
                    [Product],
                    [EDISID]
                FROM #Variance
                WHERE
                    [ExtendedTrending] = 1
                AND [ExtendedTrendTotal] IS NOT NULL
                GROUP BY 
                    [Product],
                    [EDISID]
            ) AS [CompletedTrends]
            ON [PotentialHanging].[Product] = [CompletedTrends].[Product]
            AND DATEADD(WEEK, 1, [PotentialHanging].[HangingTrendWeek]) = [CompletedTrends].[CompletedTrendWeek]
            AND [PotentialHanging].[EDISID] = [CompletedTrends].[EDISID]
        WHERE 
            [CompletedTrends].[CompletedTrendWeek] IS NULL
    ) AS [TrendsToClose]
    ON [Variance].[Product] = [TrendsToClose].[Product]
    AND [Variance].[WeekCommencing] = [TrendsToClose].[HangingTrendWeek]
    AND [Variance].[EDISID] = [TrendsToClose].[EDISID]

DECLARE @Dispense TABLE ([EDISID] INT NOT NULL, [Product] VARCHAR(50) NOT NULL, [StandardAverageDispense] FLOAT NOT NULL, [StandardTotalDispense] FLOAt NOt NULL)

INSERT INTO @Dispense ([EDISID], [Product], [StandardAverageDispense], [StandardTotalDispense])
SELECT 
    [V].[EDISID], 
    [V].[Product], 
    AVG(CASE WHEN [V].[WeekCommencing] >=
                (CASE WHEN @MaxData >= COALESCE([S].[VisitDate], @MaxData) AND @MaxData >= COALESCE([S].[COTDate], @MaxData)
                      THEN @MaxData
                      WHEN [S].[VisitDate] >= COALESCE([S].[COTDate], [S].[VisitDate])
                      THEN [S].[VisitDate]
                      ELSE [S].[COTDate]
                      END) -- "Trend From" Date (adjusting for VRS Visit / Change of Tenancy)
             THEN [V].[Dispensed]
             ELSE NULL
             END),
    SUM(CASE WHEN [V].[WeekCommencing] >=
                (CASE WHEN @MaxData >= COALESCE([S].[VisitDate], @MaxData) AND @MaxData >= COALESCE([S].[COTDate], @MaxData)
                      THEN @MaxData
                      WHEN [S].[VisitDate] >= COALESCE([S].[COTDate], [S].[VisitDate])
                      THEN [S].[VisitDate]
                      ELSE [S].[COTDate]
                      END) -- "Trend From" Date (adjusting for VRS Visit / Change of Tenancy)
             THEN [V].[Dispensed]
             ELSE 0 
             END)
FROM #Variance AS [V]
JOIN #Sites AS [S] 
    ON [V].[EDISID] = [S].[EDISID]
GROUP BY [V].[EDISID], [V].[Product]

IF @DebugAverage = 1
BEGIN
    SELECT * FROM @Dispense
END


/* Application of Rules */
CREATE TABLE #Exceptions ([EDISID] INT NOT NULL, [Product] VARCHAR(50) NOT NULL, [Status] INT NOT NULL)
INSERT INTO #Exceptions ([EDISID], [Product], [Status])
SELECT 
    [Trends].[EDISID],
    [Trends].[Product],
    CASE 
        WHEN ([IsKeg] = 1 OR [IsCask] = 1 OR [IsSyrup] = 1)
        THEN CASE WHEN -- Apply Amber Rule 1 (Standard %) 
                       [StandardTrendTotal] <= (CASE WHEN [IsKeg] = 1 THEN @Amber_KegGallons WHEN [IsCask] = 1 THEN @Amber_CaskGallons WHEN [IsSyrup] = 1 THEN @Amber_SyrupLitres END) 
                       AND [StandardTrendPercent] >= @Amber_Percent
                  THEN -- AMBER Triggered by Amber Rule 1 (Rule Flow: Yes)
                       CASE WHEN -- Apply Service-Call/New-Product Rule (Product Cal. Request, New Product Exception)
                            ([NewProduct].[EDISID] IS NOT NULL) -- New Product Exception (latest 3 weeks)
                            AND ([SiteConditions].[EDISID] IS NOT NULL -- Calibration Request All
                                 OR 
                                ([ProductConditions].[Product] IS NOT NULL AND [ProductConditions].[CalRequest] = 1)) -- Calibration Request for Product
                       THEN -- GREEN Triggered by Service-Call/New-Product Rule
                            0 -- GREEN - Based on Service-Call/New-Product Rule (Yes), Amber Rule 1 (Yes)
                       ELSE -- CONTINUE Triggered by Service-Call/New-Product Rule
                            CASE WHEN -- Apply Red Rule 1 (Standard %)
                                 [StandardTrendTotal] <= (CASE WHEN [IsKeg] = 1 THEN @Red_KegGallons WHEN [IsCask] = 1 THEN @Red_CaskGallons WHEN [IsSyrup] = 1 THEN @Red_SyrupLitres END) 
                                 AND [StandardTrendPercent] >= @Red_Percent
                            THEN -- RED Triggered by Red Rule 1 (Rule Flow: Yes)
                                 CASE WHEN -- Apply Red Rule 2 (Extended %)
                                      [ExtendedTrendTotal] <= (CASE WHEN [IsKeg] = 1 THEN @Red_KegGallons WHEN [IsCask] = 1 THEN @Red_CaskGallons WHEN [IsSyrup] = 1 THEN @Red_SyrupLitres END) 
                                      AND [ExtendedTrendPercent] >= @Red_Percent
                                 THEN -- RED Triggered by Red Rule 2 (Rule Flow: Yes)
                                     CASE WHEN -- Apply Red Rule 4 (Standard Avg)
                                         [StandardAverageDispense] < @Red_AverageDispense
                                     THEN -- AMBER Favoured by Red Rule 4 (Rule Flow: Yes)
                                         CASE WHEN -- Apply Red Rule 5 (Extended %, Standard Total)
                                             ([ExtendedTrendPercent] > @Red_PercentHigh) OR ([ExtendedTrendTotal] > [StandardTotalDispense])
                                         THEN -- RED Triggered by Red Rule 5 (Rule Flow: Yes)
                                             1 -- RED - Based on Red Rule 5 (Yes), Red Rule 4 (Yes), Red Rule 2 (Yes), Red Rule 1 (Yes), Service-Call/New-Product Rule (No) and Amber Rule 1 (Yes)
                                         ELSE -- AMBER Triggered by Red Rule 5 (Rule Flow: No)
                                             2 -- AMBER - Based on Red Rule 5 (No), Red Rule 4 (Yes), Red Rule 2 (Yes), Red Rule 1 (Yes), Service-Call/New-Product Rule (No) and Amber Rule 1 (Yes)
                                         END
                                     ELSE -- RED Remains by Red Rule 4 (Rule Flow: No)
                                         1 -- RED - Based on Red Rule 4 (No), Red Rule 2 (Yes), Red Rule 1 (Yes) Service-Call/New-Product Rule (No) and Amber Rule 1 (Yes)
                                     END
                                 ELSE -- AMBER Triggered by Red Rule 2 (Rule Flow: No)
                                     CASE WHEN -- Apply Amber Rule 2 (Extended %)
                                          [ExtendedTrendTotal] <= (CASE WHEN [IsKeg] = 1 THEN @Amber_KegGallons WHEN [IsCask] = 1 THEN @Amber_CaskGallons WHEN [IsSyrup] = 1 THEN @Amber_SyrupLitres END) 
                                          AND [ExtendedTrendPercent] >= @Amber_Percent
                                     THEN -- AMBER Triggered by Amber Rule 2 (Rule Flow: Yes)
                                          CASE WHEN -- Apply Amber Rule 5 (Standard Avg)
                                               [StandardAverageDispense] < @Amber_AverageDispense
                                          THEN -- GREEN Favoured by Amber Rule 5 (Rule Flow: Yes)
                                               CASE WHEN -- Apple Amber Rule 6 (Extended %, Standard Total)
                                                    ([ExtendedTrendPercent] > @Amber_PercentHigh) OR ([ExtendedTrendTotal] > [StandardTotalDispense])
                                               THEN -- AMBER Triggered by Amber Rule 6 (Rule Flow: Yes)
                                                    2 -- AMBER - Based on Amber Rule 6 (Yes), Amber Rule 5 (Yes), Amber Rule 2 (Yes), Red Rule 2 (No) Red Rule 1 (Yes), Service-Call/New-Product Rule (No) and Amber Rule 1 (Yes)
                                               ELSE -- GREEN Triggered by Amber Rule 6 (Rule Flow: No)
                                                    0 -- GREEN - Based on Amber Rule 6 (No), Amber Rule 5 (Yes), Amber Rule 2 (Yes), Red Rule 2 (No), Red Rule 1 (Yes), Service-Call/New-Product Rule (No) and Amber Rule 1 (Yes)
                                               END
                                          ELSE -- AMBER Remains by Amber Rule 2 (Rule Flow: No)
                                               2 -- AMBER - Based on Amber Rule 5 (No), Amber Rule 2 (Yes), Red Rule 2 (No), Red Rule 1 (Yes), Service-Call/New-Product Rule (No) and Amber Rule 1 (Yes)
                                          END
                                     ELSE -- GREEN Triggered by Amber Rule 2 (Rule Flow: No)
                                         CASE WHEN -- Apply Amber Rule 4 (Extended #)
                                              [ExtendedTrendTotal] <= @Amber_TotalGallons
                                         THEN -- AMBER Triggered by Amber Rule 4 (Rule Flow: Yes)
                                             CASE WHEN -- Apply Red Rule 3 (Extended #)
                                                  [ExtendedTrendTotal] <= @Red_TotalGallons
                                             THEN -- RED Triggered by Red Rule 3 (Rule Flow: Yes)
                                                  1 -- RED - Based on Red Rule 3 (Yes), Amber Rule 4 (Yes), Amber Rule 2 (No), Red Rule 1 (No), Service-Call/New-Product Rule (No) and Amber Rule 1 (Yes)
                                             ELSE -- AMBER Remains by Amber Rule 4 (Rule Flow: No)
                                                  2 -- AMBER - Based on Red Rule 3 (No), Amber Rule 4 (Yes), Amber Rule 2 (No), Red Rule 1 (No), Service-Call/New-Product Rule (No) and Amber Rule 1 (Yes)
                                             END
                                         ELSE -- GREEN Triggered by Amber Rule 4 (Rule Flow: No)
                                              0 -- GREEN - Based on Amber Rule 4 (No), Amber Rule 2 (No), Red Rule 1 (No), Service-Call/New-Product Rule (No) and Amber Rule 1 (Yes)
                                         END
                                     END
                                 END
                            ELSE -- AMBER Remains by Amber Rule 1 (Rule Flow: No)
                                 CASE WHEN -- Apply Amber Rule 2 (Extended %)
                                      [ExtendedTrendTotal] <= (CASE WHEN [IsKeg] = 1 THEN @Amber_KegGallons WHEN [IsCask] = 1 THEN @Amber_CaskGallons WHEN [IsSyrup] = 1 THEN @Amber_SyrupLitres END) 
                                      AND [ExtendedTrendPercent] >= @Amber_Percent
                                 THEN -- AMBER Triggered by Amber Rule 2 (Rule Flow: Yes)
                                     CASE WHEN -- Apply Amber Rule 5 (Standard Avg)
                                          [StandardAverageDispense] < @Amber_AverageDispense
                                     THEN -- GREEN Favoured by Amber Rule 5 (Rule Flow: Yes)
                                          CASE WHEN -- Apple Amber Rule 6 (Extended %, Standard Total)
                                               ([ExtendedTrendPercent] > @Amber_PercentHigh) OR ([ExtendedTrendTotal] > [StandardTotalDispense])
                                          THEN -- AMBER Triggered by Amber Rule 6 (Rule Flow: Yes)
                                               2 -- AMBER - Based on Amber Rule 6 (Yes), Amber Rule 5 (Yes), Amber Rule 2 (Yes), Red Rule 1 (No), Service-Call/New-Product Rule (No) and Amber Rule 1 (Yes)
                                          ELSE -- GREEN Triggered by Amber Rule 6 (Rule Flow: No)
                                               0 -- GREEN - Based on Amber Rule 6 (No), Amber Rule 5 (Yes), Amber Rule 2 (Yes), Red Rule 1 (No), Service-Call/New-Product Rule (No) and Amber Rule 1 (Yes)
                                          END
                                     ELSE -- AMBER Remains by Amber Rule 2 (Rule Flow: No)
                                          2 -- AMBER - Based on Amber Rule 5 (No), Amber Rule 2 (Yes), Red Rule 1 (No), Service-Call/New-Product Rule (No) and Amber Rule 1 (Yes)
                                     END
                                 ELSE -- GREEN Triggered by Amber Rule 2 (Rule Flow: No)
                                     CASE WHEN -- Apply Amber Rule 4 (Extended #)
                                          [ExtendedTrendTotal] <= @Amber_TotalGallons
                                     THEN -- AMBER Triggered by Amber Rule 4 (Rule Flow: Yes)
                                         CASE WHEN -- Apply Red Rule 3 (Extended #)
                                              [ExtendedTrendTotal] <= @Red_TotalGallons
                                         THEN -- RED Triggered by Red Rule 3 (Rule Flow: Yes)
                                              1 -- RED - Based on Red Rule 3 (Yes), Amber Rule 4 (Yes), Amber Rule 2 (No), Red Rule 1 (No), Service-Call/New-Product Rule (No) and Amber Rule 1 (Yes)
                                         ELSE -- AMBER Remains by Amber Rule 4 (Rule Flow: No)
                                              2 -- AMBER - Based on Red Rule 3 (No), Amber Rule 4 (Yes), Amber Rule 2 (No), Red Rule 1 (No), Service-Call/New-Product Rule (No) and Amber Rule 1 (Yes)
                                         END
                                     ELSE -- GREEN Triggered by Amber Rule 4 (Rule Flow: No)
                                          0 -- GREEN - Based on Amber Rule 4 (No), Amber Rule 2 (No), Red Rule 1 (No), Service-Call/New-Product Rule (No) and Amber Rule 1 (Yes)
                                     END
                                 END
                            END
                       END
                  ELSE -- GREEN Triggered by Amber Rule 1 (No)
                       CASE WHEN -- Apply Amber Rule 3 (Standard #)
                            [StandardTrendTotal] <= @Amber_TotalGallons
                       THEN -- AMBER Triggered by Amber Rule 3 (Rule Flow: Yes)
                           CASE WHEN -- Apply Service-Call/New-Product Rule (Product Cal. Request, New Product Exception)
                                ([NewProduct].[EDISID] IS NOT NULL) -- New Product Exception (latest 3 weeks)
                                AND ([SiteConditions].[EDISID] IS NOT NULL -- Calibration Request All
                                     OR 
                                    ([ProductConditions].[Product] IS NOT NULL AND [ProductConditions].[CalRequest] = 1)) -- Calibration Request for Product
                           THEN -- GREEN Triggered by Service-Call/New-Product Rule
                                0 -- GREEN - Based on Service-Call/New-Product Rule (Yes), Amber Rule 1 (No)
                           ELSE -- CONTINUE Triggered by Service-Call/New-Product Rule
                                CASE WHEN -- Apply Amber Rule 4 (Extended #)
                                     [ExtendedTrendTotal] <= @Amber_TotalGallons
                                THEN -- AMBER Triggered by Amber Rule 4 (Rule Flow: Yes)
                                    CASE WHEN -- Apply Red Rule 3 (Extended #)
                                         [ExtendedTrendTotal] <= @Red_TotalGallons
                                    THEN -- RED Triggered by Red Rule 3 (Rule Flow: Yes)
                                         1 -- RED - Based on Red Rule 3 (Yes), Amber Rule 4 (Yes), Service-Call/New-Product Rule (No), Amber Rule 3 (Yes) and Amber Rule 1 (No)
                                    ELSE -- AMBER Remains by Amber Rule 4 (Rule Flow: No)
                                         2 -- AMBER - Based on Red Rule 3 (No), Amber Rule 4 (Yes), Service-Call/New-Product Rule (No), Amber Rule 3 (Yes) and Amber Rule 1 (No)
                                    END
                                ELSE -- GREEN Triggered by Amber Rule 4 (Rule Flow: No)
                                     0 -- GREEN - Based on Amber Rule 4 (No), Amber Rule 3 (Yes), Service-Call/New-Product Rule (No) and Amber Rule 1 (No)
                                END
                           END
                       ELSE -- GREEN Triggered by Amber Rule 3 (Rule Flow: No)
                           0 -- GREEN - Based on Amber Rule 3 (No), Service-Call/New-Product Rule (No) and Amber Rule 1 (No)
                       END
                  END
        ELSE -1 -- Water (or another product category we don't care about)
        END AS [TrafficLight]
FROM (
    SELECT 
        [V].[EDISID],
        [V].[Product],
        [V].[IsCask],
        [V].[IsKeg],
        [V].[IsMetric] AS [IsSyrup],
        SUM(CASE WHEN [V].[WeekCommencing] BETWEEN [S].[FromDate] AND [S].[ToDate] THEN [V].[Dispensed] ELSE 0 END) AS [TotalStandardDispense],
        SUM([V].[StandardTrendTotal]) AS [StandardTrendTotal],
        ABS(ROUND(CASE
            WHEN SUM(CASE WHEN [V].[WeekCommencing] BETWEEN [S].[FromDate] AND [S].[ToDate] THEN [V].[Dispensed] ELSE 0 END) > 0
            THEN SUM([V].[StandardTrendTotal]) / SUM(CASE WHEN [V].[WeekCommencing] BETWEEN [S].[FromDate] AND [S].[ToDate] THEN [V].[Dispensed] ELSE 0 END)
            ELSE 0
            END * 100, 2)) AS [StandardTrendPercent],
        SUM(CASE WHEN [V].[WeekCommencing] BETWEEN [S].[SuperFromDate] AND [S].[ToDate] THEN [V].[Dispensed] ELSE 0 END) AS [TotalExtendedDispense],
        SUM([V].[ExtendedTrendTotal]) AS [ExtendedTrendTotal],
        ABS(ROUND(CASE
            WHEN SUM(CASE WHEN [V].[WeekCommencing] BETWEEN [S].[SuperFromDate] AND [S].[ToDate] THEN [V].[Dispensed] ELSE 0 END) > 0
            THEN SUM([V].[ExtendedTrendTotal]) / SUM(CASE WHEN [V].[WeekCommencing] BETWEEN [S].[FromDate] AND [S].[ToDate] THEN [V].[Dispensed] ELSE 0 END)
            ELSE 0
            END * 100, 2)) AS [ExtendedTrendPercent]
    FROM #Variance [V]
    JOIN #Sites [S] ON [V].[EDISID] = [S].[EDISID]
    JOIN [dbo].[Sites] [Si] ON [S].[EDISID] = [Si].[EDISID]
    WHERE [Si].[Status] NOT IN (2,10) -- Disable Closed (always Grey) and Free-of-Tie (always Green)
    GROUP BY
        [V].[EDISID],
        [V].[Product],
        [V].[IsCask],
        [V].[IsKeg],
        [V].[IsMetric]
    ) AS [Trends]
JOIN @Dispense AS [D] ON [Trends].[EDISID] = [D].[EDISID] AND [Trends].[Product] = [D].[Product]
LEFT JOIN (
    SELECT
        [V].[EDISID],
        [V].[Product],
        CAST(CASE WHEN [CalProd].[Product] IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS [CalRequest]
    FROM (SELECT [EDISID], [Product] FROM #Variance GROUP BY [EDISID], [Product]) AS [V]
    LEFT JOIN @CalibrationRequestForProduct [CalProd] ON [V].[EDISID] = [CalProd].[EDISID] AND [V].[Product] = [CalProd].[Product]
    ) AS [ProductConditions] ON [Trends].[EDISID] = [ProductConditions].[EDISID] AND [Trends].[Product] = [ProductConditions].[Product]
LEFT JOIN @CalibrationRequestForAll AS [SiteConditions] ON [Trends].[EDISID] = [SiteConditions].[EDISID]
LEFT JOIN (SELECT DISTINCT [EDISID] FROM @NewProductsEx) AS [NewProduct] ON [Trends].[EDISID] = [NewProduct].[EDISID]
ORDER BY 
    [Trends].[EDISID], 
    [Trends].[Product]

--SELECT * 
--FROM #Variance
--WHERE [EDISID] = 3451
----AND [Product] = 'John Smiths Extra Smooth'
--ORDER BY [EDISID], [Product], [WeekCommencing]

CREATE TABLE #ExceptionDetail ([EDISID] INT NOT NULL, [Detail] VARCHAR(4000) NOT NULL, [TrafficLightNo] INT)
INSERT INTO #ExceptionDetail ([EDISID], [Detail], [TrafficLightNo])
SELECT 
    [EDISID],
    (CASE 
        WHEN [Status] = 1 THEN 'Red'
        WHEN [Status] = 2 THEN 'Amber'
        WHEN [Status] = 0 THEN 'Green'
    END) + ' - ' + [ProductExceptionList] AS [Detail],
    [Status]
FROM (
    SELECT
        [E].[EDISID],
        MIN([E].[Status]) AS [Status],
        MIN([Info].[ProductList]) AS [ProductExceptionList]
    FROM #Exceptions AS [E]
        JOIN (
        SELECT DISTINCT
            [EDISID],
            SUBSTRING(
                (   SELECT ';' + [Product] + '|' + CASE  WHEN [Status] = 1 THEN 'Red' WHEN [Status] = 2 THEN 'Amber' END
                    FROM #Exceptions AS [Ex]
                    WHERE [Ex].[EDISID] = [E].[EDISID]
                    AND [Ex].[Status] > 0 -- Exclude GREEN
                    FOR XML PATH (''), TYPE).value('.','VARCHAR(4000)')
                ,2, 4000) AS [ProductList]
        FROM #Exceptions AS [E]
        ) AS [Info] ON [E].[EDISID] = [Info].[EDISID]
    WHERE [E].[Status] > 0
    GROUP BY 
        [E].[EDISID]
    ) [Exceptions]
UNION ALL
SELECT 
    [EDISID],
    'Green - No current issues' AS [Detail],
    3 AS [TL]
FROM #Exceptions 
GROUP BY [EDISID]
HAVING SUM([Status]) = 0 -- Green

IF @EnableComments = 1
BEGIN
    -- APPLY THE SITE COMMENTS AND SITE RANKING

    DECLARE @CommentType INT = 1 -- Auditor
    DECLARE @CommentDate DATE = GETDATE()

    DECLARE @GreenComment VARCHAR(4000)
    DECLARE @AmberComment VARCHAR(4000)
    DECLARE @RedComment VARCHAR(4000)
    
    DECLARE @FinalRAG VARCHAR(100) -- Will be set to the 'worst' applicable colour. A string equivalent to the TL Status.
    DECLARE @FinalHeading INT -- Will be set to the 'worst' applicable Heading (5003 - Red, 5002 - Amber, 5000 - Green)
    DECLARE @FinalComment VARCHAR(4000) -- May contain Green, Amber, Red, Amber & Red

    DECLARE @StatusComment VARCHAR(4000) -- Used for status based comments (Closed/Free-of-Tie)
    DECLARE @StatusColour VARCHAR(100)

    /* TODO: Make Stock and Trend agree with their internal handling of the TL.
             Purely so it's easier to follow!
        Stock: 3 = Green, 2 = Amber, 1 = Red
        Trend: 0 = Green, 2 = Amber, 1 = Red
    */

    DECLARE TrendComments CURSOR FAST_FORWARD FOR
    SELECT
        [S].[EDISID],
        [Si].[Status] AS [SiteStatus],
        CASE WHEN [Good].[OverallStatus] = 0
                THEN @CommentTemplateGood
                ELSE NULL 
                END AS [GreenComment],
        CASE WHEN [Bad].[ProductList] IS NOT NULL 
                THEN REPLACE(@CommentTemplateBad, '{products}', [Bad].[ProductList])
                ELSE NULL
                END AS [AmberComment],
        CASE WHEN [Ugly].[ProductList] IS NOT NULL 
                THEN REPLACE(@CommentTemplateUgly, '{products}', [Ugly].[ProductList])
                ELSE NULL
                END AS [RedComment]
    FROM #Sites [S]
    JOIN [dbo].[Sites] [Si] ON [S].[EDISID] = [Si].[EDISID]
    LEFT JOIN (
        SELECT 
            [EDISID],
            MAX([Status]) AS [OverallStatus]
        FROM #Exceptions [E] 
        GROUP BY [EDISID]
        HAVING MAX([Status]) = 0 -- Purely GREEN
    ) AS [Good] ON [S].[EDISID] = [Good].[EDISID]
    LEFT JOIN (
        SELECT DISTINCT
            [EDISID],
            SUBSTRING(
                (   SELECT ', ' + [Product]
                    FROM #Exceptions AS [Ex]
                    WHERE [Ex].[EDISID] = [E].[EDISID]
                    AND [Ex].[Status] = 1 -- RED only
                    FOR XML PATH (''), TYPE).value('.','VARCHAR(4000)')
                ,2, 4000) AS [ProductList]
        FROM #Exceptions AS [E]
        ) AS [Ugly] ON [S].[EDISID] = [Ugly].[EDISID]
    LEFT JOIN (
        SELECT DISTINCT
            [EDISID],
            SUBSTRING(
                (   SELECT ', ' + [Product]
                    FROM #Exceptions AS [Ex]
                    WHERE [Ex].[EDISID] = [E].[EDISID]
                    AND [Ex].[Status] = 2 -- AMBER only
                    FOR XML PATH (''), TYPE).value('.','VARCHAR(4000)')
                ,2, 4000) AS [ProductList]
        FROM #Exceptions AS [E]
        ) AS [Bad] ON [S].[EDISID] = [Bad].[EDISID]

    OPEN TrendComments
    FETCH NEXT FROM TrendComments INTO @CurrentEDISID, @CurrentSiteStatus, @GreenComment, @AmberComment, @RedComment

    WHILE @@FETCH_STATUS = 0
    BEGIN

        -- DELETE ANY EXISTING COMMENT (for Trend or Stock)
        --EXEC [dbo].[DeleteTLComments] @CurrentEDISID
        -- Replaced with functionality in AddOrUpdateSiteComment

        -- WARNING: Don't enable the following line unless debugging a single site
        --          Otherwise this may cause SQL Management Studio to crash due to running out of memory
        --SELECT @CurrentEDISID AS [EDISID], @CurrentSiteStatus AS [SiteStatus], @GreenComment AS [Green], @AmberComment AS [Amber], @RedComment AS [Red]

        IF @CurrentSiteStatus NOT IN (2,10) -- 2:Closed (always Grey) and 10:Free-of-Tie (always Green)
        BEGIN
            -- GREEN
            IF @GreenComment IS NOT NULL 
            BEGIN 
                IF @DebugComments = 1
                BEGIN
                    PRINT CAST(@CurrentEDISID AS VARCHAR) + ' - GREEN (' + @GreenComment + ')'
                END

                SET @FinalHeading = 5000
                SET @FinalRAG = 'Green'
                SET @FinalComment = @GreenComment
                --EXEC AddOrUpdateSiteComment @CurrentEDISID, @CommentType, @CommentDate, 5000, @GreenComment, @MatchedCommentGood, NULL, 'Green'
            END

            -- AMBER
            IF @AmberComment IS NOT NULL
            BEGIN 
                IF @DebugComments = 1
                BEGIN
                    PRINT CAST(@CurrentEDISID AS VARCHAR) + ' - AMBER (' + @AmberComment + ')'
                END

                SET @FinalHeading = 5001
                SET @FinalRAG = 'Amber'
                SET @FinalComment = @AmberComment
                --EXEC AddOrUpdateSiteComment @CurrentEDISID, @CommentType, @CommentDate, 5001, @AmberComment, @MatchedCommentBad, NULL, 'Amber'
            END

            -- RED
            IF @RedComment IS NOT NULL 
            BEGIN 
                IF @DebugComments = 1
                BEGIN
                    PRINT CAST(@CurrentEDISID AS VARCHAR) + ' - RED (' + @RedComment + ')'
                END

                SET @FinalHeading = 5004 -- Will override AMBER
                SET @FinalRAG = 'Red'
                SET @FinalComment = @RedComment + (CASE WHEN @AmberComment IS NOT NULL THEN CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10)+@AmberComment ELSE '' END)

                IF @DebugComments = 1
                BEGIN
                    PRINT CAST(@CurrentEDISID AS VARCHAR) + ' - RED+AMBER (' + @FinalComment + ')'
                END
                --EXEC AddOrUpdateSiteComment @CurrentEDISID, @CommentType, @CommentDate, 5004, @RedComment, @MatchedCommentUgly, NULL, 'Red'
            END

            EXEC AddOrUpdateSiteComment @CurrentEDISID, @CommentType, @CommentDate, @FinalHeading, @FinalComment, NULL, NULL, @FinalRAG
        END
        ELSE
        BEGIN
            IF @CurrentSiteStatus = 2
            BEGIN -- Closed (always Grey)
                SET @StatusComment = 'Grey - ' + @CommentTemplateNA
                SET @StatusColour = 'Grey'
            END
            ELSE IF @CurrentSiteStatus = 10
            BEGIN -- Free-of-Tie (always Green)
                SET @StatusComment = 'Green - ' + @CommentTemplateGood 
                SET @StatusColour = 'Green'
            END

            IF @CurrentSiteStatus <> 10
            BEGIN -- Do not create comment for Free-of-Tie
                IF @DebugComments = 1
                BEGIN
                    PRINT CAST(@CurrentEDISID AS VARCHAR) + ' - ' + UPPER(@StatusColour) + ' (' + @StatusComment + ')'
                END

                EXEC AddOrUpdateSiteComment @CurrentEDISID, @CommentType, @CommentDate, 5000, @StatusComment, NULL, NULL, @StatusColour
            END
        END
        
        FETCH NEXT FROM TrendComments INTO @CurrentEDISID, @CurrentSiteStatus, @GreenComment, @AmberComment, @RedComment
    END

    CLOSE TrendComments
    DEALLOCATE TrendComments
END
ELSE
BEGIN
    PRINT 'Comments Disabled'
END

IF @EnableRankings = 1
BEGIN
    DECLARE @CurrentRankingEDISID INT
    DECLARE @CurrentRankingTL INT

    DECLARE @RankingCategory INT = 1 -- Dispense Category

    DECLARE Cursor_Ranking CURSOR FAST_FORWARD FOR
    SELECT
        [S].[EDISID],
        CASE WHEN [MS].[Status] = 2 -- Closed
             THEN 6
             WHEN [MS].[Status] = 10 -- Free-of-Tie
             THEN 3
             WHEN [SI].[TrafficLightNo] IS NOT NULL
             THEN [SI].[TrafficLightNo]
             ELSE 3
             END AS [TraficLight]
    FROM #Sites AS [S]
    JOIN [dbo].[Sites] AS [MS] ON [S].[EDISID] = [MS].[EDISID]
    LEFT JOIN #ExceptionDetail AS [SI] ON [S].[EDISID] = [SI].[EDISID]

    OPEN Cursor_Ranking

    FETCH NEXT FROM Cursor_Ranking INTO @CurrentRankingEDISID, @CurrentRankingTL

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC [neo].[AssignSiteRanking] @CurrentRankingEDISID, @CurrentRankingTL, '', @EndDate, @RankingCategory

        FETCH NEXT FROM Cursor_Ranking INTO @CurrentRankingEDISID, @CurrentRankingTL
    END

    CLOSE Cursor_Ranking
    DEALLOCATE Cursor_Ranking
END
ELSE
BEGIN
    PRINT 'Rankings Disabled'
END

/* For Testing */
--SELECT 
--    [Ex].[EDISID],
--    [Ex].[Detail],
--    [S].[SiteID]
--FROM (
/* For Testing */
SELECT
    [Ex].[EDISID],
    [Ex].[Detail]
FROM #ExceptionDetail AS [Ex]
JOIN [dbo].[Sites] AS [Si] ON [Ex].[EDISID] = [Si].[EDISID]
WHERE [Si].[Status] NOT IN (2,10) -- Disable Closed (always Grey) and Free-of-Tie (always Green)
/* For Testing */
--WHERE [Ex].[EDISID] = 3451
UNION ALL
SELECT 
    [S].[EDISID],
    CASE WHEN [Si].[Status] = 2 -- Closed
         THEN 'Grey - ' + @CommentTemplateNA
         WHEN [Si].[Status] = 10 -- Free-of-Tie
         THEN 'Green - ' + @CommentTemplateGood 
         END AS [Detail]
FROM #Sites AS [S]
JOIN [dbo].[Sites] AS [Si] ON [S].[EDISID] = [Si].[EDISID]
LEFT JOIN #ExceptionDetail [Ex] ON [S].[EDISID] = [Ex].[EDISID]
WHERE [Si].[Status] IN (2,10) -- Only Closed (always Grey) and Free-of-Tie (always Green)
--AND [Ex].[EDISID] IS NULL
/* For Testing */
--    ) AS [Ex]
--JOIN [dbo].[Sites] AS [S] ON [Ex].[EDISID] = [S].[EDISID]
/* For Testing */
ORDER BY [Ex].[EDISID]

/* For Testing */
IF @DebugProduct <> ''
BEGIN
    SELECT * FROM #Variance 
    WHERE [Product] = @DebugProduct
    ORDER BY EDISID, Product, WeekCommencing
END

/* For Testing */
IF @DebugVariance = 1
BEGIN
    SELECT 
        [V].[EDISID],
        [V].[Product],
        [V].[IsCask],
        [V].[IsKeg],
        [V].[IsMetric] AS [IsSyrup],
        --SUM(CASE WHEN [V].[WeekCommencing] BETWEEN [S].[FromDate] AND [S].[ToDate] THEN [V].[Dispensed] ELSE 0 END) AS [TotalStandardDispense],
        SUM([V].[StandardTrendTotal]) AS [StandardTrendTotal],
        ABS(ROUND(CASE
            WHEN SUM(CASE WHEN [V].[WeekCommencing] BETWEEN [S].[FromDate] AND [S].[ToDate] THEN [V].[Dispensed] ELSE 0 END) > 0
            THEN CASE WHEN SUM([V].[StandardTrendTotal]) <> 0 AND SUM(CASE WHEN [V].[WeekCommencing] BETWEEN [S].[FromDate] AND [S].[ToDate] THEN [V].[Dispensed] ELSE 0 END) <> 0
                      THEN SUM([V].[StandardTrendTotal]) / SUM(CASE WHEN [V].[WeekCommencing] BETWEEN [S].[FromDate] AND [S].[ToDate] THEN [V].[Dispensed] ELSE 0 END)
                      ELSE 0 -- Avoid a divide by zero error
                      END
            ELSE 0
            END * 100, 2)) AS [StandardTrendPercent],
        SUM(CASE WHEN [V].[WeekCommencing] BETWEEN [S].[FromDate] AND [S].[ToDate] THEN [V].[Dispensed] ELSE 0 END) AS [TotalStandardDispense],
        --SUM(CASE WHEN [V].[WeekCommencing] BETWEEN [S].[SuperFromDate] AND [S].[ToDate] THEN [V].[Dispensed] ELSE 0 END) AS [TotalExtendedDispense],
        SUM([V].[ExtendedTrendTotal]) AS [ExtendedTrendTotal],
        ABS(ROUND(CASE
            WHEN SUM(CASE WHEN [V].[WeekCommencing] BETWEEN [S].[SuperFromDate] AND [S].[ToDate] THEN [V].[Dispensed] ELSE 0 END) > 0
            THEN CASE WHEN SUM([V].[ExtendedTrendTotal]) <> 0 AND SUM(CASE WHEN [V].[WeekCommencing] BETWEEN [S].[FromDate] AND [S].[ToDate] THEN [V].[Dispensed] ELSE 0 END) <> 0
                      THEN SUM([V].[ExtendedTrendTotal]) / SUM(CASE WHEN [V].[WeekCommencing] BETWEEN [S].[FromDate] AND [S].[ToDate] THEN [V].[Dispensed] ELSE 0 END)
                      ELSE 0 -- Avoid a divide by zero error
                      END
            ELSE 0
            END * 100, 2)) AS [ExtendedTrendPercent]
    FROM #Variance [V]
    JOIN #Sites [S] ON [V].[EDISID] = [S].[EDISID]
    --WHERE [S].[EDISID] = 3451
    GROUP BY
        [V].[EDISID],
        [V].[Product],
        [V].[IsCask],
        [V].[IsKeg],
        [V].[IsMetric]
END

DROP TABLE #Variance
DROP TABLE #Sites
DROP TABLE #Exceptions
DROP TABLE #ExceptionDetail

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ExceptionNegativeTrend] TO PUBLIC
    AS [dbo];

