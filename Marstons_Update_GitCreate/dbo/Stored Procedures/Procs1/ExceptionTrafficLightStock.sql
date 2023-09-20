CREATE PROCEDURE [dbo].[ExceptionTrafficLightStock]
(
    @EDISID INT = NULL,
    @Auditor VARCHAR(255) = NULL
)
AS

--/* For Testing */ --3787
--DECLARE @Auditor VARCHAR(255) = NULL
--DECLARE @EDISID INT = NULL --30
--DECLARE @SiteID VARCHAR (15) = NULL --'897476'
--IF @SiteID IS NOT NULL
--    SELECT @EDISID = [EDISID] FROM [dbo].[Sites] WHERE [SiteID] = @SiteID

SET NOCOUNT ON;
SET DATEFIRST 1;

DECLARE @EnableHacks BIT = 1 -- Set to 1 before release... :(

DECLARE @EnableLogging BIT = 1
DECLARE @EnableComments BIT = 1
DECLARE @EnableRankings BIT = 1
DECLARE @DebugSite BIT = 0
DECLARE @DebugVariance BIT = 0
DECLARE @DebugConsolidated BIT = 0
DECLARE @DebugStock BIT = 0
DECLARE @DebugDates BIT = 0
DECLARE @DebugDelivery BIT = 0
DECLARE @DebugNewProduct BIT = 0
DECLARE @DebugCalRequest BIT = 0
DECLARE @DebugStockCursor BIT = 0
DECLARE @DebugProduct VARCHAR(200) = ''
DECLARE @DebugComments BIT = 0
DECLARE @DebugRankings BIT = 0

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
--SET @DebugDelivery = 1
--SET @DebugVariance = 1
--SET @DebugConsolidated = 1
--SET @DebugStock = 1
--SET @DebugNewProduct = 1
--SET @DebugCalRequest = 1
--SET @DebugStockCursor = 1
--SET @DebugProduct = 'Consolidated Casks'
--SET @DebugComments = 1
--SET @DebugRankings = 1
--SET @BaseFrom = DATEADD(WEEK, -1, @BaseFrom) 
--SET @BaseTo = DATEADD(WEEK, -1, @BaseTo)

/* Moved out of IF for easier access and to remove debugging variable interference (@EnableComments=0 would invalidate these previously) */
DECLARE @CommentTemplateNA VARCHAR(4000) = 'N/A'
DECLARE @CommentTemplateGood VARCHAR(4000) = 'No current Issues at site'
DECLARE @CommentTemplateBad VARCHAR(4000) = 'Negative Stock on {products}'
DECLARE @CommentTemplateUgly VARCHAR(4000) = 'Significant Negative Stock on {products}'

-- New Installs (req. 4 Weeks min.), Otherwise (up to 18 weeks)
DECLARE @EndDate DATE = @BaseTo
DECLARE @MinNewProd DATE = DATEADD(WEEK, -2, @BaseFrom) -- New Product Exception (examine 3 Weeks)
DECLARE @MinData DATE = DATEADD(WEEK, -3, @BaseFrom)
DECLARE @MaxData DATE = DATEADD(WEEK, -17, @BaseFrom)
DECLARE @MinStock DATE

DECLARE @StockWeeksBack INT
SELECT @StockWeeksBack = [PropertyValue] FROM [dbo].[Configuration] WHERE [PropertyName] = 'Oldest Stock Weeks Back'

SET @MinStock = DATEADD(WEEK, -@StockWeeksBack, @MaxData)

DECLARE @AccurateDeliveryProvided AS BIT
SELECT @AccurateDeliveryProvided = CASE WHEN Configuration.PropertyValue = 'False' THEN 0 ELSE 1 END
FROM [dbo].[Configuration]
WHERE PropertyName = 'Accurate Stock'

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
        @MaxData AS [StandardFromDate], 
        @MinData AS [MinimumFromDate], 
        @EndDate AS [ToDate],
        @MinStock AS [MinimumStockFromDate],
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
    [Stock] FLOAT NOT NULL,
    [CumulativeVariance] FLOAT NOT NULL DEFAULT(0),
    [CumulativeStockVariance] FLOAT NOT NULL DEFAULT(0),
    [IsAdjusted] BIT NOT NULL DEFAULT (0),
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

DECLARE @Red_KegGallons INT
DECLARE @Red_CaskGallons INT
DECLARE @Red_SyrupLitres INT

SELECT  @Amber_KegGallons = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'AmberStockKeg-Gallons'
SELECT  @Amber_CaskGallons = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'AmberStockCask-Gallons'
SELECT  @Amber_SyrupLitres = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'AmberStockSyrup-Litres'

SELECT  @Red_KegGallons = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'RedStockKeg-Gallons'
SELECT  @Red_CaskGallons = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'RedStockCask-Gallons'
SELECT  @Red_SyrupLitres = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'RedStockSyrup-Litres'

--SELECT 
--    @Amber_KegGallons =  CASE WHEN [ParameterName] = 'AmberStockKeg-Gallons'        THEN CAST([NP].[ParameterValue] AS INT) ELSE @Amber_KegGallons   END,
--    @Amber_CaskGallons =  CASE WHEN [ParameterName] = 'AmberStockCask-Gallons'      THEN CAST([NP].[ParameterValue] AS INT) ELSE @Amber_CaskGallons   END,
--    @Amber_SyrupLitres = CASE WHEN [ParameterName] = 'AmberStockSyrup-Litres'       THEN CAST([NP].[ParameterValue] AS INT) ELSE @Amber_SyrupLitres  END,

--    @Red_KegGallons =  CASE WHEN [ParameterName] = 'RedStockKeg-Gallons'     THEN CAST([NP].[ParameterValue] AS INT) ELSE @Red_KegGallons   END,
--    @Red_CaskGallons =  CASE WHEN [ParameterName] = 'RedStockCask-Gallons'    THEN CAST([NP].[ParameterValue] AS INT) ELSE @Red_CaskGallons   END,
--    @Red_SyrupLitres = CASE WHEN [ParameterName] = 'RedStockSyrup-Litres'     THEN CAST([NP].[ParameterValue] AS INT) ELSE @Red_SyrupLitres  END

--FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationParameter] AS [NP]

--SELECT 
--    @Amber_KegGallons, @Amber_CaskGallons, @Amber_SyrupLitres, @Amber_Percent,
--    @Red_KegGallons, @Red_CaskGallons, @Red_SyrupLitres, @Red_Percent

/* **************************************************************************************************************************************************
    Site List

    As each Site will have it's own conditions that could affect the Date Range we need to work on, we need to generate a
    list of From & To dates that are custom for every Site.
    Some Sites will gain NULL values for their From/To dates, this indicates that something about the Site makes it unusable.
*/
CREATE TABLE #Sites ([EDISID] INT NOT NULL PRIMARY KEY, [FromDate] DATE, [ToDate] DATE, [StockDate] DATE, [AccurateStockDate] Date, [VisitDate] DATE, [COTDate] DATE)

/* ************************************************************* */
/* See Service Desk Ticket 20488 for why this abomination exists */

DECLARE @DatabaseHack VARCHAR(200)
SET @DatabaseHack = DB_NAME()

IF @DatabaseHack = 'Punch' AND @EnableHacks = 1
BEGIN
    -- Punch Exclusive Logic
    --  Prevents VRS/COT from having any meaningful impact on the site selection
    INSERT INTO #Sites ([EDISID], [FromDate], [ToDate], [StockDate], [AccurateStockDate], [VisitDate], [COTDate])
    SELECT 
        [S].[EDISID],
        CASE    -- If Site Online is after Minimum From, we cannot use this Site
                WHEN [S].[SiteOnline] > @MinData THEN NULL
                -- If Site Online is after the From date, set it to be the new "From"
                WHEN [S].[SiteOnline] >= @MaxData THEN CAST([S].[SiteOnline] AS DATE)
                -- No overriding conditions detected
                ELSE @MaxData
                END AS [FromDate], -- Calculate the Standard From Date taking the Site Online and Visit Dates into account
        CASE    -- If Site Online is after Minimum From, we cannot use this Site
                WHEN [S].[SiteOnline] > @MinData THEN NULL
                -- Nothing can override the To date
                ELSE @EndDate 
                END AS [ToDate],
        DATEADD(DD, -(DATEPART(DW, [Included].[LatestStock])-1), [Included].[LatestStock]) AS [LastestStock], -- The WC date for which the Stock becomes usable
        [Included].[LatestStock],
        [VR].[WeekCommencing] AS [VisitDate], -- Not used for Punch
        [COT].[WeekCommencing] AS [COTDate]   -- Not used for Punch
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
        AND [SC].[Date] >= @MaxData -- Anything earlier is irrelevant
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
        ) AS [Included] ON [S].[EDISID] = [Included].[EDISID]
    WHERE 
        [S].[Hidden] = 0
    AND (@EDISID IS NULL OR [S].[EDISID] = @EDISID)
    AND	(@Auditor IS NULL OR LOWER([S].[SiteUser]) = LOWER(@Auditor))
    AND [S].[Status] IN (1,2,3,10) -- Active, Closed, Legals & Free-of-Tie
    AND [Included].[EDISID] IS NOT NULL -- Only if a Site has Stock within the last 18 weeks (or within the configurable extension period)
