CREATE PROCEDURE [dbo].[ExceptionPositiveVariance]
(
    @EDISID     INT = NULL,
    @Auditor    VARCHAR(255) = NULL
)
AS

/* For Testing */
--DECLARE @EDISID INT = 2173
--DECLARE @Auditor VARCHAR(50) = NULL
--DECLARE @SiteID VARCHAR(15) = NULL --'101375'
--IF @SiteID IS NOT NULL
--    SELECT @EDISID = [EDISID] FROM [dbo].[Sites] WHERE [SiteID] = @SiteID

SET DATEFIRST 1;
SET NOCOUNT ON;

/* Debugging */
DECLARE @EnableLogging BIT = 1
DECLARE @UseInternalCache BIT = 1
DECLARE @DebugDates BIT = 0
DECLARE @DebugParameters BIT = 0
DECLARE @DebugVariance BIT = 0
DECLARE @DebugRawVariance BIT = 0
DECLARE @DebugValidProducts BIT = 0
DECLARE @DebugSiteID BIT = 0

/* Debugging */
--SET @EnableLogging = 0
--SET @UseInternalCache = 0
--SET @DebugDates = 1
--SET @DebugParameters = 1
--SET @DebugVariance = 1
--SET @DebugRawVariance = 1
--SET @DebugValidProducts = 1
--SET @DebugSiteID = 1

--DECLARE @CurrentWeekFrom    DATE = GETDATE()
--SET @CurrentWeekFrom = DATEADD(dd, 1-DATEPART(dw, @CurrentWeekFrom), @CurrentWeekFrom)

IF @DebugSiteID = 1 AND @EDISID IS NOT NULL
    SELECT [SiteID] FROM [dbo].[Sites] WHERE [EDISID] = @EDISID

DECLARE @CurrentWeekFrom       DATE
DECLARE @To                     DATE
DECLARE @Today                  DATE

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

--SET @CurrentWeekFrom = DATEADD(WEEK, -(@AuditWeeksBack-1), DATEADD(WEEK, DATEDIFF(WEEK, 6, GETDATE()), 0))
SET @To = DATEADD(DAY, 6, @CurrentWeekFrom)

DECLARE @ReportingWeekFrom DATE = DATEADD(WEEK, -11, @CurrentWeekFrom)

IF @DebugDates = 1
    SELECT @ReportingWeekFrom AS [From W/C], @CurrentWeekFrom [To W/C]

CREATE TABLE #Sites(EDISID INT, [Hidden] BIT, SiteOnline DATETIME)

INSERT INTO #Sites
(EDISID, Hidden, SiteOnline)
SELECT 
    --TOP 200 -- Debugging
    Sites.EDISID, Hidden, SiteOnline
FROM Sites
WHERE [Hidden] = 0
AND (@EDISID IS NULL OR Sites.EDISID = @EDISID)
AND(@Auditor IS NULL OR LOWER(SiteUser) = LOWER(@Auditor))
AND SiteOnline <= @To
AND SiteOnline < DATEADD(WEEK, -4, @CurrentWeekFrom)

IF @EnableLogging = 1 
BEGIN
    DECLARE @DatabaseID INT
    SELECT @DatabaseID = [ID] FROM [SQL1\SQL1].[ServiceLogger].[dbo].[EDISDatabases] WHERE [Name] = DB_NAME()
    DECLARE @NotificationTypeID INT
    SELECT @NotificationTypeID = [NotificationTypeID] FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationType] WHERE [StoredProcedure] = OBJECT_NAME(@@PROCID)
    IF @NotificationTypeID IS NOT NULL
    BEGIN
        EXEC [SQL1\SQL1].[Auditing].[dbo].[AddNotificationTypeGenerationLog] @NotificationTypeID, @DatabaseID, @EDISID, @ReportingWeekFrom, @To
    END
END
ELSE
BEGIN
    PRINT 'Logging Disabled'
END

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

CREATE TABLE #Variance 
(
    [Date] DATETIME NOT NULL,
    [Dispensed] FLOAT NOT NULL,
    [Delivered] FLOAT NOT NULL,
    [Variance] FLOAT NOT NULL,
    [EDISID] INT NOT NULL,
    [ProductID] INT NOT NULL
    PRIMARY KEY ([EDISID], [ProductID], [Date])
)

