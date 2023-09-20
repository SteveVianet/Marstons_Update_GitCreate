CREATE PROCEDURE [dbo].[ExceptionNewProductKegSyrup]
(
	@EDISID INT = NULL,
	@Auditor VARCHAR(255) = NULL
)
AS

/* For Testing */
--DECLARE @EDISID INT = NULL
--DECLARE @Auditor VARCHAR(50) = NULL
--DECLARE @SiteID VARCHAR(15) = NULL --'031622'
--IF @SiteID IS NOT NULL
--    SELECT @EDISID = [EDISID] FROM [dbo].[Sites] WHERE [SiteID] = @SiteID

SET DATEFIRST 1;
SET NOCOUNT ON;

DECLARE @EnableLogging BIT = 1
DECLARE @DebugDates BIT = 0
DECLARE @DebugDeliveries BIT = 0
DECLARE @DebugNewProduct BIT = 0
DECLARE @DebugCalRequest BIT = 0

/* Debugging */
--SET @EnableLogging = 0
--SET @DebugDates = 1
--SET @DebugDeliveries = 1
--SET @DebugNewProduct = 1
--SET @DebugCalRequest = 1

DECLARE @CurrentWeekFrom		DATETIME
DECLARE @To						DATETIME
DECLARE @Today					DATETIME

DECLARE @AuditWeeksBack INT = 1
SELECT @AuditWeeksBack = ISNULL(CAST([PropertyValue] AS INTEGER), 1) FROM [dbo].[Configuration] WHERE [PropertyName] = 'AuditWeeksBehind'

--Get Audit Day for customer, the day in which the audit period will be classed as an extra week forward
DECLARE @AuditDay INT
SELECT @AuditDay = ISNULL(CAST([PropertyValue] AS INTEGER), NULL) FROM [dbo].[Configuration] WHERE [PropertyName] = 'AuditDay'

IF @AuditDay IS NOT NULL
BEGIN
	--Get Current Day
	DECLARE @CurrentDay INT
	SET @CurrentDay = DATEPART(dw,GETDATE())

	IF @CurrentDay >= @AuditDay
		BEGIN
			SET @CurrentWeekFrom = DATEADD(WEEK, -(@AuditWeeksBack-2), DATEADD(WEEK, DATEDIFF(WEEK, 6, GETDATE()), 0)) --take back 1 and a half weeks
		END
	ELSE
		BEGIN 
			SET @CurrentWeekFrom = DATEADD(WEEK, -(@AuditWeeksBack-1), DATEADD(WEEK, DATEDIFF(WEEK, 6, GETDATE()), 0)) -- take back 2 weeks
		END
END

IF @AuditDay IS NULL
	BEGIN 
		SET @CurrentWeekFrom = DATEADD(WEEK, -(@AuditWeeksBack-1), DATEADD(WEEK, DATEDIFF(WEEK, 6, GETDATE()), 0))
	END

--DEBUG
--SET @CurrentWeekFrom = DATEADD(WEEK, -6, @CurrentWeekFrom)

SET @To = DATEADD(day, 6, @CurrentWeekFrom)

IF @DebugDates = 1
BEGIN
    SELECT @CurrentWeekFrom AS [From], @To [To]
END

IF @EnableLogging = 1 
BEGIN
    DECLARE @DatabaseID INT
    SELECT @DatabaseID = [ID] FROM [SQL1\SQL1].[ServiceLogger].[dbo].[EDISDatabases] WHERE [Name] = DB_NAME()
    DECLARE @NotificationTypeID INT
    SELECT @NotificationTypeID = [NotificationTypeID] FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationType] WHERE [StoredProcedure] = OBJECT_NAME(@@PROCID)
    IF @NotificationTypeID IS NOT NULL
    BEGIN
        EXEC [SQL1\SQL1].[Auditing].[dbo].[AddNotificationTypeGenerationLog] @NotificationTypeID, @DatabaseID, @EDISID, @CurrentWeekFrom, @To
    END
END
ELSE
BEGIN
    PRINT 'Logging Disabled'
END

DECLARE @PreviousWeeks INT