END
/* See Service Desk Ticket 20488 for why this abomination exists */
/* ************************************************************* */
ELSE
BEGIN
    -- Standard Logic
    INSERT INTO #Sites ([EDISID], [FromDate], [ToDate], [StockDate], [AccurateStockDate], [VisitDate], [COTDate])
    SELECT 
        [S].[EDISID],
        CASE    -- If Site Online is after Minimum From, we cannot use this Site
                WHEN [S].[SiteOnline] > @MinData THEN NULL
                -- If VRS Visit is later than all other dates, we cannot use this Site
                WHEN [VR].[WeekCommencing] IS NOT NULL AND [VR].[WeekCommencing] > @EndDate THEN NULL
                -- If COT is later than all other dates, we cannot use this Site
                WHEN [COT].[WeekCommencing] IS NOT NULL AND [COT].[WeekCommencing] > @EndDate THEN NULL
                -- If Site Online is after the From date, set it to be the new "From"
                WHEN [S].[SiteOnline] >= @MaxData THEN CAST([S].[SiteOnline] AS DATE)
                -- No overriding conditions detected
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
        DATEADD(DD, -(DATEPART(DW, [Included].[LatestStock])-1), [Included].[LatestStock]) AS [LastestStock], -- The WC date for which the Stock becomes usable
        [Included].[LatestStock],
        [VR].[WeekCommencing] AS [VisitDate],
        [COT].[WeekCommencing] AS [COTDate]
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
        AND [SC].[Date] >= @MaxData -- Anything earlier is irrelevant
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
        ) AS [Included] ON [S].[EDISID] = [Included].[EDISID]
    WHERE 
        [S].[Hidden] = 0
    AND (@EDISID IS NULL OR [S].[EDISID] = @EDISID)
    AND	(@Auditor IS NULL OR LOWER([S].[SiteUser]) = LOWER(@Auditor))
    AND [S].[Status] IN (1,2,3,10) -- Active, Closed, Legals & Free-of-Tie
    AND ([Included].[EDISID] IS NOT NULL -- Only if a Site has Stock within the last 18 weeks (or within the configurable extension period)
        AND
        [Included].[LatestStock] >=
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

IF @DebugSite = 1
BEGIN
    SELECT * FROM #Sites AS [Si]
END


/* ************************************************************* */
/* See Service Desk Ticket 20488 for why this abomination exists */

IF @DatabaseHack = 'Punch' AND @EnableHacks = 1 -- @DatabaseHack value has been set before #Sites insert
BEGIN
    -- Hard-coded to prevent Punch from accepting configured values
    --SELECT 
    --    @Amber_KegGallons, @Amber_CaskGallons, @Amber_SyrupLitres,
    --    @Red_KegGallons, @Red_CaskGallons, @Red_SyrupLitres

    SET @Amber_CaskGallons = -5
    SET @Amber_KegGallons = -5

    SET @Red_CaskGallons = -11
    SET @Red_KegGallons = -11

    --SELECT 
    --    @Amber_KegGallons, @Amber_CaskGallons, @Amber_SyrupLitres,
    --    @Red_KegGallons, @Red_CaskGallons, @Red_SyrupLitres

    -- Punch does not support the "VRS/COT" restrictions so we abuse those fields to instead apply the "Latest Reporting Week" restriction
    UPDATE #Sites
    SET [VisitDate] = DATEADD(DAY, -6, @EndDate),
        [COTDate] = DATEADD(DAY, -6, @EndDate)
END

/* See Service Desk Ticket 20488 for why this abomination exists */
/* ************************************************************* */


CREATE TABLE #SiteProductStock ([EDISID] INT NOT NULL, [ProductID] INT NOT NULL DEFAULT(0), [BeforeDelivery] BIT NOT NULL, [IsCask] BIT NOT NULL, [Stock] FLOAT NOT NULL PRIMARY KEY ([EDISID], [ProductID]))

INSERT INTO #SiteProductStock ([EDISID], [ProductID], [BeforeDelivery], [IsCask], [Stock])
SELECT
    [S].[EDISID],
    [St].[ProductID],
    [St].[BeforeDelivery],
    [P].[IsCask],
    [St].[Quantity]
FROM [dbo].[Stock] AS [St]
JOIN [dbo].[MasterDates] AS [MD] ON [St].[MasterDateID] = [MD].[ID]
JOIN #Sites AS [S] ON [MD].[EDISID] = [S].[EDISID]
JOIN [dbo].[Sites] AS [Si] ON [S].[EDISID] = [Si].[EDISID]
JOIN [dbo].[Products] AS [P] ON [St].[ProductID] = [P].[ID]
JOIN (
    SELECT
        [S].[EDISID],
        [St].[ProductID],
        COUNT([St].[Quantity]) AS [Count]
    FROM [dbo].[Stock] AS [St]
    JOIN [dbo].[MasterDates] AS [MD] ON [St].[MasterDateID] = [MD].[ID]
    JOIN #Sites AS [S] ON [MD].[EDISID] = [S].[EDISID]
    JOIN [dbo].[Sites] AS [Si] ON [S].[EDISID] = [Si].[EDISID]
    JOIN [dbo].[Products] AS [P] ON [St].[ProductID] = [P].[ID]
    WHERE 
        [S].[AccurateStockDate] = [MD].[Date]
    AND [Si].[Status] NOT IN (2,10) -- Closed & FoT
    GROUP BY
        [S].[EDISID],
        [St].[ProductID]
    HAVING
        COUNT([St].[Quantity]) = 1
    ) As [Valid] ON [S].[EDISID] = [Valid].[EDISID] AND [P].[ID] = [Valid].[ProductID]
WHERE 
    [S].[AccurateStockDate] = [MD].[Date]
AND [Si].[Status] NOT IN (2,10) -- Closed & FoT

--DELETE FROM #SiteProductStock 
--WHERE [IsCask] = 1 AND [BeforeDelivery] = 0

IF @DebugStock = 1
BEGIN
    SELECT
        [S].[EDISID],
        [St].[ProductID],
        COUNT([St].[Quantity]) AS [Count]
    FROM [dbo].[Stock] AS [St]
    JOIN [dbo].[MasterDates] AS [MD] ON [St].[MasterDateID] = [MD].[ID]
    JOIN #Sites AS [S] ON [MD].[EDISID] = [S].[EDISID]
    JOIN [dbo].[Sites] AS [Si] ON [S].[EDISID] = [Si].[EDISID]
    JOIN [dbo].[Products] AS [P] ON [St].[ProductID] = [P].[ID]
    WHERE 
        [S].[AccurateStockDate] = [MD].[Date]
    AND [Si].[Status] NOT IN (2,10) -- Closed & FoT
    GROUP BY
        [S].[EDISID],
        [St].[ProductID]
    --HAVING
        --COUNT([St].[Quantity]) = 1

    SELECT
        --[P].[Description] AS [Product],
        SUM([SPS].Stock) AS [Total Cask Stock]
    FROM #SiteProductStock AS [SPS]
    --JOIN [dbo].[Products] AS [P] ON [SPS].[ProductID] = [P].[ID]
    WHERE [SPS].[IsCask] = 1
    --GROUP BY [P].[Description]
    --ORDER BY [P].[Description]

    SELECT * 
    FROM #SiteProductStock AS [SPS]
    JOIN [dbo].[Products] AS [P] ON [SPS].[ProductID] = [P].[ID]
END

IF @DebugDelivery = 1
BEGIN
    SELECT
        [P].[ID] AS [ProductID],
        [P].[Description] AS [Product],
        [MD].[Date] AS [DeliveryDate],
        [S].[AccurateStockDate] AS [StockDate],
        [P].[IsCask],
        [D].[Quantity] AS [DeliveryQuantity],
        [SPS].[Stock] AS [StockQuantity]
    FROM [dbo].[Delivery] AS [D]
    JOIN [dbo].[Products] AS [P] ON [D].[Product] = [P].[ID]
    JOIN [dbo].[MasterDates] AS [MD] ON [D].[DeliveryID] = [MD].[ID]
    JOIN #Sites AS [S] ON [MD].[EDISID] = [S].[EDISID]
    JOIN #SiteProductStock AS [SPS] ON [S].[EDISID] = [SPS].[EDISID] AND [P].[ID] = [SPS].[ProductID]
    WHERE 
        DATEADD(DAY, 0, DATEDIFF(DAY, 0, DATEADD(DAY, -DATEPART(WEEKDAY, [MD].[Date]) + 1, [MD].[Date]))) 
         = 
        DATEADD(DAY, 0, DATEDIFF(DAY, 0, DATEADD(DAY, -DATEPART(WEEKDAY, [S].[AccurateStockDate]) + 1, [S].[AccurateStockDate]))) 

    SELECT
        'Consolidated Casks',
        [MD].[Date] AS [DeliveryDate],
        [S].[AccurateStockDate] AS [StockDate],
        SUM([D].[Quantity]) AS [DeliveryQuantity],
        SUM([SPS].[Stock]) AS [StockQuantity],
        CASE WHEN (@AccurateDeliveryProvided = 1 AND (([S].[AccurateStockDate] < [MD].[Date]) OR ([MD].[Date] = [S].[AccurateStockDate] AND [SPS].[BeforeDelivery] = 1)))
                   OR
                  (@AccurateDeliveryProvided = 0 AND [SPS].[BeforeDelivery] = 1)
             THEN -- Stock occurs before Deliveries, so both are used
                SUM([D].[Quantity]) + SUM([SPS].[Stock]) 
             WHEN (@AccurateDeliveryProvided = 1 AND (([MD].[Date] < [S].[AccurateStockDate]) OR ([MD].[Date] = [S].[AccurateStockDate] AND [SPS].[BeforeDelivery] = 0)))
                   OR
                  (@AccurateDeliveryProvided = 0 AND [SPS].[BeforeDelivery] = 0)
             THEN -- Stock occurs after Deliveries, so only Stock is used
                SUM([SPS].[Stock])
             END AS [DeliveredStock]
    FROM [dbo].[Delivery] AS [D]
    JOIN [dbo].[Products] AS [P] ON [D].[Product] = [P].[ID]
    JOIN [dbo].[MasterDates] AS [MD] ON [D].[DeliveryID] = [MD].[ID]
    JOIN #Sites AS [S] ON [MD].[EDISID] = [S].[EDISID]
    JOIN #SiteProductStock AS [SPS] ON [S].[EDISID] = [SPS].[EDISID] AND [P].[ID] = [SPS].[ProductID]
    WHERE 
        DATEADD(DAY, 0, DATEDIFF(DAY, 0, DATEADD(DAY, -DATEPART(WEEKDAY, [MD].[Date]) + 1, [MD].[Date]))) 
         = 
        DATEADD(DAY, 0, DATEDIFF(DAY, 0, DATEADD(DAY, -DATEPART(WEEKDAY, [S].[AccurateStockDate]) + 1, [S].[AccurateStockDate]))) 
    AND [P].[IsCask] = 1
    GROUP BY 
        [MD].[Date],
        [S].[AccurateStockDate],
        [SPS].[BeforeDelivery]
END

--SELECT
--    [EDISID],
--    0 AS [ProductID],
--    [BeforeDelivery],
--    [IsCask],
--    SUM([Stock]) AS [Quantity]
--FROM #SiteProductStock AS [SPS]
--WHERE [IsCask] = 1
--GROUP BY
--    [EDISID],
--    [BeforeDelivery],
--    [IsCask]

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
    Stock - Only the latest batch of Stock for the period is used (as it will be the most accurate)
    The Internal Cache
*/

--/* **************************************************************************************************************************************************
--    Cumulative Stock Variance
--*/

DECLARE @SiteStockVariance TABLE ([EDISID] INT NOT NULL, [Product] VARCHAR(50) NOT NULL, [Stock] FLOAT NOT NULL, [ProductType] INT NOT NULL)
-- Product Type : 1=Cask, 2=Keg, 3=Metric/Syrup

DECLARE @CurrentEDISID INT
DECLARE @CurrentSiteStatus INT
DECLARE @CurrentWC DATE
DECLARE @CurrentProduct VARCHAR(50)
DECLARE @CurrentStockVariance FLOAT
DECLARE @CurrentStockCV FLOAT
DECLARE @CurrentIsMetric BIT
DECLARE @CurrentProductType INT
DECLARE @CurrentMinimumDate DATE

DECLARE @PreviousEDISID INT
DECLARE @PreviousWC DATE
DECLARE @PreviousProduct VARCHAR(50)
DECLARE @PreviousStockVariance FLOAT
DECLARE @PreviousStockCV FLOAT
DECLARE @PreviousIsMetric BIT
DECLARE @PreviousProductType INT

DECLARE @WorstStockCV FLOAT

/* For Testing */
IF @DebugProduct <> ''
BEGIN
    SELECT
        [PCVI].[EDISID],
        [PCVI].[WeekCommencing],
        [P].[Description] AS [Product],
        CASE WHEN [P].[IsMetric] = 1 THEN [PCVI].[Delivered] * @ToLitres
             ELSE [PCVI].[Delivered] * @ToGallons
             END AS [Delivered],
        CASE WHEN [P].[IsMetric] = 1 THEN [PCVI].[Dispensed] * @ToLitres
             ELSE [PCVI].[Dispensed] * @ToGallons
             END AS [Dispensed],
        CASE WHEN [P].[IsMetric] = 1 THEN [PCVI].[StockAdjustedDispensed] * @ToLitres
             ELSE [PCVI].[StockAdjustedDispensed] * @ToGallons
             END AS [Dispensed],
        CASE WHEN [PCVI].[WeekCommencing] >= [S].[StockDate] -- Only use the current Stock Take
             THEN CASE WHEN [P].[IsMetric] = 1 THEN [PCVI].[Stock] * @ToLitres
                       ELSE [PCVI].[Stock] * @ToGallons
                       END
             ELSE NULL END AS [Stock],
        CASE WHEN [PCVI].[WeekCommencing] >= [S].[StockDate] -- Only use the current Stock Take
             THEN CASE WHEN [P].[IsMetric] = 1 THEN [PCVI].[StockAdjustedVariance] * @ToLitres 
                       ELSE [PCVI].[StockAdjustedVariance] * @ToGallons
                       END
             ELSE NULL END AS [StockVariance], 
        CASE WHEN [P].[IsMetric] = 1 THEN 3 ELSE 2 END AS [ProductType],
        CASE WHEN @MaxData >= COALESCE([S].[VisitDate], @MaxData) AND @MaxData >= COALESCE([S].[COTDate], @MaxData)
             THEN @MaxData
             WHEN [S].[VisitDate] >= COALESCE([S].[COTDate], [S].[VisitDate])
             THEN [S].[VisitDate]
             ELSE [S].[COTDate]
             END AS [UsableStockDate]
        --[P].[IsCask],
        --[P].[IsMetric]
    FROM [dbo].[PeriodCacheVarianceInternal] AS [PCVI]
    JOIN #Sites AS [S] ON [PCVI].[EDISID] = [S].[EDISID]
    JOIN [dbo].[Sites] AS [Si] ON [S].[EDISID] = [Si].[EDISID]
    JOIN [dbo].[Products] AS [P] ON [PCVI].[ProductID] = [P].[ID]
    JOIN #SiteProductStock AS [SPS] ON [S].[EDISID] = [SPS].[EDISID] AND [P].[ID] = [SPS].[ProductID]
    WHERE (@EDISID IS NULL OR [PCVI].[EDISID] = @EDISID)
    AND [Si].[Status] NOT IN (2, 10) -- Closed & Free-of-Tie
    AND [PCVI].[WeekCommencing] BETWEEN [S].[StockDate] AND [S].[ToDate]
    AND [PCVI].[IsTied] = 1 -- Exclude Untied
    AND [P].[IsCask] = 0 -- Exclude Casks 
    AND [P].[IsWater] = 0 -- Exclude Water
    AND [P].[Description] = @DebugProduct
    --ORDER BY 
    --    [PCVI].[EDISID],
    --    [P].[Description],
    --    [PCVI].[WeekCommencing]
END

IF @DebugConsolidated = 1
BEGIN
    SELECT
        [PCVI].[EDISID],
        [PCVI].[WeekCommencing],
        'Consolidated Casks' AS [Product],
        --[P].[Description] AS [Product],
        SUM([PCVI].[Delivered] * @ToGallons) AS [Delivered],
        SUM([PCVI].[StockAdjustedDelivered] * @ToGallons) AS [AdjustedDelivered],
        SUM([PCVI].[Dispensed] * @ToGallons) AS [Dispensed],
        SUM([PCVI].[StockAdjustedDispensed] * @ToGallons) AS [AdjustedDispensed],
        SUM(CASE WHEN [PCVI].[WeekCommencing] >= [S].[StockDate] -- Only use the current Stock Take
                    THEN [PCVI].[Stock] * @ToGallons
                    ELSE NULL END) AS [Stock],
        [SPS].[StockAfterDelivery],
        [SPS].[StockBeforeDelivery],
        --SUM([PCVI].[Stock] - [PCVI].[StockAdjustedDispensed]) * @ToGallons AS [StockMinusDispensed],
        --CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] 
        --         THEN CASE WHEN [StockAfterDelivery] > 0 
        --                   THEN [StockAfterDelivery] 
        --                   ELSE [StockBeforeDelivery] + SUM([PCVI].[Delivered]) END - SUM([PCVI].[StockAdjustedDispensed])
        --         ELSE NULL 
        --END * @ToGallons AS [Stock0],
        --SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] THEN (([SPS].[StockBeforeDelivery] - [PCVI].[StockAdjustedDispensed]) + [PCVI].[Delivered]) * @ToGallons ELSE NULL END) AS [Stock1],
        --SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] THEN (([SPS].[StockBeforeDelivery] - [PCVI].[StockAdjustedDispensed]) + [PCVI].[StockAdjustedDelivered]) * @ToGallons ELSE NULL END) AS [Stock1a],
        --SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] THEN ([SPS].[StockAfterDelivery] - [PCVI].[StockAdjustedDispensed]) * @ToGallons ELSE NULL END) AS [Stock2],
        --SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] THEN ([SPS].[StockAfterDelivery] - [PCVI].[Dispensed]) * @ToGallons ELSE NULL END) AS [Stock3],
        --SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] THEN (((([SPS].[StockBeforeDelivery]) + [PCVI].[Delivered]) - [PCVI].[Dispensed]) - [PCVI].[Delivered]) * @ToGallons ELSE NULL END) AS [Stock4],
        --SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] THEN (((([SPS].[StockBeforeDelivery]) + [PCVI].[StockAdjustedDelivered]) - [PCVI].[Dispensed]) - [PCVI].[StockAdjustedDelivered]) * @ToGallons ELSE NULL END) AS [Stock4a],
        --SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] THEN (([PCVI].[Stock] - [PCVI].[StockAdjustedDispensed]) + [PCVI].[Delivered]) * @ToGallons ELSE NULL END) AS [StockX],
        --SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] THEN (([PCVI].[Stock] - [PCVI].[StockAdjustedDispensed]) + [PCVI].[StockAdjustedDelivered]) * @ToGallons ELSE NULL END) AS [StockXa],
        --SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] THEN (([PCVI].[Stock] - [PCVI].[StockAdjustedDispensed])) * @ToGallons ELSE NULL END) AS [StockY],
        SUM([PCVI].[StockAdjustedVariance] * @ToGallons) AS [StockVariance]
        /*
        SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate]
                    --THEN ((([SPS].[StockBeforeDelivery] - [PCVI].[StockAdjustedDispensed]) + [PCVI].[DeliveredAfterStock])
                    --       +
                    --      ([SPS].[StockAfterDelivery] - [PCVI].[StockAdjustedDispensed]))
                    --       * @ToGallons
                    THEN NULL
                    WHEN [PCVI].[WeekCommencing] > [S].[StockDate]
                    THEN [PCVI].[StockAdjustedVariance] * @ToGallons
                    ELSE NULL END) AS [StockVariance] --, 
        */
        --[P].[IsCask],
        --[P].[IsMetric]
    FROM [dbo].[PeriodCacheVarianceInternal] AS [PCVI]
    JOIN #Sites AS [S] ON [PCVI].[EDISID] = [S].[EDISID]
    JOIN [dbo].[Sites] AS [Si] ON [S].[EDISID] = [Si].[EDISID]
    JOIN [dbo].[Products] AS [P] ON [PCVI].[ProductID] = [P].[ID]
    JOIN (
        /* Apply fix here? */
        SELECT
            [EDISID],
            SUM(CASE WHEN [BeforeDelivery] = 1 THEN [Stock] ELSE 0 END) AS [StockBeforeDelivery],
            SUM(CASE WHEN [BeforeDelivery] = 0 THEN [Stock] ELSE 0 END) AS [StockAfterDelivery]
        FROM #SiteProductStock AS [SPS]
        WHERE [IsCask] = 1
        GROUP BY 
            [EDISID]
        ) AS [SPS] ON [S].[EDISID] = [SPS].[EDISID]
    WHERE (@EDISID IS NULL OR [PCVI].[EDISID] = @EDISID)
    AND [Si].[Status] NOT IN (2, 10) -- Closed & Free-of-Tie
    AND [PCVI].[WeekCommencing] BETWEEN [S].[StockDate] AND [S].[ToDate]
    AND [PCVI].[IsTied] = 1 -- Exclude Untied
    AND [P].[IsCask] = 1 -- Include Casks 
    AND [P].[IsMetric] = 0 AND [P].[IsWater] = 0 -- Used to filter out corrupted data (discovered in some UAT databases)
    --AND [P].[Description] = 'Consolidated Casks' /* For Testing */
    GROUP BY
        [PCVI].[EDISID],
        [PCVI].[WeekCommencing],
        [SPS].[StockAfterDelivery],
        [SPS].[StockBeforeDelivery]--,
        --[S].[StockDate]
    --    [P].[Description]