CREATE TABLE #Root
(
    [EDISID] INT NOT NULL,
    [ProductID] INT NOT NULL,
    [FirstDateOfWeek] DATE NOT NULL
)

IF @UseInternalCache = 1
BEGIN
    INSERT INTO #Root ([EDISID], [ProductID], [FirstDateOfWeek])
    SELECT DISTINCT
        [EDISID],
        [Product],
        [FirstDateOfWeek]
    FROM (
        SELECT DISTINCT
            [Sites].[EDISID],
            [PCVI].[ProductID] AS [Product]
        FROM [dbo].[PeriodCacheVarianceInternal] AS [PCVI]
        JOIN #Sites AS [Sites] ON [PCVI].[EDISID] = [Sites].[EDISID]
        WHERE [PCVI].[WeekCommencing] BETWEEN @ReportingWeekFrom AND @To
        ) AS [SiteProducts]
    CROSS APPLY (
        SELECT DISTINCT
            FirstDateOfWeek
        FROM Calendar 
        WHERE CalendarDate BETWEEN @ReportingWeekFrom AND @CurrentWeekFrom
        ) AS [Weeks]
END
ELSE
BEGIN
    INSERT INTO #Root ([EDISID], [ProductID], [FirstDateOfWeek])
    SELECT DISTINCT
        [EDISID],
        [Product],
        [FirstDateOfWeek]
    FROM (
        SELECT DISTINCT 
            [Sites].[EDISID],
            [Product]
        FROM Delivery
        JOIN MasterDates ON Delivery.DeliveryID = MasterDates.ID
        JOIN #Sites AS Sites ON MasterDates.EDISID = Sites.EDISID
        WHERE MasterDates.[Date] BETWEEN @ReportingWeekFrom AND @To
        UNION
        SELECT DISTINCT 
            [Sites].[EDISID],
            [Product]
        FROM DLData
        JOIN MasterDates ON DLData.DownloadID = MasterDates.ID
        JOIN #Sites AS Sites ON MasterDates.EDISID = Sites.EDISID
        WHERE MasterDates.[Date] BETWEEN @ReportingWeekFrom AND @To
        ) AS [Products]
    CROSS APPLY (
        SELECT DISTINCT
            FirstDateOfWeek
        FROM Calendar 
        WHERE CalendarDate BETWEEN @ReportingWeekFrom AND @CurrentWeekFrom
        ) AS [Weeks]
END

IF @UseInternalCache = 1
BEGIN
    INSERT INTO #Variance
    (
        [Date],
        [Dispensed],
        [Delivered],
        [Variance],
        [EDISID],
        [ProductID]
    )
    SELECT 
        [Weeks].[FirstDateOfWeek],
        CASE WHEN [PCVI].[Dispensed] IS NULL THEN 0 ELSE [PCVI].[Dispensed] / 8 END,
        CASE WHEN [PCVI].[Delivered] IS NULL THEN 0 ELSE [PCVI].[Delivered] / 8 END,
        CASE WHEN [PCVI].[Variance] IS NULL THEN 0 ELSE [PCVI].[Variance] / 8 END,
        [Weeks].[EDISID],
        ISNULL([PP].[PrimaryProductID], [Weeks].[ProductID]) AS [ProductID]
    FROM #Root AS [Weeks]
    LEFT JOIN [dbo].[PeriodCacheVarianceInternal] AS [PCVI] 
        ON  [Weeks].[ProductID] = [PCVI].[ProductID]
        AND [Weeks].[FirstDateOfWeek] = [PCVI].[WeekCommencing]
        AND [Weeks].[EDISID] = [PCVI].[EDISID]
    FULL OUTER JOIN #PrimaryProducts AS [PP] ON [PP].[ProductID] = [Weeks].[ProductID]
    WHERE [Weeks].[FirstDateOfWeek] IS NOT NULL