SELECT @PreviousWeeks = CAST([ParameterValue] AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'NewProductKegSyrup-PriorWeeks'


CREATE TABLE #Sites(EDISID INT, Hidden BIT, LastDownload datetime, SystemTypeID int)

INSERT INTO #Sites
(EDISID, Hidden, LastDownload, SystemTypeID)
SELECT Sites.EDISID, Hidden, LastDownload, SystemTypeID
FROM Sites
WHERE Hidden = 0
AND (@EDISID IS NULL OR Sites.EDISID = @EDISID)
AND(@Auditor IS NULL OR LOWER(SiteUser) = LOWER(@Auditor))
AND SiteOnline <= @To
AND [Status] IN (1,10,3)

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

/* Outstanding New Flowmeter Request */
DECLARE @NewFlowmeterID INT = 21 -- New Flowmeter Required
DECLARE @NewFlowmeterBrandID INT = 59 -- New Flowmeter Required (Brand Driven)
DECLARE @NewSyrupMeter INT = 64 -- New Syrup Meter Required

/*
-- LEGACY LOGGER
DECLARE @InfoDelimiter CHAR(1) = '|'
DECLARE @NewFlowmeterRequestForProduct TABLE ([EDISID] INT NOT NULL, [Product] VARCHAR (50) NOT NULL)

INSERT INTO @NewFlowmeterRequestForProduct ([EDISID], [Product])
SELECT 
    --[C].[ID] AS [CallID],
    [C].[EDISID],
    --[CR].[AdditionalInfo],
    CASE 
        WHEN
            (CHARINDEX(@InfoDelimiter, [CR].[AdditionalInfo], 0) + 1) <> 1 -- After the Start of the string
        THEN
            SUBSTRING([CR].[AdditionalInfo], 0, CHARINDEX(@InfoDelimiter, [CR].[AdditionalInfo], 0))
        ELSE
            NULL
    END AS [Product]
FROM [dbo].[Calls] AS [C]
JOIN #Sites AS [S] ON [C].[EDISID] = [S].[EDISID]
JOIN [dbo].[CallReasons] AS [CR]
    ON [C].[ID] = [CR].[CallID]
WHERE [ClosedOn] IS NULL -- Only Open/Outstanding Calls
AND [AbortReasonID] = 0 -- Not Aborted
AND [CR].[ReasonTypeID] IN (@NewFlowmeterID,@NewFlowmeterBrandID,@NewSyrupMeter)
AND (CHARINDEX(@InfoDelimiter, [CR].[AdditionalInfo], 0) + 1) <> 1
*/

-- JOB WATCH
DECLARE @NewFlowmeterRequestForProduct TABLE ([EDISID] INT NOT NULL, [Product] VARCHAR (50) NOT NULL)
INSERT INTO @NewFlowmeterRequestForProduct ([EDISID], [Product])
SELECT
    [JobWatchCalls].[EdisID],
    [Products].[Description]
FROM [dbo].[JobWatchCalls]
JOIN [dbo].[JobWatchCallsData] ON [JobWatchCalls].[JobId] = [JobWatchCallsData].[JobId]
JOIN [dbo].[Products] ON [JobWatchCallsData].[ProductID] = [Products].[ID]
WHERE [JobWatchCalls].[JobActive] = 1
AND [JobWatchCallsData].[ProductID] IS NOT NULL
AND [JobWatchCallsData].[CallReasonTypeID] IN (@NewFlowmeterID,@NewFlowmeterBrandID,@NewSyrupMeter)

IF @DebugNewProduct = 1
BEGIN
    SELECT [EDISID], [Product] AS [New Product Requested]
    FROM @NewFlowmeterRequestForProduct
END
/* Outstanding Calibration Request */

/* **************************************************************************************************************************************************
    Calibration Requests

    Retrieve the details of any active Service Calls with Calibration Requests
*/
--DECLARE @CalRequestID INT = 33 -- Calibration request (Audit raised following data query)
DECLARE @CalRequestAllID INT = 63 -- Calibration request (Audit raised following data query)

/*
-- LEGACY LOGGER
DECLARE @ProductStart CHAR = ':'
DECLARE @ProductEnd CHAR = '('

DECLARE @CalibrationRequestForAll TABLE ([EDISID] INT NOT NULL)
--DECLARE @CalibrationRequestForProduct TABLE ([EDISID] INT NOT NULL, [Product] VARCHAR (50) NOT NULL)

/* All Lines */
INSERT INTO @CalibrationRequestForAll ([EDISID])
SELECT 
    --[C].[ID] AS [CallID],
    [C].[EDISID]
FROM [dbo].[Calls] AS [C]
JOIN #Sites AS [S] ON [C].[EDISID] = [S].[EDISID]
JOIN [dbo].[CallReasons] AS [CR]
    ON [C].[ID] = [CR].[CallID]
JOIN (
    SELECT
        [CallStatusHistory].[CallID],
        [CallStatusHistory].[StatusID]
    FROM [dbo].[CallStatusHistory]
    JOIN (
        SELECT
            [CallID],
            MAX([ChangedOn]) AS [LatestChange]
        FROM [dbo].[CallStatusHistory]
        GROUP BY [CallID]
        ) AS [LatestStatus] 
        ON [CallStatusHistory].[CallID] = [LatestStatus].[CallID]
        AND [CallStatusHistory].[ChangedOn] = [LatestStatus].[LatestChange]
    WHERE [CallStatusHistory].[StatusID] NOT IN (4, 5) -- Closed, Closed & Invoiced
    ) AS [CurrentStatus] 
    ON [C].[ID] = [CurrentStatus].[CallID]
WHERE [ClosedOn] IS NULL -- Only Open/Outstanding Calls
--AND [RaisedOn] >= DATEADD(WEEK, -2, @CurrentWeekFrom)
AND [AbortReasonID] = 0 -- Not Aborted
AND [CR].[ReasonTypeID] IN (@CalRequestAllID, @CalRequestID)
*/

/* Specific Lines */
/*
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
AND [RaisedOn] >= DATEADD(WEEK, -2, GETDATE())
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

IF @DebugCalRequest = 1
BEGIN
    SELECT [EDISID] AS [Cal. Request on Site] FROM @CalibrationRequestForAll ORDER BY [EDISID]
    --SELECT [EDISID], [Product] AS [Cal. Request on Product] FROM @CalibrationRequestForProduct ORDER BY [EDISID]
END

/*
    Calibration Requests
    **************************************************************************************************************************************************
*/


IF @DebugDeliveries = 1
BEGIN
    /*
    SELECT 
        @CurrentWeekFrom [From],
        @To [To],
        DATEADD(WEEK, -2, @CurrentWeekFrom) [PrevFrom],
        DATEADD(DAY, -1, @CurrentWeekFrom) [PrevTo]
    */

    SELECT
        [DeliveryProducts].[EDISID],
        [P].[Description] AS [ProductName],
        [DeliveryProducts].[DeliveryProductID],
        *
    FROM (
        SELECT DISTINCT
            [S].[EDISID],
            ISNULL([PP].[PrimaryProductID], [D].[Product]) AS [DeliveryProductID]
        FROM #Sites AS [S] 
        JOIN [dbo].[MasterDates] AS [MD] ON [S].[EDISID] = [MD].[EDISID]
        JOIN [dbo].[Delivery] AS [D] ON [MD].[ID] = [D].[DeliveryID]
        LEFT JOIN #PrimaryProducts AS [PP] ON [PP].[ProductID] = [D].[Product]
        WHERE [MD].[Date] BETWEEN @CurrentWeekFrom AND @To
        ) AS [DeliveryProducts]
    LEFT JOIN 
        (
        SELECT DISTINCT
            [S].[EDISID],
            ISNULL([PP].[PrimaryProductID], [PS].[ProductID]) AS [PumpProductID]
        FROM #Sites AS [S] 
        JOIN [dbo].[PumpSetup] AS [PS] ON [S].[EDISID] = [PS].[EDISID]
        LEFT JOIN #PrimaryProducts AS [PP] ON [PP].[ProductID] = [PS].[ProductID]
        WHERE 
            [PS].[ValidTo] IS NULL    
        ) AS [PumpProducts]
          ON [PumpProducts].[EDISID] = [DeliveryProducts].[EDISID]
         AND [PumpProducts].[PumpProductID] = [DeliveryProducts].[DeliveryProductID]
    LEFT JOIN [dbo].[Products] AS [P] 
        ON [DeliveryProducts].[DeliveryProductID] = [P].[ID]
    LEFT JOIN [dbo].[SiteProductTies] AS [SPT] 
        ON [P].[ID] = [SPT].[ProductID] AND [DeliveryProducts].[EDISID] = [SPT].[EDISID]
    LEFT JOIN [dbo].[SiteProductCategoryTies] AS [SPCT] 
        ON [P].[CategoryID] = [SPCT].[ProductCategoryID] AND [DeliveryProducts].[EDISID] = [SPCT].[EDISID]
    WHERE 
        [PumpProducts].[PumpProductID] IS NULL -- We only care if it's not on the current Font Setup
    AND [P].[IsCask] = 0  -- No Casks
    AND [P].[IsWater] = 0 -- No Water
                          -- Only Kegs/Syrup
    AND	COALESCE([SPT].[Tied], [SPCT].[Tied], [P].[Tied]) = 1 -- Only Tied
    ORDER BY [DeliveryProducts].[EDISID]

    SELECT
        [DeliveryProducts].[EDISID],
        [P].[Description] AS [ProductName],
        [DeliveryProducts].[DeliveryProductID],
        *
    FROM (
        SELECT DISTINCT
            [S].[EDISID],
            ISNULL([PP].[PrimaryProductID], [D].[Product]) AS [DeliveryProductID]
        FROM #Sites AS [S] 
        JOIN [dbo].[MasterDates] AS [MD] ON [S].[EDISID] = [MD].[EDISID]
        JOIN [dbo].[Delivery] AS [D] ON [MD].[ID] = [D].[DeliveryID]
        LEFT JOIN #PrimaryProducts AS [PP] ON [PP].[ProductID] = [D].[Product]
        WHERE [MD].[Date] BETWEEN DATEADD(WEEK, -@PreviousWeeks, @CurrentWeekFrom) AND DATEADD(DAY, -1, @CurrentWeekFrom)
        ) AS [DeliveryProducts]
    LEFT JOIN 
        (
        SELECT DISTINCT
            [S].[EDISID],
            ISNULL([PP].[PrimaryProductID], [PS].[ProductID]) AS [PumpProductID]
        FROM #Sites AS [S] 
        JOIN [dbo].[PumpSetup] AS [PS] ON [S].[EDISID] = [PS].[EDISID]
        LEFT JOIN #PrimaryProducts AS [PP] ON [PP].[ProductID] = [PS].[ProductID]
        WHERE 
            [PS].[ValidTo] IS NULL    
        ) AS [PumpProducts]
          ON [PumpProducts].[EDISID] = [DeliveryProducts].[EDISID]
         AND [PumpProducts].[PumpProductID] = [DeliveryProducts].[DeliveryProductID]
    LEFT JOIN [dbo].[Products] AS [P] 
        ON [DeliveryProducts].[DeliveryProductID] = [P].[ID]
    LEFT JOIN [dbo].[SiteProductTies] AS [SPT] 
        ON [P].[ID] = [SPT].[ProductID] AND [DeliveryProducts].[EDISID] = [SPT].[EDISID]
    LEFT JOIN [dbo].[SiteProductCategoryTies] AS [SPCT] 
        ON [P].[CategoryID] = [SPCT].[ProductCategoryID] AND [DeliveryProducts].[EDISID] = [SPCT].[EDISID]
    WHERE 
        [PumpProducts].[PumpProductID] IS NULL -- We only care if it's not on the current Font Setup
    AND [P].[IsCask] = 0  -- No Casks
    AND [P].[IsWater] = 0 -- No Water
                          -- Only Kegs/Syrup
    AND	COALESCE([SPT].[Tied], [SPCT].[Tied], [P].[Tied]) = 1 -- Only Tied
    ORDER BY [DeliveryProducts].[EDISID]
END

DECLARE @SitesNewProductKegReasons TABLE
(
	[EDISID] INT NOT NULL,
	[Product] VARCHAR(255) NOT NULL,
	[ProductID] INT NOT NULL
)

INSERT INTO @SitesNewProductKegReasons ([EDISID], [Product], [ProductID])
SELECT
    [DeliveryProductsLatestWeek].[EDISID],
    [P].[Description] AS [ProductName],
    [DeliveryProductsLatestWeek].[DeliveryProductID]
FROM (
    SELECT DISTINCT
        [S].[EDISID],
        ISNULL([PP].[PrimaryProductID], [D].[Product]) AS [DeliveryProductID]
    FROM #Sites AS [S] 
    JOIN [dbo].[MasterDates] AS [MD] ON [S].[EDISID] = [MD].[EDISID]
    JOIN [dbo].[Delivery] AS [D] ON [MD].[ID] = [D].[DeliveryID]
    LEFT JOIN #PrimaryProducts AS [PP] ON [PP].[ProductID] = [D].[Product]
    WHERE [MD].[Date] BETWEEN @CurrentWeekFrom AND @To
    ) AS [DeliveryProductsLatestWeek]
LEFT JOIN (
    SELECT DISTINCT
        [S].[EDISID],
        ISNULL([PP].[PrimaryProductID], [D].[Product]) AS [DeliveryProductID]
    FROM #Sites AS [S] 
    JOIN [dbo].[MasterDates] AS [MD] ON [S].[EDISID] = [MD].[EDISID]
    JOIN [dbo].[Delivery] AS [D] ON [MD].[ID] = [D].[DeliveryID]
    LEFT JOIN #PrimaryProducts AS [PP] ON [PP].[ProductID] = [D].[Product]
    WHERE [MD].[Date] BETWEEN DATEADD(WEEK, -@PreviousWeeks, @CurrentWeekFrom) AND DATEADD(DAY, -1, @CurrentWeekFrom)
) AS [DeliveryProductsPriorWeeks]
  ON [DeliveryProductsLatestWeek].[EDISID] = [DeliveryProductsPriorWeeks].[EDISID]
  AND [DeliveryProductsLatestWeek].[DeliveryProductID] = [DeliveryProductsPriorWeeks].[DeliveryProductID]
LEFT JOIN 
    (
    SELECT DISTINCT
        [S].[EDISID],
        ISNULL([PP].[PrimaryProductID], [PS].[ProductID]) AS [PumpProductID]
    FROM #Sites AS [S] 
    JOIN [dbo].[PumpSetup] AS [PS] ON [S].[EDISID] = [PS].[EDISID]
    LEFT JOIN #PrimaryProducts AS [PP] ON [PP].[ProductID] = [PS].[ProductID]
    WHERE 
        [PS].[ValidTo] IS NULL    
    ) AS [PumpProducts]
      ON [PumpProducts].[EDISID] = [DeliveryProductsLatestWeek].[EDISID]
     AND [PumpProducts].[PumpProductID] = [DeliveryProductsLatestWeek].[DeliveryProductID]
LEFT JOIN [dbo].[Products] AS [P] 
    ON [DeliveryProductsLatestWeek].[DeliveryProductID] = [P].[ID]
LEFT JOIN [dbo].[SiteProductTies] AS [SPT] 
    ON [P].[ID] = [SPT].[ProductID] AND [DeliveryProductsLatestWeek].[EDISID] = [SPT].[EDISID]
LEFT JOIN [dbo].[SiteProductCategoryTies] AS [SPCT] 
    ON [P].[CategoryID] = [SPCT].[ProductCategoryID] AND [DeliveryProductsLatestWeek].[EDISID] = [SPCT].[EDISID]
LEFT JOIN @NewFlowmeterRequestForProduct AS [NFRFP] 
    ON [P].[Description] = [NFRFP].[Product] AND [DeliveryProductsLatestWeek].[EDISID] = [NFRFP].[EDISID]
LEFT JOIN @CalibrationRequestForAll AS [CRFA]
    ON [DeliveryProductsLatestWeek].[EDISID] = [CRFA].[EDISID]
--LEFT JOIN @CalibrationRequestForProduct AS [CRFP]
--    ON [P].[Description] = [CRFP].[Product] AND [DeliveryProductsLatestWeek].[EDISID] = [CRFP].[EDISID]
WHERE 
    [PumpProducts].[PumpProductID] IS NULL -- We only care if it's not on the current Font Setup
AND [NFRFP].[Product] IS NULL -- We only care if no New Product Requests have been raised
AND (
      (
        ([CRFA].[EDISID] IS NULL) -- Exclude Sites with Calibration Requested for all Products
        OR
        ([CRFA].[EDISID] IS NOT NULL AND [DeliveryProductsPriorWeeks].[DeliveryProductID] IS NULL) -- Ignore Cal. Req. if includes a Delivery in the 2 weeks prior to current
      )
      --AND
      --(
      --  ([CRFP].[Product] IS NULL) -- We only care for Products which don't have a Calibration Requested
      --  OR
      --  ([CRFP].[Product] IS NOT NULL AND [DeliveryProductsPriorWeeks].[DeliveryProductID] IS NULL) -- Ignore Cal. Req. if includes a Delivery in the 2 weeks prior to current
      --)
    )
AND [P].[IsCask] = 0  -- No Casks
AND [P].[IsWater] = 0 -- No Water
                      -- Only Kegs/Syrup
AND	COALESCE([SPT].[Tied], [SPCT].[Tied], [P].[Tied]) = 1 -- Only Tied

SELECT  
    [Results].[EDISID], 
    SUBSTRING ((
		SELECT ';' + Product
		FROM @SitesNewProductKegReasons WHERE 
			EDISID = Results.EDISID
		FOR XML PATH (''),TYPE).value('.','VARCHAR(4000)')
		,2,4000
	) AS ProductList, 
    ProductID, 
    NULL AS [Pump]
    /* Debugging */
    --,[Sites].[SiteID]
FROM @SitesNewProductKegReasons AS [Results]
/* Debugging */
--JOIN [dbo].[Sites] ON [Results].[EDISID] = [Sites].[EDISID]


DROP TABLE #PrimaryProducts
DROP TABLE #Sites

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ExceptionNewProductKegSyrup] TO PUBLIC
    AS [dbo];