END

IF @DebugVariance = 1
BEGIN
    SELECT
        [PCVI].[EDISID],
        [PCVI].[WeekCommencing],
        [P].[Description] AS [Product],
        --CASE WHEN [P].[IsMetric] = 1 THEN [PCVI].[Delivered] * @ToLitres
        --     ELSE [PCVI].[Delivered] * @ToGallons
        --     END AS [Delivered],
        --CASE WHEN [P].[IsMetric] = 1 THEN [PCVI].[Dispensed] * @ToLitres
        --     ELSE [PCVI].[Dispensed] * @ToGallons
        --     END AS [Dispensed],
        --CASE WHEN [PCVI].[WeekCommencing] >= [S].[StockDate] -- Only use the current Stock Take
        --     THEN CASE WHEN [P].[IsMetric] = 1 THEN [PCVI].[Stock] * @ToLitres
        --               ELSE [PCVI].[Stock] * @ToGallons
        --               END
        --     ELSE NULL END AS [Stock],
        CASE WHEN [PCVI].[WeekCommencing] >= [S].[StockDate] -- Only use the current Stock Take
             THEN CASE WHEN [P].[IsMetric] = 1 THEN [PCVI].[StockAdjustedVariance] * @ToLitres 
                       ELSE [PCVI].[StockAdjustedVariance] * @ToGallons
                       END
             ELSE NULL END AS [StockVariance], 
        CASE WHEN [P].[IsMetric] = 1 THEN 3 ELSE 2 END AS [ProductType],
        CASE WHEN @MaxData >= COALESCE([S].[VisitDate], @MaxData) AND @MaxData >= COALESCE([S].[COTDate], @MaxData)
             THEN @MaxData
             WHEN [S].[VisitDate] >= COALESCE([S].[COTDate], [S].[VisitDate])
             THEN [S].[VisitDate]
             ELSE [S].[COTDate]
             END AS [UsableStockDate]
        --[P].[IsCask],
        --[P].[IsMetric]
    FROM [dbo].[PeriodCacheVarianceInternal] AS [PCVI]
    JOIN #Sites AS [S] ON [PCVI].[EDISID] = [S].[EDISID]
    JOIN [dbo].[Sites] AS [Si] ON [S].[EDISID] = [Si].[EDISID]
    JOIN [dbo].[Products] AS [P] ON [PCVI].[ProductID] = [P].[ID]
    JOIN #SiteProductStock AS [SPS] ON [S].[EDISID] = [SPS].[EDISID] AND [P].[ID] = [SPS].[ProductID]
    WHERE (@EDISID IS NULL OR [PCVI].[EDISID] = @EDISID)
    AND [Si].[Status] NOT IN (2, 10) -- Closed & Free-of-Tie
    AND [PCVI].[WeekCommencing] BETWEEN [S].[StockDate] AND [S].[ToDate]
    AND [PCVI].[IsTied] = 1 -- Exclude Untied
    AND [P].[IsCask] = 0 -- Exclude Casks 
    AND [P].[IsWater] = 0 -- Exclude Water
    --AND [P].[Description] = 'Bulmers Strongbow' /* For Testing */
    --ORDER BY 
    --    [PCVI].[EDISID],
    --    [P].[Description],
    --    [PCVI].[WeekCommencing]
    UNION ALL -- Consolidated Casks
    SELECT
        [Consolidated].[EDISID],
        [Consolidated].[WeekCommencing],
        [Consolidated].[Product],
        --[Consolidated].[Delivered],
        --[Consolidated].[AdjustedDelivered],
        --[Consolidated].[Dispensed],
        --[Consolidated].[AdjustedDispensed],
        --[Consolidated].[Stock],
        --[Consolidated].[StockBeforeDelivery],
        --[Consolidated].[StockAfterDelivery],
        [Consolidated].[StockVariance],
        /*
        CASE WHEN [WeekCommencing] = [S].[StockDate] 
             THEN CASE WHEN [SPS].[BeforeDelivery] = 0
                       THEN [StockAfterDelivery] 
                       ELSE [StockBeforeDelivery] + [Delivered] END - [AdjustedDispensed]
              ELSE [StockVariance]
        END AS [StockVariance],
        */
        1 AS [ProductType],
        CASE WHEN @MaxData >= COALESCE([S].[VisitDate], @MaxData) AND @MaxData >= COALESCE([S].[COTDate], @MaxData)
             THEN @MaxData
             WHEN [S].[VisitDate] >= COALESCE([S].[COTDate], [S].[VisitDate])
             THEN [S].[VisitDate]
             ELSE [S].[COTDate]
             END AS [UsableStockDate]
    FROM (
        SELECT
            [PCVI].[EDISID],
            [PCVI].[WeekCommencing],
            'Consolidated Casks' AS [Product],
            --[P].[Description] AS [Product],
            SUM([PCVI].[Delivered] * @ToGallons) AS [Delivered],
            SUM([PCVI].[StockAdjustedDelivered] * @ToGallons) AS [AdjustedDelivered],
            SUM([PCVI].[Dispensed] * @ToGallons) AS [Dispensed],
            SUM([PCVI].[StockAdjustedDispensed] * @ToGallons) AS [AdjustedDispensed],
            SUM(CASE WHEN [PCVI].[WeekCommencing] >= [S].[StockDate] -- Only use the current Stock Take
                     THEN [PCVI].[Stock] * @ToGallons
                     ELSE NULL END) AS [Stock],
            [SPS].[StockAfterDelivery],
            [SPS].[StockBeforeDelivery],
            --SUM([PCVI].[Stock] - [PCVI].[StockAdjustedDispensed]) * @ToGallons AS [StockMinusDispensed],
            --CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] 
            --         THEN CASE WHEN [StockAfterDelivery] > 0 
            --                   THEN [StockAfterDelivery] 
            --                   ELSE [StockBeforeDelivery] + SUM([PCVI].[Delivered]) END - SUM([PCVI].[StockAdjustedDispensed])
            --         ELSE NULL 
            --END * @ToGallons AS [Stock0],
            --SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] THEN (([SPS].[StockBeforeDelivery] - [PCVI].[StockAdjustedDispensed]) + [PCVI].[Delivered]) * @ToGallons ELSE NULL END) AS [Stock1],
            --SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] THEN (([SPS].[StockBeforeDelivery] - [PCVI].[StockAdjustedDispensed]) + [PCVI].[StockAdjustedDelivered]) * @ToGallons ELSE NULL END) AS [Stock1a],
            --SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] THEN ([SPS].[StockAfterDelivery] - [PCVI].[StockAdjustedDispensed]) * @ToGallons ELSE NULL END) AS [Stock2],
            --SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] THEN ([SPS].[StockAfterDelivery] - [PCVI].[Dispensed]) * @ToGallons ELSE NULL END) AS [Stock3],
            --SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] THEN (((([SPS].[StockBeforeDelivery]) + [PCVI].[Delivered]) - [PCVI].[Dispensed]) - [PCVI].[Delivered]) * @ToGallons ELSE NULL END) AS [Stock4],
            --SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] THEN (((([SPS].[StockBeforeDelivery]) + [PCVI].[StockAdjustedDelivered]) - [PCVI].[Dispensed]) - [PCVI].[StockAdjustedDelivered]) * @ToGallons ELSE NULL END) AS [Stock4a],
            --SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] THEN (([PCVI].[Stock] - [PCVI].[StockAdjustedDispensed]) + [PCVI].[Delivered]) * @ToGallons ELSE NULL END) AS [StockX],
            --SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] THEN (([PCVI].[Stock] - [PCVI].[StockAdjustedDispensed]) + [PCVI].[StockAdjustedDelivered]) * @ToGallons ELSE NULL END) AS [StockXa],
            --SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] THEN (([PCVI].[Stock] - [PCVI].[StockAdjustedDispensed])) * @ToGallons ELSE NULL END) AS [StockY],
            SUM([PCVI].[StockAdjustedVariance] * @ToGallons) AS [StockVariance]
            /*
            SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate]
                     --THEN ((([SPS].[StockBeforeDelivery] - [PCVI].[StockAdjustedDispensed]) + [PCVI].[DeliveredAfterStock])
                     --       +
                     --      ([SPS].[StockAfterDelivery] - [PCVI].[StockAdjustedDispensed]))
                     --       * @ToGallons
                     THEN NULL
                     WHEN [PCVI].[WeekCommencing] > [S].[StockDate]
                     THEN [PCVI].[StockAdjustedVariance] * @ToGallons
                     ELSE NULL END) AS [StockVariance] --, -- TODO: Use this to get a cumulative variance
            */
            --[P].[IsCask],
            --[P].[IsMetric]
        FROM [dbo].[PeriodCacheVarianceInternal] AS [PCVI]
        JOIN #Sites AS [S] ON [PCVI].[EDISID] = [S].[EDISID]
        JOIN [dbo].[Sites] AS [Si] ON [S].[EDISID] = [Si].[EDISID]
        JOIN [dbo].[Products] AS [P] ON [PCVI].[ProductID] = [P].[ID]
        JOIN (
            SELECT
                [EDISID],
                SUM(CASE WHEN [BeforeDelivery] = 1 THEN [Stock] ELSE 0 END) AS [StockBeforeDelivery],
                SUM(CASE WHEN [BeforeDelivery] = 0 THEN [Stock] ELSE 0 END) AS [StockAfterDelivery]
            FROM #SiteProductStock AS [SPS]
            WHERE [IsCask] = 1
            GROUP BY 
                [EDISID]
            ) AS [SPS] ON [S].[EDISID] = [SPS].[EDISID]
        WHERE (@EDISID IS NULL OR [PCVI].[EDISID] = @EDISID)
        AND [Si].[Status] NOt IN (2, 10) -- Closed & Free-of-Tie
        AND [PCVI].[WeekCommencing] BETWEEN [S].[StockDate] AND [S].[ToDate]
        AND [PCVI].[IsTied] = 1 -- Exclude Untied
        AND [P].[IsCask] = 1 -- Include Casks 
        AND [P].[IsMetric] = 0 AND [P].[IsWater] = 0 -- Used to filter out corrupted data (discovered in some UAT databases)
        --AND [P].[Description] = 'Consolidated Casks' /* For Testing */
        GROUP BY
            [PCVI].[EDISID],
            [PCVI].[WeekCommencing],
            [SPS].[StockAfterDelivery],
            [SPS].[StockBeforeDelivery]--,
            --[S].[StockDate]
        --    [P].[Description]
        ) AS [Consolidated]
    JOIN #Sites AS [S] ON [Consolidated].[EDISID] = [S].[EDISID]
    JOIN [dbo].[Sites] AS [Si] ON [S].[EDISID] = [Si].[EDISID]
    JOIN (
        SELECT
            [EDISID],
            CAST(MAX(CAST([BeforeDelivery] AS INT)) AS BIT) AS [BeforeDelivery] -- Consolidated can't mix this as dispense isn't seperate, so use it if any related product has it enabled
        FROM #SiteProductStock AS [SPS]
        WHERE [IsCask] = 1
        GROUP BY 
            [EDISID]) AS [SPS] ON [S].[EDISID] = [SPS].[EDISID]
    WHERE [Si].[Status] NOT IN (2,10) -- Closed & Free-of-Tie
    ORDER BY 
        [EDISID],
        [Product],
        [WeekCommencing]