END
ELSE
BEGIN
    ;WITH Delivered
    AS
    (
        SELECT 
            ISNULL(SUM(Quantity), 0) AS [Delivered],
            [Weeks].[FirstDateOfWeek],
            [Weeks].[EDISID],
            ISNULL([PP].[PrimaryProductID], [Weeks].[ProductID]) AS [ProductID]
            --[Weeks].[ProductID]
        FROM #Root AS [Weeks]
        JOIN #Sites AS [Sites] ON [Weeks].[EDISID] = Sites.EDISID
        LEFT JOIN dbo.MasterDates 
            ON [Weeks].EDISID = MasterDates.EDISID 
            AND [Weeks].FirstDateOfWeek = (DATEADD(DAY, 1-DATEPART(WEEKDAY, MasterDates.[Date]), MasterDates.[Date]))
            AND Sites.SiteOnline <= MasterDates.[Date]
            AND MasterDates.[Date] BETWEEN @ReportingWeekFrom AND @To
        LEFT JOIN dbo.Delivery 
            ON MasterDates.ID = Delivery.DeliveryID
            AND [Weeks].[ProductID] = Delivery.Product
        FULL OUTER JOIN #PrimaryProducts AS [PP] ON [PP].[ProductID] = [Weeks].[ProductID]
        GROUP BY 
            [Weeks].[FirstDateOfWeek], 
            [Weeks].[EDISID], 
            ISNULL([PP].[PrimaryProductID], [Weeks].[ProductID])
        --ORDER BY [Weeks].[EDISID], [Weeks].[ProductID], [Weeks].[FirstDateOfWeek]
    ),
    Dispensed
    AS
    (
        SELECT 
            ISNULL(SUM(Quantity)/8, 0) AS [Dispensed], -- 0 indicates missing weeks of (dispense) data
            [Weeks].[FirstDateOfWeek],
            [Weeks].[EDISID],
            ISNULL([PP].[PrimaryProductID], [Weeks].[ProductID]) AS [ProductID]
            --[Weeks].[ProductID]
        FROM #Root AS [Weeks]
        JOIN #Sites AS [Sites] ON [Weeks].[EDISID] = Sites.EDISID
        LEFT JOIN dbo.MasterDates 
            ON [Weeks].EDISID = MasterDates.EDISID 
            AND [Weeks].FirstDateOfWeek = (DATEADD(DAY, 1-DATEPART(WEEKDAY, MasterDates.[Date]), MasterDates.[Date]))
            AND Sites.SiteOnline <= MasterDates.[Date]
            AND MasterDates.[Date] BETWEEN @ReportingWeekFrom AND @To
        LEFT JOIN dbo.DLData 
            ON MasterDates.ID = DLData.DownloadID
            AND [Weeks].[ProductID] = DLData.Product
        FULL OUTER JOIN #PrimaryProducts AS [PP] ON [PP].[ProductID] = [Weeks].[ProductID]
        GROUP BY 
            [Weeks].[FirstDateOfWeek], 
            [Weeks].[EDISID], 
            ISNULL([PP].[PrimaryProductID], [Weeks].[ProductID])
        --ORDER BY [Weeks].[EDISID], [Weeks].[ProductID], [Weeks].[FirstDateOfWeek]
    )
    INSERT INTO #Variance
    (
        [Date],
        [Dispensed],
        [Delivered],
        [Variance],
        [EDISID],
        [ProductID]
    )
    SELECT  
        [Root].[FirstDateOfWeek] AS [Date], 
        ISNULL(dis.Dispensed, 0) As Dispensed,  
        ISNULL(del.Delivered, 0) AS Delivered, 
        ISNULL(del.Delivered, 0) - ISNULL(dis.Dispensed, 0) AS Variance,
        [Root].EDISID,
        [Root].ProductID
    FROM #Root AS [Root]
    LEFT OUTER JOIN Delivered del ON [Root].[FirstDateOfWeek] = del.FirstDateOfWeek AND [Root].EDISID = del.EDISID AND [Root].ProductID = del.ProductID
    LEFT OUTER JOIN Dispensed dis ON [Root].[FirstDateOfWeek] = dis.FirstDateOfWeek AND [Root].EDISID = dis.EDISID AND [Root].ProductID = dis.ProductID
    --ORDER BY [EDISID], [ProductID], [Date]
END

/* Join against this table to exclude products which are missing a week of dispense */
CREATE TABLE #ValidProducts ([EDISID] INT NOT NULL, [ProductID] INT NOT NULL, [IsKeg] BIT NOT NULL, [IsSyrup] BIT NOT NULL, PRIMARY KEY ([EDISID], [ProductID]))
INSERT INTO #ValidProducts ([EDISID], [ProductID], [IsKeg], [IsSyrup])
SELECT  
    [EDISID],
    [ProductID],
    CAST(CASE WHEN [P].[IsCask] = 0 AND [P].[IsMetric] = 0 AND [P].[IsWater] = 0 THEN 1 ELSE 0 END AS BIT),
    [P].[IsMetric]