END

-- The data in this table is only useful for Keg/Syrup products
-- Consolidated Casks need to be worked out seperately
DECLARE Cursor_Variance CURSOR LOCAL FAST_FORWARD FOR
SELECT
    [PCVI].[EDISID],
    [PCVI].[WeekCommencing],
    [P].[Description] AS [Product],
    --CASE WHEN [P].[IsMetric] = 1 THEN [PCVI].[Delivered] * @ToLitres
    --     ELSE [PCVI].[Delivered] * @ToGallons
    --     END AS [Delivered],
    --CASE WHEN [P].[IsMetric] = 1 THEN [PCVI].[Dispensed] * @ToLitres
    --     ELSE [PCVI].[Dispensed] * @ToGallons
    --     END AS [Dispensed],
    --CASE WHEN [PCVI].[WeekCommencing] >= [S].[StockDate] -- Only use the current Stock Take
    --     THEN CASE WHEN [P].[IsMetric] = 1 THEN [PCVI].[Stock] * @ToLitres
    --               ELSE [PCVI].[Stock] * @ToGallons
    --               END
    --     ELSE NULL END AS [Stock],
    CASE WHEN [PCVI].[WeekCommencing] >= [S].[StockDate] -- Only use the current Stock Take
         THEN CASE WHEN [P].[IsMetric] = 1 THEN [PCVI].[StockAdjustedVariance] * @ToLitres 
                   ELSE [PCVI].[StockAdjustedVariance] * @ToGallons
                   END
         ELSE NULL END AS [StockVariance], -- TODO: Use this to get a cumulative variance
    CASE WHEN [P].[IsMetric] = 1 THEN 3 ELSE 2 END AS [ProductType],
    CASE WHEN @MaxData >= COALESCE([S].[VisitDate], @MaxData) AND @MaxData >= COALESCE([S].[COTDate], @MaxData)
         THEN @MaxData
         WHEN [S].[VisitDate] >= COALESCE([S].[COTDate], [S].[VisitDate])
         THEN [S].[VisitDate]
         ELSE [S].[COTDate]
         END AS [UsableStockDate]
    --[P].[IsCask],
    --[P].[IsMetric]
FROM [dbo].[PeriodCacheVarianceInternal] AS [PCVI]
JOIN #Sites AS [S] ON [PCVI].[EDISID] = [S].[EDISID]
JOIN [dbo].[Sites] AS [Si] ON [S].[EDISID] = [Si].[EDISID]
JOIN [dbo].[Products] AS [P] ON [PCVI].[ProductID] = [P].[ID]
JOIN #SiteProductStock AS [SPS] ON [S].[EDISID] = [SPS].[EDISID] AND [P].[ID] = [SPS].[ProductID]
WHERE (@EDISID IS NULL OR [PCVI].[EDISID] = @EDISID)
AND [Si].[Status] NOT IN (2, 10) -- Closed & Free-of-Tie
AND [PCVI].[WeekCommencing] BETWEEN [S].[StockDate] AND [S].[ToDate]
AND [PCVI].[IsTied] = 1 -- Exclude Untied
AND [P].[IsCask] = 0 -- Exclude Casks 
AND [P].[IsWater] = 0 -- Exclude Water
--AND [P].[Description] = 'Bulmers Strongbow' /* For Testing */
--ORDER BY 
--    [PCVI].[EDISID],
--    [P].[Description],
--    [PCVI].[WeekCommencing]
UNION ALL -- Consolidated Casks
SELECT
    [Consolidated].[EDISID],
    [Consolidated].[WeekCommencing],
    [Consolidated].[Product],
    --[Consolidated].[Delivered],
    --[Consolidated].[AdjustedDelivered],
    --[Consolidated].[Dispensed],
    --[Consolidated].[AdjustedDispensed],
    --[Consolidated].[Stock],
    --[Consolidated].[StockBeforeDelivery],
    --[Consolidated].[StockAfterDelivery],
    [Consolidated].[StockVariance],
    /*
    CASE WHEN [WeekCommencing] = [S].[StockDate] 
         THEN CASE WHEN [SPS].[BeforeDelivery] = 0
                   THEN [StockAfterDelivery] 
                   ELSE [StockBeforeDelivery] + [Delivered] END - [AdjustedDispensed]
          ELSE [StockVariance]
    END AS [StockVariance],
    */
    1 AS [ProductType],
    CASE WHEN @MaxData >= COALESCE([S].[VisitDate], @MaxData) AND @MaxData >= COALESCE([S].[COTDate], @MaxData)
         THEN @MaxData
         WHEN [S].[VisitDate] >= COALESCE([S].[COTDate], [S].[VisitDate])
         THEN [S].[VisitDate]
         ELSE [S].[COTDate]
         END AS [UsableStockDate]