FROM #Variance AS [V]
JOIN [dbo].[Products] AS [P] ON [V].[ProductID] = [P].[ID]
GROUP BY [EDISID], [ProductID], [P].[Description], [P].[IsCask], [P].[IsMetric], [P].[IsWater]
HAVING COUNT(CASE WHEN [Dispensed] = 0 THEN 1 ELSE NULL END) = 0
ORDER BY [EDISID], [ProductID]

IF @DebugRawVariance = 1
BEGIN
    SELECT
        [EDISID],
        [ProductID],
        [Date],
        [Dispensed],
        [Delivered],
        [Variance]
    FROM #Variance
    ORDER BY [EDISID], [ProductID], [Date]
END

IF @DebugValidProducts = 1
BEGIN
    SELECT  
        [EDISID],
        [ProductID],
        CAST(CASE WHEN [P].[IsCask] = 0 AND [P].[IsMetric] = 0 AND [P].[IsWater] = 0 THEN 1 ELSE 0 END AS BIT),
        [P].[IsMetric],
        COUNT(CASE WHEN [Dispensed] = 0 THEN 1 ELSE NULL END) AS [DispenseCount]
    FROM #Variance AS [V]
    JOIN [dbo].[Products] AS [P] ON [V].[ProductID] = [P].[ID]
    GROUP BY [EDISID], [ProductID], [P].[Description], [P].[IsCask], [P].[IsMetric], [P].[IsWater]
    ORDER BY [EDISID], [ProductID]
END

/*
SELECT
    [P].[Description] AS [Product],
    * 
FROM #Variance AS [V]
JOIN [dbo].[Products] AS [P] ON [V].[ProductID] = [P].[ID] 
ORDER BY
    [V].[EDISID],
    [P].[Description]
*/

DECLARE @syrupProductVariance int
DECLARE @syrupAvgWeekly int
DECLARE @kegProductVariance int
DECLARE @kegAvgWeekly int
DECLARE @kegPercentDifferent int

/* Configuration */
SELECT  @syrupProductVariance = CAST(ParameterValue AS INT) FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'SyrupProductVariance'
SELECT  @syrupAvgWeekly = CAST(ParameterValue AS INT)       FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'SyrupAvgWeeklyDelivery'
SELECT  @kegProductVariance = CAST(ParameterValue AS INT)   FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'KegProductVariance'
SELECT  @kegAvgWeekly = CAST(ParameterValue AS INT)         FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'KegAvgWeeklyDelivery'
SELECT  @kegPercentDifferent = CAST(ParameterValue AS INT)  FROM [SQL1\SQL1].Auditing.dbo.NotificationParameter WHERE ParameterName = 'KegPercentDifference'

IF @DebugParameters = 1
    SELECT 
        @syrupProductVariance [SyrupProductVariance], 
        @syrupAvgWeekly [SyrupAvgWeeklyDelivery], 
        @kegProductVariance [KegProductVariance], 
        @kegAvgWeekly [KegAvgWeeklyDelivery], 
        @kegPercentDifferent [KegPercentDifference]

-- Unit Conversion
DECLARE @ToGallons FLOAT = 0.125     -- {Pint Value} * @ToGallons
DECLARE @ToLitres FLOAT = 0.568261   -- {Pint Value} * @ToLitres

CREATE TABLE #ProductVariances
(
	EDISID INT,
	Product VARCHAR(255),
	ProductID int,
	Pump int
)

IF @DebugVariance = 1
BEGIN
    SELECT	
        [V].[EDISID], 
        [V].[ProductID], 
        [VP].[IsKeg],
        [VP].[IsSyrup],
        [P].[Description] AS [Product],
        AVG(CASE WHEN [VP].[IsSyrup] = 1 THEN [V].[Delivered] * @ToLitres ELSE [V].[Delivered] END) AS [AverageWeeklyDelivered], 
        AVG(CASE WHEN [VP].[IsSyrup] = 1 THEN [V].[Dispensed] * @ToLitres ELSE [V].[Dispensed] END) AS [AverageWeeklyDispensed],
        SUM(CASE WHEN [VP].[IsSyrup] = 1 THEN [V].[Variance] * @ToLitres ELSE [V].[Variance] END) AS [TotalVariance]
    FROM #Variance AS [V]
    JOIN #ValidProducts AS [VP] ON [V].[EDISID] = [VP].[EDISID] AND [V].[ProductID] = [VP].[ProductID]
    INNER JOIN [dbo].[Products] AS [P] ON [VP].[ProductID] = [P].[ID]
    WHERE
        [V].[Dispensed] > 0 OR [V].[Delivered] > 0
    GROUP BY 
        [V].[EDISID], [V].[ProductID], [VP].[IsKeg], [VP].[IsSyrup], [P].[Description]
    ORDER BY 
        [V].[EDISID], [P].[Description]