FROM (
    SELECT
        [PCVI].[EDISID],
        [PCVI].[WeekCommencing],
        'Consolidated Casks' AS [Product],
        --[P].[Description] AS [Product],
        SUM([PCVI].[Delivered] * @ToGallons) AS [Delivered],
        SUM([PCVI].[StockAdjustedDelivered] * @ToGallons) AS [AdjustedDelivered], -- Value cannot be trusted as it is calculated incorrectly
        SUM([PCVI].[Dispensed] * @ToGallons) AS [Dispensed],
        SUM([PCVI].[StockAdjustedDispensed] * @ToGallons) AS [AdjustedDispensed],
        SUM(CASE WHEN [PCVI].[WeekCommencing] >= [S].[StockDate] -- Only use the current Stock Take
                 THEN [PCVI].[Stock] * @ToGallons
                 ELSE NULL END) AS [Stock],
        [SPS].[StockAfterDelivery],
        [SPS].[StockBeforeDelivery],
        --SUM([PCVI].[Stock] - [PCVI].[StockAdjustedDispensed]) * @ToGallons AS [StockMinusDispensed],
        --CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] 
        --         THEN CASE WHEN [StockAfterDelivery] > 0 
        --                   THEN [StockAfterDelivery] 
        --                   ELSE [StockBeforeDelivery] + SUM([PCVI].[Delivered]) END - SUM([PCVI].[StockAdjustedDispensed])
        --         ELSE NULL 
        --END * @ToGallons AS [Stock0],
        --SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] THEN (([SPS].[StockBeforeDelivery] - [PCVI].[StockAdjustedDispensed]) + [PCVI].[Delivered]) * @ToGallons ELSE NULL END) AS [Stock1],
        --SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] THEN (([SPS].[StockBeforeDelivery] - [PCVI].[StockAdjustedDispensed]) + [PCVI].[StockAdjustedDelivered]) * @ToGallons ELSE NULL END) AS [Stock1a],
        --SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] THEN ([SPS].[StockAfterDelivery] - [PCVI].[StockAdjustedDispensed]) * @ToGallons ELSE NULL END) AS [Stock2],
        --SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] THEN ([SPS].[StockAfterDelivery] - [PCVI].[Dispensed]) * @ToGallons ELSE NULL END) AS [Stock3],
        --SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] THEN (((([SPS].[StockBeforeDelivery]) + [PCVI].[Delivered]) - [PCVI].[Dispensed]) - [PCVI].[Delivered]) * @ToGallons ELSE NULL END) AS [Stock4],
        --SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] THEN (((([SPS].[StockBeforeDelivery]) + [PCVI].[StockAdjustedDelivered]) - [PCVI].[Dispensed]) - [PCVI].[StockAdjustedDelivered]) * @ToGallons ELSE NULL END) AS [Stock4a],
        --SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] THEN (([PCVI].[Stock] - [PCVI].[StockAdjustedDispensed]) + [PCVI].[Delivered]) * @ToGallons ELSE NULL END) AS [StockX],
        --SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] THEN (([PCVI].[Stock] - [PCVI].[StockAdjustedDispensed]) + [PCVI].[StockAdjustedDelivered]) * @ToGallons ELSE NULL END) AS [StockXa],
        --SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate] THEN (([PCVI].[Stock] - [PCVI].[StockAdjustedDispensed])) * @ToGallons ELSE NULL END) AS [StockY],
        SUM([PCVI].[StockAdjustedVariance] * @ToGallons) AS [StockVariance]
        /*
        SUM(CASE WHEN [PCVI].[WeekCommencing] = [S].[StockDate]
                 --THEN ((([SPS].[StockBeforeDelivery] - [PCVI].[StockAdjustedDispensed]) + [PCVI].[DeliveredAfterStock])
                 --       +
                 --      ([SPS].[StockAfterDelivery] - [PCVI].[StockAdjustedDispensed]))
                 --       * @ToGallons
                 THEN NULL
                 WHEN [PCVI].[WeekCommencing] > [S].[StockDate]
                 THEN [PCVI].[StockAdjustedVariance] * @ToGallons
                 ELSE NULL END) AS [StockVariance] --, -- TODO: Use this to get a cumulative variance
        */
        --[P].[IsCask],
        --[P].[IsMetric]
    FROM [dbo].[PeriodCacheVarianceInternal] AS [PCVI]
    JOIN #Sites AS [S] ON [PCVI].[EDISID] = [S].[EDISID]
    JOIN [dbo].[Sites] AS [Si] ON [S].[EDISID] = [Si].[EDISID]
    JOIN [dbo].[Products] AS [P] ON [PCVI].[ProductID] = [P].[ID]
    JOIN (
        SELECT
            [EDISID],
            SUM(CASE WHEN [BeforeDelivery] = 1 THEN [Stock] ELSE 0 END) AS [StockBeforeDelivery],
            SUM(CASE WHEN [BeforeDelivery] = 0 THEN [Stock] ELSE 0 END) AS [StockAfterDelivery]
        FROM #SiteProductStock AS [SPS]
        WHERE [IsCask] = 1
        GROUP BY 
            [EDISID]
        ) AS [SPS] ON [S].[EDISID] = [SPS].[EDISID]
    WHERE (@EDISID IS NULL OR [PCVI].[EDISID] = @EDISID)
    AND [Si].[Status] NOt IN (2, 10) -- Closed & Free-of-Tie
    AND [PCVI].[WeekCommencing] BETWEEN [S].[StockDate] AND [S].[ToDate]
    AND [PCVI].[IsTied] = 1 -- Exclude Untied
    AND [P].[IsCask] = 1 -- Include Casks 
    AND [P].[IsMetric] = 0 AND [P].[IsWater] = 0 -- Used to filter out corrupted data (discovered in some UAT databases)
    --AND [P].[Description] = 'Consolidated Casks' /* For Testing */
    GROUP BY
        [PCVI].[EDISID],
        [PCVI].[WeekCommencing],
        [SPS].[StockAfterDelivery],
        [SPS].[StockBeforeDelivery]--,
        --[S].[StockDate]
    --    [P].[Description]
    ) AS [Consolidated]
JOIN #Sites AS [S] ON [Consolidated].[EDISID] = [S].[EDISID]
JOIN [dbo].[Sites] AS [Si] ON [S].[EDISID] = [Si].[EDISID]
JOIN (
    SELECT
        [EDISID],
        CAST(MAX(CAST([BeforeDelivery] AS INT)) AS BIT) AS [BeforeDelivery] -- Consolidated can't mix this as dispense isn't seperate, so use it if any related product has it enabled
    FROM #SiteProductStock AS [SPS]
    WHERE [IsCask] = 1
    GROUP BY 
        [EDISID]) AS [SPS] ON [S].[EDISID] = [SPS].[EDISID]
WHERE [Si].[Status] NOT IN (2,10) -- Closed & Free-of-Tie
ORDER BY 
    [EDISID],
    [Product],
    [WeekCommencing]

OPEN Cursor_Variance

FETCH NEXT FROM Cursor_Variance INTO @CurrentEDISID, @CurrentWC, @CurrentProduct, @CurrentStockVariance, @CurrentProductType, @CurrentMinimumDate

WHILE @@FETCH_STATUS = 0
BEGIN

    IF ((@PreviousEDISID IS NULL OR @PreviousEDISID <> @CurrentEDISID) OR (@PreviousProduct IS NULL OR @PreviousProduct <> @CurrentProduct))
    BEGIN
        IF @PreviousEDISID IS NOT NULL
        BEGIN
            --SET @StoredStockCV = CASE WHEN @PreviousIsMetric = 1 THEN @PreviousStockCV * @ToLitres ELSE @PreviousStockCV * @ToGallons END

            IF ISNULL(@WorstStockCV, 0) <> 0
            BEGIN
                INSERT INTO @SiteStockVariance ([EDISID], [Product], [Stock], [ProductType])
                VALUES (@PreviousEDISID, @PreviousProduct, @WorstStockCV, @PreviousProductType)
            END
        END

        SELECT  @PreviousEDISID = NULL, 
                @PreviousWC = NULL, 
                @PreviousProduct = NULL, 
                @PreviousProductType = NULL,
                @PreviousStockVariance = 0,
                @PreviousStockCV = 0,
                @CurrentStockCV = 0,
                @WorstStockCV = 10000
    END

    SELECT
        @CurrentStockCV = @CurrentStockCV + ISNULL(@CurrentStockVariance, 0)
    
    IF @CurrentWC >= @CurrentMinimumDate -- Only consider stock values after VRS Visits/COT
    BEGIN
        SELECT 
            @WorstStockCV = CASE WHEN @WorstStockCV < @CurrentStockCV
                                    THEN @WorstStockCV
                                    ELSE @CurrentStockCV
                                    END
    END

    /* For Testing */
    IF @DebugStockCursor = 1 AND @CurrentProduct = @DebugProduct
    BEGIN
        SELECT  @CurrentEDISID AS EDISID, 
                @CurrentWC AS WC, 
                @CurrentProduct AS Product, 
                @CurrentStockVariance AS StockVariance,
                @PreviousStockVariance AS StockVariancePrev,
                @CurrentStockCV AS StockCV,
                @CurrentIsMetric AS Metric            
    END

    SELECT  @PreviousEDISID = @CurrentEDISID, 
            @PreviousWC = @CurrentWC, 
            @PreviousProduct = @CurrentProduct, 
            @PreviousStockVariance = @CurrentStockVariance,
            @PreviousStockCV = @CurrentStockCV,
            @PreviousProductType = @CurrentProductType

    FETCH NEXT FROM Cursor_Variance INTO @CurrentEDISID, @CurrentWC, @CurrentProduct, @CurrentStockVariance, @CurrentProductType, @CurrentMinimumDate
END

CLOSE Cursor_Variance
DEALLOCATE Cursor_Variance

/* As the loop will miss the final entry, save it now */
IF @PreviousEDISID IS NOT NULL
BEGIN
    --SET @StoredStockCV = CASE WHEN @PreviousIsMetric = 1 THEN @PreviousStockCV * @ToLitres ELSE @PreviousStockCV * @ToGallons END
    IF ISNULL(@WorstStockCV, 0) <> 0
    BEGIN
        INSERT INTO @SiteStockVariance ([EDISID], [Product], [Stock], [ProductType])
        VALUES (@PreviousEDISID, @PreviousProduct, @WorstStockCV, @PreviousProductType)
    END
END


-- Product Type : 1=Cask, 2=Keg, 3=Metric/Syrup
CREATE TABLE #StockTLRules([EDISID] INT NOT NULL, [Product] VARCHAR(500) NOT NULL, [NewTrafficLight] INT, [RuleDescription] VARCHAR(4000))

INSERT INTO #StockTLRules([EDISID], [Product], [NewTrafficLight], [RuleDescription])
SELECT 
    [SSV].[EDISID],
    [SSV].[Product],
    --[Stock] AS [LowestStock],
    CASE WHEN -- Apply Amber Rule
              ([ProductType] = 1 AND [Stock] <= @Amber_CaskGallons) OR ([ProductType] = 2 AND [Stock] <= @Amber_KegGallons) OR ([ProductType] = 3 AND [Stock] <= @Amber_SyrupLitres)
         THEN -- AMBER Triggered
            /* Add Service-Call/New-Product Rule */
              CASE WHEN -- Apply Service-Call/New-Product Rule (Product Cal. Request, New Product Exception)
                        ([NewProduct].[EDISID] IS NOT NULL) -- New Product Exception (latest 3 weeks)
                        AND ([SiteConditions].[EDISID] IS NOT NULL -- Calibration Request All
                                OR 
                            ([ProductConditions].[Product] IS NOT NULL AND [ProductConditions].[CalRequest] = 1)) -- Calibration Request for Product
                   THEN -- GREEN Triggered by Service-Call/New-Product Rule
                        3
                   ELSE -- CONTINUE Triggered by Service-Call/New-Product Rule
                        CASE WHEN -- Apply Red Rule
                                  ([ProductType] = 1 AND [Stock] <= @Red_CaskGallons) OR ([ProductType] = 2 AND [Stock] <= @Red_KegGallons) OR ([ProductType] = 3 AND [Stock] <= @Red_SyrupLitres)
                             THEN -- RED Triggered
                                  1 -- RED - Based on Red (Yes), Service-Call/New-Product (No) and Amber (Yes)
                             ELSE -- AMBER Remains
                                  2 -- AMBER - Based on Red (No), Service-Call/New-Product (No) and Amber (Yes)
                             END
                   END
         ELSE -- GREEN Triggered
              3 -- GREEN - Based on Amber (No)
         END AS [TrafficLight],
    CASE WHEN -- Apply Amber Rule
              ([ProductType] = 1 AND [Stock] <= @Amber_CaskGallons) OR ([ProductType] = 2 AND [Stock] <= @Amber_KegGallons) OR ([ProductType] = 3 AND [Stock] <= @Amber_SyrupLitres)
         THEN -- AMBER Triggered
            /* Add Service-Call/New-Product Rule */
              CASE WHEN -- Apply Service-Call/New-Product Rule (Product Cal. Request, New Product Exception)
                        ([NewProduct].[EDISID] IS NOT NULL) -- New Product Exception (latest 3 weeks)
                        AND ([SiteConditions].[EDISID] IS NOT NULL -- Calibration Request All
                                OR 
                            ([ProductConditions].[Product] IS NOT NULL AND [ProductConditions].[CalRequest] = 1)) -- Calibration Request for Product
                   THEN -- GREEN Triggered by Service-Call/New-Product Rule
                        ''
                   ELSE -- CONTINUE Triggered by Service-Call/New-Product Rule
                        CASE WHEN -- Apply Red Rule
                                  ([ProductType] = 1 AND [Stock] <= @Red_CaskGallons) OR ([ProductType] = 2 AND [Stock] <= @Red_KegGallons) OR ([ProductType] = 3 AND [Stock] <= @Red_SyrupLitres)
                             THEN -- RED Triggered
                                  'Product stock in Red limit' -- RED - Based on Red (Yes), Service-Call/New-Product (No) and Amber (Yes)
                             ELSE -- AMBER Remains
                                  'Product stock in Amber limit' -- AMBER - Based on Red (No), Service-Call/New-Product (No) and Amber (Yes)
                             END
                   END
         ELSE -- GREEN Triggered
              '' -- GREEN - Based on Amber (No)
         END AS [RuleTriggered]
    /*
    CASE WHEN ([ProductType] = 1 AND [Stock] <= @Red_CaskGallons) OR ([ProductType] = 2 AND [Stock] <= @Red_KegGallons) OR ([ProductType] = 3 AND [Stock] <= @Red_SyrupLitres)
         THEN 1
         WHEN ([ProductType] = 1 AND [Stock] <= @Amber_CaskGallons) OR ([ProductType] = 2 AND [Stock] <= @Amber_KegGallons) OR ([ProductType] = 3 AND [Stock] <= @Amber_SyrupLitres)
         THEN 2
         ELSE 3
         END AS [TrafficLight],
    CASE WHEN ([ProductType] = 1 AND [Stock] <= @Red_CaskGallons) OR ([ProductType] = 2 AND [Stock] <= @Red_KegGallons) OR ([ProductType] = 3 AND [Stock] <= @Red_SyrupLitres)
         THEN 'Product stock in Red limit'
         WHEN ([ProductType] = 1 AND [Stock] <= @Amber_CaskGallons) OR ([ProductType] = 2 AND [Stock] <= @Amber_KegGallons) OR ([ProductType] = 3 AND [Stock] <= @Amber_SyrupLitres)
         THEN 'Product stock in Amber limit'
         --ELSE 'Product stock in Green limit'
         END AS [RuleTriggered]
    */