END

INSERT INTO #ProductVariances
SELECT DISTINCT
    [S].[EDISID], 
	[P].[Description],
	[P].[ID],
	[PS].[Pump]
FROM (
    SELECT	
        [V].[EDISID], 
        [V].[ProductID], 
        [VP].[IsKeg],
        [VP].[IsSyrup],
        AVG(CASE WHEN [VP].[IsSyrup] = 1 THEN [V].[Delivered] * @ToLitres ELSE [V].[Delivered] END) AS [AverageWeeklyDelivered], 
        AVG(CASE WHEN [VP].[IsSyrup] = 1 THEN [V].[Dispensed] * @ToLitres ELSE [V].[Dispensed] END) AS [AverageWeeklyDispensed],
        SUM(CASE WHEN [VP].[IsSyrup] = 1 THEN [V].[Variance] * @ToLitres ELSE [V].[Variance] END) AS [TotalVariance]
    FROM #Variance AS [V]
    JOIN [dbo].[Products] AS [P] ON [V].[ProductID] = [P].[ID]
    JOIN #ValidProducts AS [VP] ON [V].[EDISID] = [VP].[EDISID] AND [V].[ProductID] = [VP].[ProductID]
    WHERE
        [V].[Dispensed] > 0 OR [V].[Delivered] > 0
    GROUP BY 
        [V].[EDISID], [V].[ProductID], [VP].[IsKeg], [VP].[IsSyrup]
    ) AS [WeeklyVariance]
JOIN [dbo].[Sites] AS [S] ON [WeeklyVariance].[EDISID] = [S].[EDISID]
JOIN [dbo].[Products] AS [P] ON [WeeklyVariance].[ProductID] = [P].ID
LEFT JOIN [dbo].[PumpSetup] AS [PS] ON [S].[EDISID] = [PS].[EDISID] AND [PS].[ValidTo] IS NULL AND [P].[ID] = [PS].[ProductID]
WHERE 
    (
        ([WeeklyVariance].[IsSyrup] = 1 AND 
            ([WeeklyVariance].[TotalVariance] >= @syrupProductVariance) 
             AND 
             ([WeeklyVariance].[TotalVariance] > ([WeeklyVariance].[AverageWeeklyDelivered] * @syrupAvgWeekly))
        )
        OR
        ([WeeklyVariance].[IsKeg] = 1 AND 
            ([WeeklyVariance].[TotalVariance] >= @kegProductVariance) 
            AND 
            ([WeeklyVariance].[TotalVariance] > ([WeeklyVariance].[AverageWeeklyDelivered] * @kegAvgWeekly))
        )
        OR
        ([WeeklyVariance].[IsKeg] = 1 AND 
            ([WeeklyVariance].[TotalVariance] < @kegProductVariance) 
            AND 
            ([WeeklyVariance].[AverageWeeklyDelivered] > ([WeeklyVariance].[AverageWeeklyDispensed] * (@kegPercentDifferent / 100.0)))
        )
    )

SELECT  EDISID, SUBSTRING (
		(
		SELECT ';' + Product
		FROM #ProductVariances WHERE 
			EDISID = Results.EDISID
		FOR XML PATH (''),TYPE).value('.','VARCHAR(4000)')
		,2,4000
	) AS ProductList, ProductID, Pump
FROM #ProductVariances Results
--removed group by as we now need separate notifications for each product 
--(generate notifications should ensure multiple notifications aren't raised in SiteNotification, just stored against product) 

DROP TABLE #ProductVariances
DROP TABLE #PrimaryProducts
DROP TABLE #ValidProducts
DROP TABLE #Variance
DROP TABLE #Sites
DROP TABLE #Root
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ExceptionPositiveVariance] TO PUBLIC
    AS [dbo];