FROM @SiteStockVariance AS [SSV]--Normandy
LEFT JOIN (
    SELECT
        [V].[EDISID],
        [V].[Product],
        CAST(CASE WHEN [CalProd].[Product] IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS [CalRequest]
    FROM (SELECT [EDISID], [Product] FROM #Variance GROUP BY [EDISID], [Product]) AS [V]
    LEFT JOIN @CalibrationRequestForProduct [CalProd] ON [V].[EDISID] = [CalProd].[EDISID] AND [V].[Product] = [CalProd].[Product]
    ) AS [ProductConditions] ON [SSV].[EDISID] = [ProductConditions].[EDISID] AND [SSV].[Product] = [ProductConditions].[Product]
LEFT JOIN @CalibrationRequestForAll AS [SiteConditions] ON [SSV].[EDISID] = [SiteConditions].[EDISID]
LEFT JOIN (SELECT DISTINCT [EDISID] FROM @NewProductsEx) AS [NewProduct] ON [SSV].[EDISID] = [NewProduct].[EDISID]

CREATE TABLE #SiteIssues(EDISID INT, TrafficLightNo INT, TrafficLightDescription VARCHAR(4000))

INSERT INTO #SiteIssues
SELECT StockTLRules.EDISID, MIN(NewTrafficLight) AS SuggestedTrafficLight, MIN(ProductList) AS TrafficLightReasons
FROM #StockTLRules AS StockTLRules
JOIN (
	SELECT  EDISID, SUBSTRING (
			(
			SELECT ';' + Product + '|' + RuleDescription
			FROM #StockTLRules WHERE 
				EDISID = Results.EDISID AND NewTrafficLight <> 3
			FOR XML PATH (''),TYPE).value('.','VARCHAR(4000)')
			,2,4000
		) AS ProductList
	FROM #StockTLRules Results
	GROUP BY EDISID
) AS RuleTriggerReasons ON RuleTriggerReasons.EDISID = StockTLRules.EDISID
GROUP BY StockTLRules.EDISID

--SELECT * FROM #SiteIssues


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
        CASE WHEN [Good].[OverallStatus] = 3
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
            MIN(NewTrafficLight) AS [OverallStatus]
        FROM #StockTLRules [E] 
        GROUP BY [EDISID]
        HAVING MIN(NewTrafficLight) = 3 -- Purely GREEN
    ) AS [Good] ON [S].[EDISID] = [Good].[EDISID]
    LEFT JOIN (
        SELECT DISTINCT
            [EDISID],
            SUBSTRING(
                (   SELECT ', ' + [Product]
                    FROM #StockTLRules AS [Ex]
                    WHERE [Ex].[EDISID] = [E].[EDISID]
                    AND [Ex].NewTrafficLight = 1 -- RED only
                    FOR XML PATH (''), TYPE).value('.','VARCHAR(4000)')
                ,2, 4000) AS [ProductList]
        FROM #StockTLRules AS [E]
        ) AS [Ugly] ON [S].[EDISID] = [Ugly].[EDISID]
    LEFT JOIN (
        SELECT DISTINCT
            [EDISID],
            SUBSTRING(
                (   SELECT ', ' + [Product]
                    FROM #StockTLRules AS [Ex]
                    WHERE [Ex].[EDISID] = [E].[EDISID]
                    AND [Ex].NewTrafficLight = 2 -- AMBER only
                    FOR XML PATH (''), TYPE).value('.','VARCHAR(4000)')
                ,2, 4000) AS [ProductList]
        FROM #StockTLRules AS [E]
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
                --EXEC AddOrUpdateSiteComment @CurrentEDISID, @CommentType, @CommentDate, 5000, @GreenComment, NULL, NULL, 'Green'
            END

            -- AMBER
            IF @AmberComment IS NOT NULL
            BEGIN 
                IF @DebugComments = 1
                BEGIN
                    PRINT CAST(@CurrentEDISID AS VARCHAR) + ' - AMBER (' + @AmberComment + ')'
                END
                
                SET @FinalHeading = 5002
                SET @FinalRAG = 'Amber'
                SET @FinalComment = @AmberComment
                --EXEC AddOrUpdateSiteComment @CurrentEDISID, @CommentType, @CommentDate, 5002, @AmberComment, NULL, NULL, 'Amber'
            END

            -- RED
            IF @RedComment IS NOT NULL 
            BEGIN
                IF @DebugComments = 1
                BEGIN
                    PRINT CAST(@CurrentEDISID AS VARCHAR) + ' - RED (' + @RedComment + ')'
                END
                
                SET @FinalHeading = 5003 -- Will override AMBER
                SET @FinalRAG = 'Red'
                SET @FinalComment = @RedComment + (CASE WHEN @AmberComment IS NOT NULL THEN CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10)+@AmberComment ELSE '' END)

                IF @DebugComments = 1
                BEGIN
                    PRINT CAST(@CurrentEDISID AS VARCHAR) + ' - RED+AMBER (' + @FinalComment + ')'
                END
                --EXEC AddOrUpdateSiteComment @CurrentEDISID, @CommentType, @CommentDate, 5003, @RedComment, NULL, NULL, 'Red'
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
    LEFT JOIN #SiteIssues AS [SI] ON [S].[EDISID] = [SI].[EDISID]

    OPEN Cursor_Ranking

    FETCH NEXT FROM Cursor_Ranking INTO @CurrentRankingEDISID, @CurrentRankingTL

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @DebugRankings = 1
        BEGIN
            PRINT 'EXEC [neo].[AssignSiteRanking] ' + CAST(@CurrentRankingEDISID AS VARCHAR(10)) + ', ' + CAST(@CurrentRankingTL AS VARCHAR(10)) + ', '''',''' + CAST(@EndDate AS VARCHAR(16)) + ''', ' + CAST(@RankingCategory AS VARCHAR(10))
        END

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


SELECT	si.EDISID,
	(CASE
		WHEN si.TrafficLightNo = 1 THEN 'Red'
		WHEN si.TrafficLightNo = 2 THEN 'Amber'
		WHEN si.TrafficLightNo = 3 THEN 'Green'
		WHEN si.TrafficLightNo = 6 THEN 'Grey'
	END) + ' - ' + ISNULL(si.TrafficLightDescription,'No Issue')  AS [Detail]
FROM	#SiteIssues si
UNION ALL
SELECT 
    [S].[EDISID],
    'Green - ' + @CommentTemplateGood AS [Detail]
    --'Green - No Tied Products' AS [Detail]
FROM #Sites AS [S]
JOIN [dbo].[Sites] AS [Si] ON [S].[EDISID] = [Si].[EDISID]
LEFT JOIN #SiteIssues AS [Ex] ON [S].[EDISID] = [Ex].[EDISID]
WHERE [Ex].[EDISID] IS NULL
AND [Si].[Status] NOT IN (2,10)
UNION ALL
SELECT 
    [S].[EDISID],
    CASE WHEN [Si].[Status] = 2 -- Closed
         THEN 'Grey - N/A' 
         WHEN [Si].[Status] = 10 -- Free-of-Tie
         THEN 'Green - ' + @CommentTemplateGood 
         END AS [Detail]
FROM #Sites AS [S]
JOIN [dbo].[Sites] AS [Si] ON [S].[EDISID] = [Si].[EDISID]
LEFT JOIN #SiteIssues [Ex] ON [S].[EDISID] = [Ex].[EDISID]
WHERE [Ex].[EDISID] IS NULL
AND [Si].[Status] IN (2,10)

/* For Testing */
IF @DebugVariance = 1
BEGIN
    SELECT *
    FROM @SiteStockVariance
END

DROP TABLE #SiteProductStock
DROP TABLE #StockTLRules
DROP TABLE #SiteIssues
DROP TABLE #Variance
DROP TABLE #Sites

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ExceptionTrafficLightStock] TO PUBLIC
    AS [dbo];

