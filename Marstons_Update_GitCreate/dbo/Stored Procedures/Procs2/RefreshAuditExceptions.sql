
CREATE PROCEDURE [dbo].[RefreshAuditExceptions]
(
    @CurrentWeek			DATETIME,
    @OnlyCurrentUsersSites	BIT = 0,
	@RebuildVariance		BIT = 1
)
AS

--DECLARE @CurrentWeek			DATETIME = '2014-05-12'
--DECLARE @OnlyCurrentUsersSites	BIT = 0
--DECLARE @RebuildVariance		BIT = 0

SET NOCOUNT ON
SET DATEFIRST 1

CREATE TABLE #Sites(EDISID INT, SiteOnline DATETIME, Closed BIT, Hidden BIT, LastDispenseWeek DATETIME, WeekCount INT, SystemTypeID INT, LastDownload DATETIME, TrafficLight INT, Quality BIT)
CREATE TABLE #SiteIssues(EDISID INT, TrafficLightNo INT, TrafficLightDescription VARCHAR(4000))
CREATE TABLE #Stock(EDISID INT, [Date] DATETIME, StockMonday DATETIME)
CREATE TABLE #PeriodCacheVarianceInternal(EDISID INT, ProductID INT, WeekCommencing DATETIME, Variance FLOAT)
CREATE TABLE #CumulativeVariance(EDISID INT, ProductID INT, WeekCommencing DATETIME, Variance FLOAT, CumulativeVariance FLOAT, IsPurple BIT)
CREATE TABLE #SiteProductTrends(EDISID INT, ProductID INT, Trend FLOAT)
CREATE TABLE #StockTLData(EDISID INT, ProductID INT, CurrentProductStockVariance FLOAT, CurrentWeekStockVariance FLOAT, MultipleTimesDeliveryAverage FLOAT)
CREATE TABLE #TrendsTLData(EDISID INT, ProductID INT, SiteOnline DATETIME, CurrentVariance FLOAT, Trend FLOAT, Dispensed FLOAT, TwentyPercentOfDispense FLOAT, TenPercentOfDispense FLOAT, FivePercentOfDispense FLOAT, MultipleTimesDeliveryAverage FLOAT)
CREATE TABLE #VarianceTLData(EDISID INT, ProductID INT, SiteOnline DATETIME, CurrentVariance FLOAT, TwentyPercentOfDispense FLOAT, TenPercentOfDispense FLOAT, FivePercentOfDispense FLOAT, Dispensed FLOAT, MultipleTimesDeliveryAverage FLOAT)
CREATE TABLE #ProductLastDispense(EDISID INT, ProductID INT, LastDispenseWeek DATETIME)
CREATE TABLE #StockTLRules(EDISID INT, ProductID INT, Product VARCHAR(500), RuleTriggered FLOAT, NewTrafficLight INT, RuleDescription VARCHAR(4000))
CREATE TABLE #TrendsTLRules(EDISID INT, ProductID INT, Product VARCHAR(500), Dispensed FLOAT, RuleTriggered FLOAT, NewTrafficLight INT, RuleDescription VARCHAR(4000))

CREATE TABLE #PeriodAdjustedVariance (
	EDISID INT, 
	ProductID INT, 
	WeekCommencing DATETIME, 
	Dispensed FLOAT, 
	Delivered FLOAT, 
	Variance FLOAT, 
	StockDate DATETIME,
	Stock FLOAT,
	StockVariance FLOAT)
	
CREATE TABLE #PeriodStockAdjustedVariance (
	EDISID INT, 
	ProductID INT, 
	WeekCommencing DATETIME, 
	Dispensed FLOAT, 
	Delivered FLOAT, 
	Variance FLOAT, 
	CumulativeVariance FLOAT,
	Stock FLOAT,
	StockVariance FLOAT,
	CumulativeStockVariance FLOAT)

DECLARE @CurrentWeekFrom DATETIME
DECLARE @WeekFromTwelveWeeks DATETIME
--DECLARE @WeekFromTwentySixWeeks DATETIME
DECLARE @FourWeeksAgoWeekFrom DATETIME
DECLARE @To DATETIME
DECLARE @DatabaseID INT
DECLARE @AuditWeeksBack INT
DECLARE @UseStock BIT
DECLARE @UseTrends BIT
DECLARE @MultipleAuditors BIT
DECLARE @MonthCount INT
DECLARE @NotAuditedForWeeks INT
DECLARE @TrafficLightProductVarianceMultiplier INT

SET @CurrentWeekFrom = @CurrentWeek
SET @To = DATEADD(day, 6, @CurrentWeekFrom)
SET @WeekFromTwelveWeeks = DATEADD(week, -11, @CurrentWeekFrom)
--SET @WeekFromTwentySixWeeks = DATEADD(week, -25, @CurrentWeekFrom)
SET @FourWeeksAgoWeekFrom = DATEADD(week, -4, @CurrentWeekFrom)
SET @MonthCount = DATEDIFF(MONTH, CAST(CAST(YEAR(@WeekFromTwelveWeeks) AS VARCHAR(4)) + '/' + CAST(MONTH(@WeekFromTwelveWeeks) AS VARCHAR(2)) + '/01' AS DATETIME), CAST(CAST(YEAR(@To) AS VARCHAR(4)) + '/' + CAST(MONTH(@To) AS VARCHAR(2)) + '/01' AS DATETIME)) + 1
SET @NotAuditedForWeeks = (SELECT NotAuditedForWeeks FROM AuditExceptionConfiguration)
SET @TrafficLightProductVarianceMultiplier = (SELECT TrafficLightProductVarianceMultiplier FROM AuditExceptionConfiguration)

IF @RebuildVariance = 1
BEGIN
	EXEC dbo.PeriodCacheVarianceInternalRebuild @FourWeeksAgoWeekFrom, @To, 1, @OnlyCurrentUsersSites
END

SELECT @DatabaseID = CAST(PropertyValue AS VARCHAR)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

SELECT @AuditWeeksBack = ISNULL(CAST(PropertyValue AS INTEGER), 1)
FROM Configuration
WHERE PropertyName = 'AuditWeeksBehind'

SELECT @UseStock = ShowApproxVarianceStock, @UseTrends = ShowTrends
FROM [EDISSQL1\SQL1].ServiceLogger.dbo.EDISDatabases
WHERE [ID] = @DatabaseID

SELECT @MultipleAuditors = MultipleAuditors
FROM [EDISSQL1\SQL1].ServiceLogger.dbo.EDISDatabases
WHERE Name = DB_NAME()
AND (LimitToClient = HOST_NAME() OR LimitToClient IS NULL)

INSERT INTO #Sites
(EDISID, SiteOnline, Closed, Hidden, LastDispenseWeek, WeekCount, SystemTypeID, LastDownload, TrafficLight, Quality)
SELECT Sites.EDISID, SiteOnline, SiteClosed, Hidden , LastSiteDispenseDate.CurrentWeekFrom, DATEDIFF(week, CASE WHEN SiteOnline > @WeekFromTwelveWeeks THEN SiteOnline ELSE @WeekFromTwelveWeeks END, @CurrentWeekFrom) + 1, SystemTypeID, LastDownload, SiteRankingCurrent.Audit, Sites.Quality
FROM Sites
LEFT JOIN ( SELECT EDISID, MAX(WeekCommencing) AS CurrentWeekFrom
	   FROM PeriodCacheVarianceInternal
	   WHERE WeekCommencing <= @To
	   GROUP BY EDISID) AS LastSiteDispenseDate ON LastSiteDispenseDate.EDISID = Sites.EDISID
JOIN Configuration ON PropertyName = 'AuditorName'
LEFT JOIN SiteRankingCurrent ON SiteRankingCurrent.EDISID = Sites.EDISID
WHERE Hidden = 0
AND ((CASE WHEN @MultipleAuditors = 0 THEN UPPER(Configuration.PropertyValue) ELSE UPPER(dbo.udfNiceName(SiteUser)) END) = UPPER(dbo.udfNiceName(SUSER_SNAME())) OR @OnlyCurrentUsersSites = 0) 
AND SiteOnline <= @To

-- DEBUG *****************************************************************
--DELETE FROM #Sites WHERE EDISID NOT IN (2453)

---- STOCK
DECLARE @OldestStockFrom DATETIME
DECLARE @OldestStockWeekBack INT

SELECT @OldestStockWeekBack = CAST(PropertyValue AS INTEGER) 
FROM Configuration
WHERE PropertyName = 'Oldest Stock Weeks Back'

SET @OldestStockFrom = DATEADD(WEEK, @OldestStockWeekBack * -1, @WeekFromTwelveWeeks)

INSERT INTO #Stock
(EDISID, [Date], StockMonday)
SELECT Sites.EDISID, MAX([Date]), MAX(DATEADD(dw, -DATEPART(dw, [Date]) + 1, [Date]))
FROM Stock
JOIN MasterDates ON MasterDates.[ID] = Stock.MasterDateID
JOIN #Sites AS Sites ON Sites.EDISID = MasterDates.EDISID
GROUP BY Sites.EDISID, Sites.SiteOnline
HAVING MAX([Date]) >= @OldestStockFrom 
AND MAX([Date]) >= Sites.SiteOnline
AND @UseStock = 1

INSERT INTO #ProductLastDispense
(EDISID, ProductID, LastDispenseWeek)
SELECT PeriodCacheVarianceInternal.EDISID,
	   PeriodCacheVarianceInternal.ProductID,
	   MAX(PeriodCacheVarianceInternal.WeekCommencing) AS LastDispenseWeek
FROM PeriodCacheVarianceInternal
JOIN #Sites AS Sites ON Sites.EDISID = PeriodCacheVarianceInternal.EDISID
WHERE WeekCommencing BETWEEN Sites.SiteOnline AND @To
GROUP BY PeriodCacheVarianceInternal.EDISID, PeriodCacheVarianceInternal.ProductID

INSERT INTO #PeriodAdjustedVariance
SELECT	PeriodCacheVarianceInternal.EDISID, 
		PeriodCacheVarianceInternal.ProductID, 
		WeekCommencing, 
		Dispensed, 
		Delivered, 
		Variance, 
		RecentStockDate,
		CASE WHEN RecentStockDate <= WeekCommencing THEN Stock ELSE NULL END AS Stock,
		CASE WHEN RecentStockDate <= WeekCommencing THEN StockAdjustedVariance ELSE NULL END AS StockVariance
FROM PeriodCacheVarianceInternal
JOIN Products ON Products.[ID] = PeriodCacheVarianceInternal.ProductID
LEFT JOIN(
	SELECT PeriodCacheVarianceInternal.EDISID, ProductID, MAX(WeekCommencing) AS RecentStockDate
	FROM PeriodCacheVarianceInternal
	JOIN #Stock AS Stock ON Stock.EDISID = PeriodCacheVarianceInternal.EDISID
	WHERE WeekCommencing BETWEEN StockMonday AND @CurrentWeekFrom
	AND StockDate IS NOT NULL
	GROUP BY PeriodCacheVarianceInternal.EDISID, ProductID
) AS StockDates ON PeriodCacheVarianceInternal.EDISID = StockDates.EDISID AND PeriodCacheVarianceInternal.ProductID = StockDates.ProductID
JOIN #Stock AS Stock ON Stock.EDISID = PeriodCacheVarianceInternal.EDISID
LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = PeriodCacheVarianceInternal.EDISID AND Products.[ID] = SiteProductTies.ProductID
LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = PeriodCacheVarianceInternal.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
WHERE WeekCommencing BETWEEN StockMonday AND @CurrentWeekFrom
AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1

INSERT INTO #PeriodStockAdjustedVariance
SELECT	VarianceA.EDISID, 
		VarianceA.ProductID,
		VarianceA.WeekCommencing, 
		VarianceA.Delivered, 
		VarianceA.Dispensed, 
		VarianceA.Variance,
		SUM(VarianceB.Variance) AS CumulativeVariance, 
		VarianceA.Stock, 
		VarianceA.StockVariance AS StockVariance, 
		SUM(VarianceB.StockVariance) AS CumulativeStockVariance
FROM #PeriodAdjustedVariance AS VarianceA
CROSS JOIN #PeriodAdjustedVariance AS VarianceB
WHERE ((VarianceA.EDISID = VarianceB.EDISID) 
AND (VarianceA.ProductID = VarianceB.ProductID OR VarianceA.ProductID IS NULL) 
AND (VarianceB.WeekCommencing <= VarianceA.WeekCommencing))
GROUP BY VarianceA.EDISID, VarianceA.ProductID, VarianceA.WeekCommencing, VarianceA.Delivered, VarianceA.Dispensed, VarianceA.Variance, VarianceA.Stock, VarianceA.StockVariance
ORDER BY VarianceA.EDISID, VarianceA.ProductID, VarianceA.WeekCommencing

-- Individual products
INSERT INTO #StockTLData
(EDISID, ProductID, CurrentProductStockVariance, CurrentWeekStockVariance, MultipleTimesDeliveryAverage)
SELECT	CurrentProductStock.EDISID,
		CurrentProductStock.ProductID,
		CurrentProductStock.CurrentStockVariance,
		CurrentWeekStock.CurrentStockVariance,
		PeriodProductDelivery.MultipleTimesDeliveryAverage
FROM (	SELECT	PeriodStockAdjustedVariance.EDISID, 
				PeriodStockAdjustedVariance.ProductID, 
				SUM(CumulativeStockVariance)/8 AS CurrentStockVariance
		FROM #PeriodStockAdjustedVariance AS PeriodStockAdjustedVariance
		JOIN #Sites AS Sites ON Sites.EDISID = PeriodStockAdjustedVariance.EDISID
		JOIN Products ON Products.[ID] = PeriodStockAdjustedVariance.ProductID AND IsGuestAle = 0 AND IsCask = 0
		JOIN #ProductLastDispense AS ProductLastDispense ON ProductLastDispense.EDISID = Sites.EDISID AND ProductLastDispense.ProductID = Products.[ID]
		WHERE WeekCommencing = ProductLastDispense.LastDispenseWeek
		GROUP BY PeriodStockAdjustedVariance.EDISID, PeriodStockAdjustedVariance.ProductID
	 ) AS CurrentProductStock
JOIN (
		SELECT	PeriodStockAdjustedVariance.EDISID,  
				SUM(CumulativeStockVariance)/8 AS CurrentStockVariance
		FROM #PeriodStockAdjustedVariance AS PeriodStockAdjustedVariance
		JOIN #Sites AS Sites ON Sites.EDISID = PeriodStockAdjustedVariance.EDISID
		JOIN Products ON Products.[ID] = PeriodStockAdjustedVariance.ProductID AND IsGuestAle = 0 AND IsCask = 0
		JOIN #ProductLastDispense AS ProductLastDispense ON ProductLastDispense.EDISID = Sites.EDISID AND ProductLastDispense.ProductID = Products.[ID]
		WHERE WeekCommencing = ProductLastDispense.LastDispenseWeek
		GROUP BY PeriodStockAdjustedVariance.EDISID
) AS CurrentWeekStock ON CurrentWeekStock.EDISID = CurrentProductStock.EDISID
JOIN (
		SELECT	PeriodCacheVarianceInternal.EDISID,  
				ProductID,
				((SUM(Delivered)/Sites.WeekCount)/8)*@TrafficLightProductVarianceMultiplier AS MultipleTimesDeliveryAverage
		FROM #Stock AS Stock
		JOIN #Sites AS Sites ON Sites.EDISID = Stock.EDISID
		JOIN PeriodCacheVarianceInternal ON PeriodCacheVarianceInternal.EDISID = Stock.EDISID AND PeriodCacheVarianceInternal.WeekCommencing BETWEEN @WeekFromTwelveWeeks AND @CurrentWeekFrom
		JOIN Products ON Products.[ID] = PeriodCacheVarianceInternal.ProductID AND IsGuestAle = 0 AND IsCask = 0
		GROUP BY PeriodCacheVarianceInternal.EDISID, ProductID, Sites.WeekCount
) AS PeriodProductDelivery ON PeriodProductDelivery.EDISID = CurrentProductStock.EDISID AND PeriodProductDelivery.ProductID = CurrentProductStock.ProductID
LEFT JOIN (
		SELECT	PeriodCacheVarianceInternal.EDISID, 
				PeriodCacheVarianceInternal.ProductID,
				SUM(Dispensed)/8 AS Dispensed,
				SUM(Delivered)/8 AS Delivered
		FROM PeriodCacheVarianceInternal
		JOIN #Stock AS Stock ON Stock.EDISID = PeriodCacheVarianceInternal.EDISID
		JOIN #Sites AS Sites ON Sites.EDISID = Stock.EDISID
		JOIN Products ON Products.[ID] = PeriodCacheVarianceInternal.ProductID AND IsGuestAle = 0 AND IsCask = 0
		WHERE WeekCommencing BETWEEN CASE WHEN Sites.SiteOnline > @WeekFromTwelveWeeks THEN Sites.SiteOnline ELSE @WeekFromTwelveWeeks END AND @CurrentWeekFrom
		GROUP BY PeriodCacheVarianceInternal.EDISID, PeriodCacheVarianceInternal.ProductID
) AS CurrentProductTwelveWeekVariance ON CurrentProductTwelveWeekVariance.EDISID = CurrentProductStock.EDISID AND CurrentProductTwelveWeekVariance.ProductID = CurrentProductStock.ProductID
JOIN (
	SELECT PumpSetup.EDISID, COALESCE(CASE WHEN PGP.IsPrimary = 1 AND TypeID = 1 THEN PGP.ProductID ELSE NULL END, Products.[ID]) AS ProductID
	FROM PumpSetup
	JOIN #Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
	JOIN Products ON Products.[ID] = PumpSetup.ProductID
	LEFT JOIN ProductGroupProducts ON ProductGroupProducts.ProductID = Products.[ID]
	LEFT JOIN ProductGroups ON ProductGroups.[ID] = ProductGroupProducts.ProductGroupID AND TypeID = 1
	LEFT JOIN ProductGroupProducts AS PGP ON PGP.ProductGroupID = ProductGroups.ID
	WHERE ValidTo IS NULL
	GROUP BY PumpSetup.EDISID, COALESCE(CASE WHEN PGP.IsPrimary = 1 AND TypeID = 1 THEN PGP.ProductID ELSE NULL END, Products.[ID])
) AS ActivePumps ON ActivePumps.EDISID = CurrentProductStock.EDISID AND ActivePumps.ProductID = CurrentProductStock.ProductID
--WHERE CurrentProductTwelveWeekVariance.Delivered > 0 AND CurrentProductTwelveWeekVariance.Dispensed > 0

-- Consolidated Casks (0 is product ID)
INSERT INTO #StockTLData
(EDISID, ProductID, CurrentProductStockVariance, CurrentWeekStockVariance, MultipleTimesDeliveryAverage)
SELECT	CurrentProductStock.EDISID,
		CurrentProductStock.ProductID,
		CurrentProductStock.CurrentStockVariance,
		CurrentWeekStock.CurrentStockVariance,
		PeriodProductDelivery.MultipleTimesDeliveryAverage
FROM (	SELECT	PeriodStockAdjustedVariance.EDISID, 
				0 AS ProductID, 
				SUM(CumulativeStockVariance)/8 AS CurrentStockVariance
		FROM #PeriodStockAdjustedVariance AS PeriodStockAdjustedVariance
		JOIN #Sites AS Sites ON Sites.EDISID = PeriodStockAdjustedVariance.EDISID
		JOIN Products ON Products.[ID] = PeriodStockAdjustedVariance.ProductID AND IsCask = 1
		JOIN #ProductLastDispense AS ProductLastDispense ON ProductLastDispense.EDISID = Sites.EDISID AND ProductLastDispense.ProductID = Products.[ID]
		WHERE WeekCommencing = ProductLastDispense.LastDispenseWeek
		GROUP BY PeriodStockAdjustedVariance.EDISID
	 ) AS CurrentProductStock
JOIN (
		SELECT	PeriodStockAdjustedVariance.EDISID,  
				SUM(CumulativeStockVariance)/8 AS CurrentStockVariance
		FROM #PeriodStockAdjustedVariance AS PeriodStockAdjustedVariance
		JOIN #Sites AS Sites ON Sites.EDISID = PeriodStockAdjustedVariance.EDISID
		JOIN #ProductLastDispense AS ProductLastDispense ON ProductLastDispense.EDISID = Sites.EDISID AND ProductLastDispense.ProductID = PeriodStockAdjustedVariance.ProductID
		WHERE WeekCommencing = ProductLastDispense.LastDispenseWeek
		GROUP BY PeriodStockAdjustedVariance.EDISID
) AS CurrentWeekStock ON CurrentWeekStock.EDISID = CurrentProductStock.EDISID
JOIN (
		SELECT	PeriodCacheVarianceInternal.EDISID,  
				0 AS ProductID,
				((SUM(Delivered)/Sites.WeekCount)/8)*@TrafficLightProductVarianceMultiplier AS MultipleTimesDeliveryAverage
		FROM #Stock AS Stock
		JOIN #Sites AS Sites ON Sites.EDISID = Stock.EDISID
		JOIN PeriodCacheVarianceInternal ON PeriodCacheVarianceInternal.EDISID = Stock.EDISID AND PeriodCacheVarianceInternal.WeekCommencing BETWEEN @WeekFromTwelveWeeks AND @CurrentWeekFrom
		JOIN Products ON Products.[ID] = PeriodCacheVarianceInternal.ProductID AND IsCask = 1
		GROUP BY PeriodCacheVarianceInternal.EDISID, Sites.WeekCount
) AS PeriodProductDelivery ON PeriodProductDelivery.EDISID = CurrentProductStock.EDISID AND PeriodProductDelivery.ProductID = CurrentProductStock.ProductID

-- Remove the Consolidated Casks row (ProductID = 0) from the results if a cask product without stock is found
DELETE
FROM #StockTLData
WHERE ProductID = 0 
AND #StockTLData.EDISID IN
(
	SELECT BadStock.EDISID
	FROM #StockTLData
	JOIN (	SELECT EDISID, SUM(CASE WHEN CurrentProductStockVariance IS NULL THEN 1 ELSE 0 END) AS NoStockCount
			FROM #StockTLData
			JOIN Products ON Products.[ID] = #StockTLData.ProductID AND Products.IsCask = 1
			GROUP BY EDISID
	) AS BadStock ON BadStock.EDISID = #StockTLData.EDISID
	WHERE ProductID = 0 AND NoStockCount > 0
)

INSERT INTO #StockTLRules(EDISID, ProductID, Product, RuleTriggered, NewTrafficLight, RuleDescription)
SELECT EDISID, ProductID, Product, RuleTriggered,
		CASE RuleTriggered WHEN 1 THEN 1
							WHEN 2 THEN 2
							WHEN 3 THEN 2
							WHEN 4 THEN 3 END AS NewTrafficLight,
		CASE RuleTriggered WHEN 1 THEN 'Product stock of -11 Gallons or Less'
							WHEN 2 THEN 'Product stock between -5 and -11 Gallons'
							WHEN 3 THEN 'Total product stock variance in 12 weeks is > 50 gallons, ' + CAST(@TrafficLightProductVarianceMultiplier AS VARCHAR) + 'x > than average weekly delivery & product has no missing weeks of dispense'
							WHEN 4 THEN '' END AS RuleDescription
FROM
(
	SELECT	Stock.EDISID,
			Stock.ProductID,
			CASE WHEN Stock.ProductID = 0 THEN 'Consolidated cask' ELSE Products.Description END AS Product,
			MIN(CASE WHEN CurrentProductStockVariance <= -11 THEN 1
					WHEN CurrentProductStockVariance <= -5 AND CurrentProductStockVariance >= -11 THEN 2
					WHEN CurrentProductStockVariance > MultipleTimesDeliveryAverage AND CurrentProductStockVariance > 50 AND (ZeroDispensers.EDISID IS NULL) THEN 3
					ELSE 4 END) AS RuleTriggered
	FROM #StockTLData AS Stock
	LEFT JOIN Products ON Products.ID = Stock.ProductID
	LEFT JOIN ( 
			/* RW: Find any weeks where we have no dispense at all */
			SELECT EDISID, ProductID
			FROM (
				SELECT PeriodCacheVarianceInternal.EDISID, WeekCommencing, CASE WHEN Products.IsCask = 1 THEN 0 ELSE ProductID END AS ProductID, SUM(Dispensed) AS WeekDispensed
				FROM PeriodCacheVarianceInternal
				JOIN #Sites AS Sites ON Sites.EDISID = PeriodCacheVarianceInternal.EDISID
				JOIN Products ON Products.ID = PeriodCacheVarianceInternal.ProductID
				WHERE WeekCommencing BETWEEN @WeekFromTwelveWeeks AND @CurrentWeekFrom
				GROUP BY PeriodCacheVarianceInternal.EDISID, WeekCommencing, CASE WHEN Products.IsCask = 1 THEN 0 ELSE ProductID END
			) AS WeeklyDispense
			WHERE WeekDispensed = 0
			GROUP BY EDISID, ProductID
	) AS ZeroDispensers ON ZeroDispensers.EDISID = Stock.EDISID AND ZeroDispensers.ProductID = Stock.ProductID
	GROUP BY Stock.EDISID, Stock.ProductID, Products.Description
) AS StockTLData

-- Traffic Light Key: 1 = Red, 2 = Amber, 3 = Green, 6 = Grey (not 4!)
-- RW: Note that the Grey trigger doesn't work here, since we can have no rows inserted here (if no dispense)
--     See much later (when we insert into AuditExceptions) how it is catered for

INSERT INTO #SiteIssues
(EDISID, TrafficLightNo, TrafficLightDescription)
SELECT StockTLRules.EDISID, MIN(NewTrafficLight) AS SuggestedTrafficLight, MIN(ProductList) AS TrafficLightReasons
FROM #StockTLRules AS StockTLRules
JOIN (
	SELECT  EDISID, SUBSTRING (
			(
			SELECT ';' + CAST(ProductID AS VARCHAR) + '|' + Product + '|' + RuleDescription
			FROM #StockTLRules WHERE 
				EDISID = Results.EDISID AND RuleTriggered <> 4
			FOR XML PATH (''),TYPE).value('.','VARCHAR(4000)')
			,2,4000
		) AS ProductList
	FROM #StockTLRules Results
	GROUP BY EDISID
) AS RuleTriggerReasons ON RuleTriggerReasons.EDISID = StockTLRules.EDISID
GROUP BY StockTLRules.EDISID

---- TRENDS
IF @UseTrends = 1
BEGIN
	-- RW:Deleted the 'old trends' version, which was dead anyway

	-- Products
	INSERT INTO #PeriodCacheVarianceInternal
	(EDISID, ProductID, WeekCommencing, Variance)
	SELECT PeriodCacheVarianceInternal.EDISID,
		   PeriodCacheVarianceInternal.ProductID,
		   WeekCommencing,
		   SUM(Variance)
	FROM PeriodCacheVarianceInternal
	JOIN Products ON Products.[ID] = PeriodCacheVarianceInternal.ProductID AND Products.IsGuestAle = 0
	JOIN #Sites AS Sites ON Sites.EDISID = PeriodCacheVarianceInternal.EDISID AND Sites.EDISID NOT IN (SELECT EDISID FROM #Stock)
	LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = PeriodCacheVarianceInternal.EDISID AND Products.[ID] = SiteProductTies.ProductID
	LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = PeriodCacheVarianceInternal.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
	WHERE WeekCommencing BETWEEN CASE WHEN Sites.SiteOnline > @WeekFromTwelveWeeks THEN Sites.SiteOnline ELSE @WeekFromTwelveWeeks END AND @CurrentWeekFrom
	AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1
	GROUP BY PeriodCacheVarianceInternal.EDISID,
		   PeriodCacheVarianceInternal.ProductID,
		   WeekCommencing
	
	-- Consolidated Casks
	INSERT INTO #PeriodCacheVarianceInternal
	(EDISID, ProductID, WeekCommencing, Variance)
	SELECT PeriodCacheVarianceInternal.EDISID,
		   0, --NULL,
		   WeekCommencing,
		   SUM(Variance)
	FROM PeriodCacheVarianceInternal
	JOIN Products ON Products.[ID] = PeriodCacheVarianceInternal.ProductID AND Products.IsCask = 1
	JOIN #Sites AS Sites ON Sites.EDISID = PeriodCacheVarianceInternal.EDISID AND Sites.EDISID NOT IN (SELECT EDISID FROM #Stock)
	LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = PeriodCacheVarianceInternal.EDISID AND Products.[ID] = SiteProductTies.ProductID
	LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = PeriodCacheVarianceInternal.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
	WHERE WeekCommencing BETWEEN CASE WHEN Sites.SiteOnline > @WeekFromTwelveWeeks THEN Sites.SiteOnline ELSE @WeekFromTwelveWeeks END AND @CurrentWeekFrom
	AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1
	GROUP BY PeriodCacheVarianceInternal.EDISID,
		     WeekCommencing
	ORDER BY WeekCommencing

	-- Products
	INSERT INTO #CumulativeVariance
	(EDISID, ProductID, WeekCommencing, Variance, CumulativeVariance, IsPurple)
	SELECT	VarianceA.EDISID, 
			VarianceA.ProductID, 
			VarianceA.WeekCommencing, 
			VarianceA.Variance/8 AS Variance, 
			SUM(VarianceB.Variance)/8 AS CumulativeVariance,
			CASE WHEN (VarianceA.Variance/8) < -5 THEN 1 ELSE 0 END AS IsPurple
	FROM #PeriodCacheVarianceInternal AS VarianceA
	CROSS JOIN #PeriodCacheVarianceInternal AS VarianceB
	WHERE ((VarianceA.EDISID = VarianceB.EDISID) 
	AND (VarianceA.ProductID = VarianceB.ProductID OR VarianceA.ProductID IS NULL) 
	AND (VarianceB.WeekCommencing <= VarianceA.WeekCommencing))
	GROUP BY VarianceA.EDISID, VarianceA.ProductID, VarianceA.WeekCommencing, VarianceA.Variance

	-- Consolidated Casks
	INSERT INTO #CumulativeVariance
	(EDISID, ProductID, WeekCommencing, Variance, CumulativeVariance, IsPurple)
	SELECT	VarianceA.EDISID, 
			0, 
			VarianceA.WeekCommencing, 
			VarianceA.Variance/8 AS Variance, 
			SUM(VarianceB.Variance)/8 AS CumulativeVariance,
			CASE WHEN (VarianceA.Variance)/8 < -5 THEN 1 ELSE 0 END AS IsPurple
	FROM #PeriodCacheVarianceInternal AS VarianceA
	CROSS JOIN #PeriodCacheVarianceInternal AS VarianceB
	WHERE ((VarianceA.EDISID = VarianceB.EDISID) 
	AND (VarianceB.WeekCommencing <= VarianceA.WeekCommencing))
	AND (VarianceA.ProductID IS NULL AND VarianceB.ProductID IS NULL)
	GROUP BY VarianceA.EDISID, VarianceA.WeekCommencing, VarianceA.Variance

	DECLARE @EDISID INT
	DECLARE @ProductID INT
	DECLARE @WeekCommencing DATETIME
	DECLARE @Variance FLOAT
	DECLARE @CumulativeVariance FLOAT
	DECLARE @IsPurple BIT

	DECLARE @PreviousEDISID INT
	DECLARE @PreviousProductID INT
	DECLARE @PreviousWeekCommencing DATETIME
	DECLARE @PreviousVariance FLOAT
	DECLARE @PreviousCumulativeVariance FLOAT
	DECLARE @PreviousIsPurple BIT

	DECLARE @NegativeFound BIT = 0
	DECLARE @ProductTrendTotal FLOAT = 0
	DECLARE @CurrentVarianceTotal FLOAT = 0
	DECLARE @PreviousVarianceTotal FLOAT = 0

	DECLARE curSiteProductVarianceWeeks CURSOR FORWARD_ONLY READ_ONLY FOR
	SELECT EDISID, ProductID, WeekCommencing, Variance, CumulativeVariance, IsPurple
	FROM #CumulativeVariance
	WHERE ProductID IS NOT NULL
	ORDER BY EDISID, ProductID, WeekCommencing

	OPEN curSiteProductVarianceWeeks
	FETCH NEXT FROM curSiteProductVarianceWeeks INTO @EDISID, @ProductID, @WeekCommencing, @Variance, @CumulativeVariance, @IsPurple

	WHILE @@FETCH_STATUS = 0
	BEGIN

		IF @PreviousEDISID IS NULL
		BEGIN
			SET @PreviousEDISID = @EDISID
			SET @PreviousProductID = @ProductID
			SET @PreviousVariance = @Variance
			SET @PreviousCumulativeVariance = @CumulativeVariance
			SET @PreviousIsPurple = @IsPurple
		
		END
			
		IF (@PreviousProductID <> @ProductID OR @PreviousEDISID <> @EDISID) AND (@ProductTrendTotal <> 0 OR @CurrentVarianceTotal <> 0 )
		BEGIN
			IF @NegativeFound = 1
			BEGIN
				SET @ProductTrendTotal = @ProductTrendTotal + @PreviousVarianceTotal
			END
		
			IF @ProductTrendTotal <> 0
			BEGIN
				INSERT INTO #SiteProductTrends
				(EDISID, ProductID, Trend)
				VALUES
				(@PreviousEDISID, @PreviousProductID, @ProductTrendTotal)
			
			END
			
			SET @ProductTrendTotal = 0
			SET @CurrentVarianceTotal = 0
			SET @NegativeFound = 0
			
		END
		
		SET @CurrentVarianceTotal = @CurrentVarianceTotal + @Variance

		IF @Variance < 0 AND @CurrentVarianceTotal <= -5
		BEGIN
			SET @NegativeFound = 1
			
		END
		
		IF @Variance > 0 AND @NegativeFound = 1
		BEGIN
			SET @ProductTrendTotal = @ProductTrendTotal + @PreviousVarianceTotal
			SET @CurrentVarianceTotal = @Variance
			SET @NegativeFound = 0
			
		END
		
		SET @PreviousEDISID = @EDISID
		SET @PreviousProductID = @ProductID
		SET @PreviousVariance = @Variance
		SET @PreviousCumulativeVariance = @CumulativeVariance
		SET @PreviousIsPurple = @IsPurple
		SET @PreviousVarianceTotal = @CurrentVarianceTotal
		
		FETCH NEXT FROM curSiteProductVarianceWeeks INTO @EDISID, @ProductID, @WeekCommencing, @Variance, @CumulativeVariance, @IsPurple

	END

	CLOSE curSiteProductVarianceWeeks
	DEALLOCATE curSiteProductVarianceWeeks

	IF (@ProductTrendTotal <> 0 OR @CurrentVarianceTotal <> 0 )
	BEGIN
		IF @NegativeFound = 1
		BEGIN
			SET @ProductTrendTotal = @ProductTrendTotal + @PreviousVarianceTotal
		END
		
		IF @ProductTrendTotal <> 0
		BEGIN
			INSERT INTO #SiteProductTrends
			(EDISID, ProductID, Trend)
			VALUES
			(@PreviousEDISID, @PreviousProductID, @ProductTrendTotal)
		
		END
	END

	-- Individual products
	INSERT INTO #TrendsTLData
	(EDISID, ProductID, SiteOnline, CurrentVariance, Trend, Dispensed, TwentyPercentOfDispense, TenPercentOfDispense, FivePercentOfDispense, MultipleTimesDeliveryAverage)
	SELECT	Sites.EDISID,
			CurrentProductTwelveWeekVariance.ProductID,
			Sites.SiteOnline,
			CurrentProductTwelveWeekVariance.Variance,
			SiteProductTrends.Trend,
			CurrentProductTwelveWeekVariance.Dispensed,
			CurrentProductTwelveWeekVariance.TwentyPercentOfDispense,
			CurrentProductTwelveWeekVariance.TenPercentOfDispense,
			CurrentProductTwelveWeekVariance.FivePercentOfDispense,
			PeriodProductDelivery.MultipleTimesDeliveryAverage
	FROM #Sites AS Sites
	LEFT JOIN (
			SELECT	PeriodCacheVarianceInternal.EDISID, 
					PeriodCacheVarianceInternal.ProductID,
					SUM(Dispensed)/8 AS Dispensed,
					SUM(Delivered)/8 AS Delivered,
					SUM(Variance)/8 AS Variance,
					((SUM(Dispensed)/8) / 100)*20 AS TwentyPercentOfDispense,
					((SUM(Dispensed)/8) / 100)*10 AS TenPercentOfDispense,
					((SUM(Dispensed)/8) / 100)*5 AS FivePercentOfDispense
			FROM PeriodCacheVarianceInternal
			JOIN #Sites AS Sites ON Sites.EDISID = PeriodCacheVarianceInternal.EDISID
			JOIN Products ON Products.[ID] = PeriodCacheVarianceInternal.ProductID AND IsGuestAle = 0
			WHERE (PeriodCacheVarianceInternal.WeekCommencing BETWEEN CASE WHEN Sites.SiteOnline > @WeekFromTwelveWeeks THEN Sites.SiteOnline ELSE @WeekFromTwelveWeeks END AND @CurrentWeekFrom)
			GROUP BY PeriodCacheVarianceInternal.EDISID, PeriodCacheVarianceInternal.ProductID
	) AS CurrentProductTwelveWeekVariance ON CurrentProductTwelveWeekVariance.EDISID = Sites.EDISID
	LEFT JOIN (
			SELECT	PeriodCacheVarianceInternal.EDISID,  
					PeriodCacheVarianceInternal.ProductID,
					((SUM(Delivered)/Sites.WeekCount)/8)*@TrafficLightProductVarianceMultiplier AS MultipleTimesDeliveryAverage
			FROM PeriodCacheVarianceInternal
			JOIN #Sites AS Sites ON Sites.EDISID = PeriodCacheVarianceInternal.EDISID
			JOIN Products ON Products.[ID] = PeriodCacheVarianceInternal.ProductID AND Products.IsGuestAle = 0
			LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = PeriodCacheVarianceInternal.EDISID AND Products.[ID] = SiteProductTies.ProductID
			LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = PeriodCacheVarianceInternal.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
			WHERE WeekCommencing BETWEEN CASE WHEN Sites.SiteOnline > @WeekFromTwelveWeeks THEN Sites.SiteOnline ELSE @WeekFromTwelveWeeks END AND @CurrentWeekFrom
			AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1
			GROUP BY PeriodCacheVarianceInternal.EDISID, PeriodCacheVarianceInternal.ProductID, Sites.WeekCount
	) AS PeriodProductDelivery ON PeriodProductDelivery.EDISID = Sites.EDISID AND PeriodProductDelivery.ProductID = CurrentProductTwelveWeekVariance.ProductID
	LEFT JOIN #SiteProductTrends AS SiteProductTrends ON SiteProductTrends.EDISID = CurrentProductTwelveWeekVariance.EDISID AND SiteProductTrends.ProductID = CurrentProductTwelveWeekVariance.ProductID
	JOIN (
		SELECT PumpSetup.EDISID, COALESCE(CASE WHEN PGP.IsPrimary = 1 AND TypeID = 1 THEN PGP.ProductID ELSE NULL END, Products.[ID]) AS ProductID
		FROM PumpSetup
		JOIN #Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
		JOIN Products ON Products.[ID] = PumpSetup.ProductID
		LEFT JOIN ProductGroupProducts ON ProductGroupProducts.ProductID = Products.[ID]
		LEFT JOIN ProductGroups ON ProductGroups.[ID] = ProductGroupProducts.ProductGroupID AND TypeID = 1
		LEFT JOIN ProductGroupProducts AS PGP ON PGP.ProductGroupID = ProductGroups.ID
		WHERE ValidTo IS NULL
		GROUP BY PumpSetup.EDISID, COALESCE(CASE WHEN PGP.IsPrimary = 1 AND TypeID = 1 THEN PGP.ProductID ELSE NULL END, Products.[ID])
	) AS ActivePumps ON ActivePumps.EDISID = CurrentProductTwelveWeekVariance.EDISID AND ActivePumps.ProductID = CurrentProductTwelveWeekVariance.ProductID
	WHERE Sites.EDISID NOT IN (SELECT EDISID FROM #Stock)
	--AND CurrentProductTwelveWeekVariance.Delivered > 0 AND CurrentProductTwelveWeekVariance.Dispensed > 0
	
	-- Consolidated Casks (0 is product ID)
	INSERT INTO #TrendsTLData
	(EDISID, ProductID, SiteOnline, CurrentVariance, Trend, Dispensed, TwentyPercentOfDispense, TenPercentOfDispense, FivePercentOfDispense, MultipleTimesDeliveryAverage)
	SELECT	Sites.EDISID,
			CurrentProductTwelveWeekVariance.ProductID,
			Sites.SiteOnline,
			CurrentProductTwelveWeekVariance.Variance,
			SUM(SiteProductTrends.Trend) AS Trend,
			CurrentProductTwelveWeekVariance.Dispensed,
			CurrentProductTwelveWeekVariance.TwentyPercentOfDispense,
			CurrentProductTwelveWeekVariance.TenPercentOfDispense,
			CurrentProductTwelveWeekVariance.FivePercentOfDispense,
			PeriodProductDelivery.MultipleTimesDeliveryAverage
	FROM #Sites AS Sites
	LEFT JOIN (
			SELECT	PeriodCacheVarianceInternal.EDISID, 
					0 AS ProductID,
					SUM(Dispensed)/8 AS Dispensed,
					SUM(Variance)/8 AS Variance,
					((SUM(Dispensed)/8) / 100)*20 AS TwentyPercentOfDispense,
					((SUM(Dispensed)/8) / 100)*10 AS TenPercentOfDispense,
					((SUM(Dispensed)/8) / 100)*5 AS FivePercentOfDispense
			FROM PeriodCacheVarianceInternal
			JOIN #Sites AS Sites ON Sites.EDISID = PeriodCacheVarianceInternal.EDISID
			JOIN Products ON Products.[ID] = PeriodCacheVarianceInternal.ProductID AND IsCask = 1
			LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = PeriodCacheVarianceInternal.EDISID AND Products.[ID] = SiteProductTies.ProductID
			LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = PeriodCacheVarianceInternal.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
			WHERE (PeriodCacheVarianceInternal.WeekCommencing BETWEEN CASE WHEN Sites.SiteOnline > @WeekFromTwelveWeeks THEN Sites.SiteOnline ELSE @WeekFromTwelveWeeks END AND @CurrentWeekFrom)
			AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1
			GROUP BY PeriodCacheVarianceInternal.EDISID
	) AS CurrentProductTwelveWeekVariance ON CurrentProductTwelveWeekVariance.EDISID = Sites.EDISID
	LEFT JOIN (
			SELECT	PeriodCacheVarianceInternal.EDISID,  
					0 AS ProductID,
					((SUM(Delivered)/Sites.WeekCount)/8)*@TrafficLightProductVarianceMultiplier AS MultipleTimesDeliveryAverage
			FROM PeriodCacheVarianceInternal
			JOIN #Sites AS Sites ON Sites.EDISID = PeriodCacheVarianceInternal.EDISID
			JOIN Products ON Products.[ID] = PeriodCacheVarianceInternal.ProductID AND IsCask = 1
			LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = PeriodCacheVarianceInternal.EDISID AND Products.[ID] = SiteProductTies.ProductID
			LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = PeriodCacheVarianceInternal.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
			WHERE (PeriodCacheVarianceInternal.WeekCommencing BETWEEN CASE WHEN Sites.SiteOnline > @WeekFromTwelveWeeks THEN Sites.SiteOnline ELSE @WeekFromTwelveWeeks END AND @CurrentWeekFrom)
			AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1
			GROUP BY PeriodCacheVarianceInternal.EDISID, Sites.WeekCount
	) AS PeriodProductDelivery ON PeriodProductDelivery.EDISID = Sites.EDISID AND PeriodProductDelivery.ProductID = CurrentProductTwelveWeekVariance.ProductID
	LEFT JOIN #SiteProductTrends AS SiteProductTrends ON SiteProductTrends.EDISID = CurrentProductTwelveWeekVariance.EDISID AND SiteProductTrends.ProductID = 0
	WHERE Sites.EDISID NOT IN (SELECT EDISID FROM #Stock)
	GROUP BY Sites.EDISID,
			CurrentProductTwelveWeekVariance.ProductID,
			Sites.SiteOnline,
			CurrentProductTwelveWeekVariance.Variance,
			CurrentProductTwelveWeekVariance.Dispensed,
			CurrentProductTwelveWeekVariance.TwentyPercentOfDispense,
			CurrentProductTwelveWeekVariance.TenPercentOfDispense,
			CurrentProductTwelveWeekVariance.FivePercentOfDispense,
			PeriodProductDelivery.MultipleTimesDeliveryAverage

	/* RW: Note that 'totaltrends.currentvariance' means the end/total of the 12 weeks, not the final week! */
	/*     Many changes here, including long-standing bug fixes to confusion in amber/red checks and 10/20% dispense */

	INSERT INTO #TrendsTLRules(EDISID, ProductID, Product, Dispensed, RuleTriggered, NewTrafficLight, RuleDescription)
	SELECT EDISID, ProductID, Product, Dispensed, RuleTriggered,
			    CASE RuleTriggered WHEN 1 THEN 1
						    WHEN 2 THEN 1
						    WHEN 2.5 THEN 1
						    WHEN 3 THEN 2
						    WHEN 4 THEN 2
						    WHEN 4.5 THEN 2
						    WHEN 5 THEN 2 
						    WHEN 6 THEN 2
						    WHEN 7 THEN 3
						    WHEN 8 THEN 6 END AS NewTrafficLight,
		CASE RuleTriggered WHEN 1 THEN '< 12 weeks data since online/COT and product has variance of -22 or less'
						    WHEN 2 THEN 'Trend is -22 or less & 20% of total dispense, also -22 or less in current weekly product variance'
						    WHEN 2.5 THEN 'Current traffic light is Red, sum of drop-down boxes is (-22 or less and 20% or more of total 12 week dispense), and one product or cask group have sum of drop-down boxes of (-22 or less and 20% or more of total 12 week dispense)'
						    WHEN 3 THEN '< 12 weeks data since online/COT and product has variance of -22 or less'
						    WHEN 4 THEN 'Current traffic light is not Green, sum of drop-down boxes is (-11 or less) and (10% or more of total 12 week dispense)'
						    WHEN 4.5 THEN 'Trend is -11 or less & 10% of total dispense, also -11 or less in current weekly product variance'
						    WHEN 5 THEN 'Product dispense total > 1000 gallons in 12 weeks & trend on product is > than 5% of total dispense' 
						    WHEN 6 THEN 'Total product variance in 12 weeks is > 50 gallons, ' + CAST(@TrafficLightProductVarianceMultiplier AS VARCHAR) + 'x > than average weekly delivery & product has no missing weeks of dispense'
						    WHEN 7 THEN 'Rules not triggered, defaulted to Green' 
						    /* RW: The below will never trigger, since no dispense means no rows returned! */
							WHEN 8 THEN 'No dispense, so defaulting to Grey' END AS [RuleDescription]

	FROM (
		SELECT	 TotalTrends.EDISID,
				TotalTrends.ProductID,
					CASE WHEN TotalTrends.ProductID = 0 THEN 'Consolidated cask' ELSE Products.Description END AS Product,
					TotalTrends.Dispensed,
					/* Grey if below: */
		CASE WHEN TotalTrends.Dispensed IS NULL THEN 0
					/* Red traffic light if below: */
					WHEN TotalTrends.CurrentVariance <= -22 AND TotalTrends.SiteOnline >= @WeekFromTwelveWeeks THEN 1
					WHEN (Sites.TrafficLight IN (2,3)) AND (FinalWeekVariance.Variance <= -22) AND (TotalTrends.Trend <= -22) AND ((TotalTrends.Trend *-1) >= TotalTrends.TwentyPercentOfDispense) THEN 2
					WHEN (Sites.TrafficLight = 1) AND (TotalTrends.Trend <= -22) AND ((TotalTrends.Trend *-1) >= TotalTrends.TwentyPercentOfDispense) THEN 2.5
					/* Amber traffic light if below: */
					WHEN TotalTrends.CurrentVariance <= -11 AND TotalTrends.SiteOnline >= @WeekFromTwelveWeeks THEN 3
					WHEN (Sites.TrafficLight <> 3) AND (TotalTrends.Trend <= -11 AND (TotalTrends.Trend * -1) >= TotalTrends.TenPercentOfDispense) THEN 4
					WHEN (Sites.TrafficLight = 3) AND (FinalWeekVariance.Variance <= -11) AND (TotalTrends.Trend <= -11 AND (TotalTrends.Trend * -1) >= TotalTrends.TenPercentOfDispense) AND (TotalTrends.CurrentVariance <= -11) THEN 4.5
					WHEN TotalTrends.Dispensed > 1000 AND (TotalTrends.Trend * -1) > TotalTrends.FivePercentOfDispense THEN 5 
					WHEN TotalTrends.CurrentVariance > TotalTrends.MultipleTimesDeliveryAverage AND TotalTrends.CurrentVariance > 50 AND (ZeroDispensers.EDISID IS NULL) THEN 6
					/* Green traffic light if below: */
					ELSE 7 END AS RuleTriggered
		FROM #TrendsTLData AS TotalTrends
		LEFT JOIN Products ON Products.ID = TotalTrends.ProductID
		LEFT JOIN ( 
					/* RW: Find any weeks where we have no dispense at all */
					SELECT EDISID, ProductID
					FROM (
						SELECT PeriodCacheVarianceInternal.EDISID, WeekCommencing, CASE WHEN Products.IsCask = 1 THEN 0 ELSE ProductID END AS ProductID, SUM(Dispensed) AS WeekDispensed
						FROM PeriodCacheVarianceInternal
						JOIN #Sites AS Sites ON Sites.EDISID = PeriodCacheVarianceInternal.EDISID
						JOIN Products ON Products.ID = PeriodCacheVarianceInternal.ProductID
						WHERE WeekCommencing BETWEEN @WeekFromTwelveWeeks AND @CurrentWeekFrom
						GROUP BY PeriodCacheVarianceInternal.EDISID, WeekCommencing, CASE WHEN Products.IsCask = 1 THEN 0 ELSE ProductID END
					) AS WeeklyDispense
					WHERE WeekDispensed = 0
					GROUP BY EDISID, ProductID
					) AS ZeroDispensers ON ZeroDispensers.EDISID = TotalTrends.EDISID AND ZeroDispensers.ProductID = TotalTrends.ProductID
		LEFT JOIN (
					/* RW: New idea for final week variance: just show per-product */
					SELECT  Variance.EDISID,
							ProductID,
							SUM(Variance.Variance)/8.0 AS Variance
					FROM #PeriodCacheVarianceInternal AS Variance
					JOIN #Sites AS Sites ON Sites.EDISID = Variance.EDISID
					LEFT JOIN Products ON Products.ID = Variance.ProductID
					WHERE WeekCommencing = @CurrentWeekFrom AND (Products.IsCask = 0 OR Variance.ProductID = 0)
					GROUP BY Variance.EDISID,
								ProductID
					) AS FinalWeekVariance ON FinalWeekVariance.EDISID = TotalTrends.EDISID AND FinalWeekVariance.ProductID = TotalTrends.ProductID
		JOIN #Sites AS Sites ON Sites.EDISID = TotalTrends.EDISID
		/* RW: TL change rules only apply to kegs or consolidated cask group */
		WHERE (Products.IsCask = 0 OR TotalTrends.ProductID = 0)
	) AS TrendsTLRulesDetail


    -- Traffic Light Key: 1 = Red, 2 = Amber, 3 = Green, 6 = Grey (not 4!)
	-- RW: Note that the Grey trigger doesn't work here, since we can have no rows inserted here (if no dispense)
	--     See much later (when we insert into AuditExceptions) how it is catered for

	INSERT INTO #SiteIssues
    (EDISID, TrafficLightNo, TrafficLightDescription)
	SELECT TrendsTLRules.EDISID, MIN(NewTrafficLight) AS SuggestedTrafficLight, MIN(ProductList) AS TrafficLightReasons
	FROM #TrendsTLRules AS TrendsTLRules
	JOIN (
		SELECT  EDISID, SUBSTRING (
				(
				SELECT ';' + CAST(ProductID AS VARCHAR) + '|' + Product + '|' + RuleDescription
				FROM #TrendsTLRules WHERE 
					EDISID = Results.EDISID AND RuleTriggered <> 7
				FOR XML PATH (''),TYPE).value('.','VARCHAR(4000)')
				,2,4000
			) AS ProductList
		FROM #TrendsTLRules Results
		GROUP BY EDISID
	) AS RuleTriggerReasons ON RuleTriggerReasons.EDISID = TrendsTLRules.EDISID
	GROUP BY TrendsTLRules.EDISID

END

IF @UseTrends = 0
BEGIN
-- VARIANCE
	INSERT INTO #PeriodCacheVarianceInternal
	(EDISID, ProductID, WeekCommencing, Variance)
	SELECT PeriodCacheVarianceInternal.EDISID,
		   PeriodCacheVarianceInternal.ProductID,
		   WeekCommencing,
		   SUM(Variance)
	FROM PeriodCacheVarianceInternal
	JOIN Products ON Products.[ID] = PeriodCacheVarianceInternal.ProductID
	JOIN #Sites AS Sites ON Sites.EDISID = PeriodCacheVarianceInternal.EDISID AND Sites.EDISID NOT IN (SELECT EDISID FROM #Stock)
	LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = PeriodCacheVarianceInternal.EDISID AND Products.[ID] = SiteProductTies.ProductID
	LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = PeriodCacheVarianceInternal.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
	WHERE WeekCommencing BETWEEN CASE WHEN Sites.SiteOnline > @WeekFromTwelveWeeks THEN Sites.SiteOnline ELSE @WeekFromTwelveWeeks END AND @CurrentWeekFrom
	AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1
	GROUP BY PeriodCacheVarianceInternal.EDISID,
		   PeriodCacheVarianceInternal.ProductID,
		   WeekCommencing

	INSERT INTO #CumulativeVariance
	(EDISID, ProductID, WeekCommencing, Variance, CumulativeVariance, IsPurple)
	SELECT	VarianceA.EDISID, 
			VarianceA.ProductID, 
			VarianceA.WeekCommencing, 
			VarianceA.Variance/8 AS Variance, 
			SUM(VarianceB.Variance)/8 AS CumulativeVariance,
			CASE WHEN (VarianceA.Variance/8) < -5 THEN 1 ELSE 0 END AS IsPurple
	FROM #PeriodCacheVarianceInternal AS VarianceA
	CROSS JOIN #PeriodCacheVarianceInternal AS VarianceB
	WHERE ((VarianceA.EDISID = VarianceB.EDISID) 
	AND (VarianceA.ProductID = VarianceB.ProductID OR VarianceA.ProductID IS NULL) 
	AND (VarianceB.WeekCommencing <= VarianceA.WeekCommencing))
	GROUP BY VarianceA.EDISID, VarianceA.ProductID, VarianceA.WeekCommencing, VarianceA.Variance

	-- Individual products
	INSERT INTO #VarianceTLData
	(EDISID, SiteOnline, ProductID, CurrentVariance, TwentyPercentOfDispense, TenPercentOfDispense, FivePercentOfDispense, Dispensed, MultipleTimesDeliveryAverage)
	SELECT	Sites.EDISID,
			Sites.SiteOnline,
			CurrentProductTwelveWeekVariance.ProductID,
			CurrentProductTwelveWeekVariance.Variance,
			CurrentProductTwelveWeekVariance.TwentyPercentOfDispense,
			CurrentProductTwelveWeekVariance.TenPercentOfDispense,
			CurrentProductTwelveWeekVariance.FivePercentOfDispense,
			CurrentProductTwelveWeekVariance.Dispensed,
			PeriodProductDelivery.MultipleTimesDeliveryAverage
	FROM #Sites AS Sites
	LEFT JOIN (
			SELECT	PeriodCacheVarianceInternal.EDISID, 
					PeriodCacheVarianceInternal.ProductID,
					SUM(Dispensed)/8 AS Dispensed,
					SUM(Delivered)/8 AS Delivered,
					SUM(Variance)/8 AS Variance,
					((SUM(Dispensed)/8) / 100)*20 AS TwentyPercentOfDispense,
					((SUM(Dispensed)/8) / 100)*10 AS TenPercentOfDispense,
					((SUM(Dispensed)/8) / 100)*5 AS FivePercentOfDispense
			FROM PeriodCacheVarianceInternal
			JOIN #Sites AS Sites ON Sites.EDISID = PeriodCacheVarianceInternal.EDISID
			JOIN Products ON Products.[ID] = PeriodCacheVarianceInternal.ProductID AND Products.IsGuestAle = 0
			LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = PeriodCacheVarianceInternal.EDISID AND Products.[ID] = SiteProductTies.ProductID
			LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = PeriodCacheVarianceInternal.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
			WHERE WeekCommencing BETWEEN CASE WHEN Sites.SiteOnline > @WeekFromTwelveWeeks THEN Sites.SiteOnline ELSE @WeekFromTwelveWeeks END AND @CurrentWeekFrom
			AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1
			GROUP BY PeriodCacheVarianceInternal.EDISID, PeriodCacheVarianceInternal.ProductID
	) AS CurrentProductTwelveWeekVariance ON CurrentProductTwelveWeekVariance.EDISID = Sites.EDISID
	LEFT JOIN (
			SELECT	PeriodCacheVarianceInternal.EDISID,  
					PeriodCacheVarianceInternal.ProductID,
					((SUM(Delivered)/Sites.WeekCount)/8)*@TrafficLightProductVarianceMultiplier AS MultipleTimesDeliveryAverage
			FROM PeriodCacheVarianceInternal
			JOIN #Sites AS Sites ON Sites.EDISID = PeriodCacheVarianceInternal.EDISID
			JOIN Products ON Products.[ID] = PeriodCacheVarianceInternal.ProductID AND Products.IsGuestAle = 0
			LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = PeriodCacheVarianceInternal.EDISID AND Products.[ID] = SiteProductTies.ProductID
			LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = PeriodCacheVarianceInternal.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
			WHERE WeekCommencing BETWEEN CASE WHEN Sites.SiteOnline > @WeekFromTwelveWeeks THEN Sites.SiteOnline ELSE @WeekFromTwelveWeeks END AND @CurrentWeekFrom
			AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1
			GROUP BY PeriodCacheVarianceInternal.EDISID, PeriodCacheVarianceInternal.ProductID, Sites.WeekCount
	) AS PeriodProductDelivery ON PeriodProductDelivery.EDISID = Sites.EDISID AND PeriodProductDelivery.ProductID = CurrentProductTwelveWeekVariance.ProductID
	JOIN
	(
		SELECT PumpSetup.EDISID, COALESCE(CASE WHEN PGP.IsPrimary = 1 AND TypeID = 1 THEN PGP.ProductID ELSE NULL END, Products.[ID]) AS ProductID
		FROM PumpSetup
		JOIN #Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
		JOIN Products ON Products.[ID] = PumpSetup.ProductID
		LEFT JOIN ProductGroupProducts ON ProductGroupProducts.ProductID = Products.[ID]
		LEFT JOIN ProductGroups ON ProductGroups.[ID] = ProductGroupProducts.ProductGroupID AND TypeID = 1
		LEFT JOIN ProductGroupProducts AS PGP ON PGP.ProductGroupID = ProductGroups.ID
		WHERE ValidTo IS NULL
		GROUP BY PumpSetup.EDISID, COALESCE(CASE WHEN PGP.IsPrimary = 1 AND TypeID = 1 THEN PGP.ProductID ELSE NULL END, Products.[ID])
	) AS ActivePumps ON ActivePumps.EDISID = CurrentProductTwelveWeekVariance.EDISID AND ActivePumps.ProductID = CurrentProductTwelveWeekVariance.ProductID
	WHERE Sites.EDISID NOT IN (SELECT EDISID FROM #Stock)
	--AND CurrentProductTwelveWeekVariance.Delivered > 0 AND CurrentProductTwelveWeekVariance.Dispensed > 0
	
	-- Consolidated Casks (0 is product ID)
	INSERT INTO #VarianceTLData
	(EDISID, SiteOnline, ProductID, CurrentVariance, TwentyPercentOfDispense, TenPercentOfDispense, FivePercentOfDispense, Dispensed, MultipleTimesDeliveryAverage)
	SELECT	Sites.EDISID,
			Sites.SiteOnline,
			CurrentProductTwelveWeekVariance.ProductID,
			CurrentProductTwelveWeekVariance.Variance,
			CurrentProductTwelveWeekVariance.TwentyPercentOfDispense,
			CurrentProductTwelveWeekVariance.TenPercentOfDispense,
			CurrentProductTwelveWeekVariance.FivePercentOfDispense,
			CurrentProductTwelveWeekVariance.Dispensed,
			PeriodProductDelivery.MultipleTimesDeliveryAverage
	FROM #Sites AS Sites
	LEFT JOIN (
			SELECT	PeriodCacheVarianceInternal.EDISID, 
					0 AS ProductID,
					SUM(Dispensed)/8 AS Dispensed,
					SUM(Variance)/8 AS Variance,
					((SUM(Dispensed)/8) / 100)*20 AS TwentyPercentOfDispense,
					((SUM(Dispensed)/8) / 100)*10 AS TenPercentOfDispense,
					((SUM(Dispensed)/8) / 100)*5 AS FivePercentOfDispense
			FROM PeriodCacheVarianceInternal
			JOIN #Sites AS Sites ON Sites.EDISID = PeriodCacheVarianceInternal.EDISID
			JOIN Products ON Products.[ID] = PeriodCacheVarianceInternal.ProductID AND IsCask = 1
			LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = PeriodCacheVarianceInternal.EDISID AND Products.[ID] = SiteProductTies.ProductID
			LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = PeriodCacheVarianceInternal.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
			WHERE WeekCommencing BETWEEN CASE WHEN Sites.SiteOnline > @WeekFromTwelveWeeks THEN Sites.SiteOnline ELSE @WeekFromTwelveWeeks END AND @CurrentWeekFrom
			AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1
			GROUP BY PeriodCacheVarianceInternal.EDISID
	) AS CurrentProductTwelveWeekVariance ON CurrentProductTwelveWeekVariance.EDISID = Sites.EDISID
	LEFT JOIN (
			SELECT	PeriodCacheVarianceInternal.EDISID,  
					0 AS ProductID,
					((SUM(Delivered)/Sites.WeekCount)/8)*@TrafficLightProductVarianceMultiplier AS MultipleTimesDeliveryAverage
			FROM PeriodCacheVarianceInternal
			JOIN #Sites AS Sites ON Sites.EDISID = PeriodCacheVarianceInternal.EDISID
			JOIN Products ON Products.[ID] = PeriodCacheVarianceInternal.ProductID AND IsCask = 1
			LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = PeriodCacheVarianceInternal.EDISID AND Products.[ID] = SiteProductTies.ProductID
			LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = PeriodCacheVarianceInternal.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
			WHERE (PeriodCacheVarianceInternal.WeekCommencing BETWEEN @WeekFromTwelveWeeks AND @CurrentWeekFrom)
			AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1
			GROUP BY PeriodCacheVarianceInternal.EDISID, Sites.WeekCount
	) AS PeriodProductDelivery ON PeriodProductDelivery.EDISID = Sites.EDISID AND PeriodProductDelivery.ProductID = CurrentProductTwelveWeekVariance.ProductID
	WHERE Sites.EDISID NOT IN (SELECT EDISID FROM #Stock)
	
	-- Traffic Light Key: 1 = Red, 2 = Amber, 3 = Green, 6 = Grey (not 4!)
	-- RW: Note that the Grey trigger doesn't work here, since we can have no rows inserted here (if no dispense)
	INSERT INTO #SiteIssues
	(EDISID, TrafficLightNo, TrafficLightDescription)
	SELECT EDISID,
		   CASE TrafficLight WHEN 1 THEN 1
							 WHEN 2 THEN 1
							 WHEN 3 THEN 2
							 WHEN 4 THEN 2
							 WHEN 5 THEN 2 
							 WHEN 6 THEN 2
							 WHEN 7 THEN 3 
							 WHEN 8 THEN 6 END AS TrafficLight,
			CASE TrafficLight WHEN 1 THEN 'Site has < 12 weeks data since online/COT and any product has variance of -22 or less'
							  WHEN 2 THEN 'Variance on any product is (-22 or less) and (20% or more of total 12 week dispense)'
							  WHEN 3 THEN 'Site has < 12 weeks data since online/COT and any product has variance of -11 or less'
							  WHEN 4 THEN 'Variance on any product is (-11 or less) and (10% or more of total 12 week dispense)'
							  WHEN 5 THEN 'Product (dispense total > 1000 gallons in 12 weeks) and (variance is more than 5% of the 12 week dispense total)' 
							  WHEN 6 THEN 'Product variance is > ' + CAST(@TrafficLightProductVarianceMultiplier AS VARCHAR) + ' times the average weekly product delivery'
							  WHEN 7 THEN 'No rules triggered, so defaulting to Green' 
							  WHEN 8 THEN 'No dispense, so defaulting to Grey' END AS [Description]
	FROM
	(
		SELECT	EDISID,
				CASE WHEN SUM(Dispensed) IS NULL THEN 8 ELSE
				MIN(CASE WHEN CurrentVariance <= -22 AND SiteOnline >= @WeekFromTwelveWeeks THEN 1
					 WHEN CurrentVariance <= -22 AND (CurrentVariance *-1) >= TwentyPercentOfDispense THEN 2
					 WHEN CurrentVariance <= -11 AND SiteOnline >= @WeekFromTwelveWeeks THEN 3
					 WHEN CurrentVariance <= -11 AND (CurrentVariance *-1) >= TenPercentOfDispense THEN 4
					 WHEN Dispensed > 1000 AND (CurrentVariance *-1) > FivePercentOfDispense THEN 5
					 WHEN CurrentVariance > MultipleTimesDeliveryAverage AND CurrentVariance > 22 THEN 6
					 ELSE 7 END) END AS TrafficLight
		FROM #VarianceTLData
		GROUP BY EDISID
	) AS VarianceTLData

END

-- SITE ISSUES
DECLARE @Today DATETIME
DECLARE @LastSunday DATETIME
DECLARE @OneWeekAgoWeekFrom DATETIME
DECLARE @ThreeWeeksAgoWeekFrom DATETIME
DECLARE @TwoWeeksAgoWeekFrom DATETIME
DECLARE @OneWeekAgoSunday DATETIME
DECLARE @FiveWeeksAgoWeekFrom DATETIME

SET @Today = GETDATE()
SET @LastSunday = DATEADD(wk, DATEDIFF(wk, 6, @Today), 6)
SET @OneWeekAgoWeekFrom = DATEADD(week, -1, @CurrentWeekFrom)
SET @TwoWeeksAgoWeekFrom = DATEADD(week, -2, @CurrentWeekFrom)
SET @OneWeekAgoSunday = DATEADD(day, -1, @CurrentWeekFrom)
SET @ThreeWeeksAgoWeekFrom = DATEADD(week, -3, @CurrentWeekFrom)
SET @FiveWeeksAgoWeekFrom = DATEADD(week, -5, @CurrentWeekFrom)

CREATE TABLE #SitesTampering(EDISID INT NOT NULL, UNIQUE(EDISID))
CREATE TABLE #SitesNoWater(EDISID INT NOT NULL, UNIQUE(EDISID))
CREATE TABLE #SitesNotDownloading(EDISID INT NOT NULL, UNIQUE(EDISID))
CREATE TABLE #SitesEDISTimeOut(EDISID INT NOT NULL, UNIQUE(EDISID))
CREATE TABLE #SitesMissingShadowRAM(EDISID INT NOT NULL, UNIQUE(EDISID))
CREATE TABLE #SitesMissingData(EDISID INT NOT NULL, UNIQUE(EDISID))
CREATE TABLE #SitesFontSetupsToAction(EDISID INT NOT NULL, UNIQUE(EDISID))
CREATE TABLE #SitesCallsOnHold(EDISID INT NOT NULL, UNIQUE(EDISID))
CREATE TABLE #SitesNotAuditedThreeWeeks(EDISID INT NOT NULL, UNIQUE(EDISID))
CREATE TABLE #SitesStoppedLines(EDISID INT NOT NULL, Reasons VARCHAR(4000), UNIQUE(EDISID))
CREATE TABLE #SitesStoppedLinesReasons(EDISID INT NOT NULL, Reason VARCHAR(256))
CREATE TABLE #SitesCalibrationIssue(EDISID INT NOT NULL, Reasons VARCHAR(4000), UNIQUE(EDISID))
CREATE TABLE #SitesCalibrationIssueReasons(EDISID INT NOT NULL, Reason VARCHAR(256))
CREATE TABLE #SitesNewProductKeg(EDISID INT NOT NULL, Reasons VARCHAR(4000), UNIQUE(EDISID))
CREATE TABLE #SitesNewProductKegReasons(EDISID INT NOT NULL, Reason VARCHAR(256))
CREATE TABLE #SitesNewProductCask(EDISID INT NOT NULL, Reasons VARCHAR(4000), UNIQUE(EDISID))
CREATE TABLE #SitesNewProductCaskReasons(EDISID INT NOT NULL, Reason VARCHAR(256))
CREATE TABLE #SitesClosed(EDISID INT NOT NULL, UNIQUE(EDISID))

-- Sites highlighted as suspected/confirmed tampering
INSERT INTO #SitesTampering
SELECT DISTINCT TamperCases.EDISID
FROM TamperCaseEvents
JOIN TamperCases ON TamperCases.CaseID = TamperCaseEvents.CaseID
JOIN (
	SELECT EDISID, MAX(EventDate) AS MaxCaseDate
	FROM TamperCases
	JOIN TamperCaseEvents ON TamperCaseEvents.CaseID = TamperCases.CaseID
	GROUP BY EDISID
) AS CurrentCases ON CurrentCases.EDISID = TamperCases.EDISID AND CurrentCases.MaxCaseDate = TamperCaseEvents.EventDate
WHERE SeverityID <> 0
GROUP BY TamperCases.EDISID

-- No Dispense On Water Line (Last 4 Weeks)
INSERT INTO #SitesNoWater
SELECT DISTINCT Sites.EDISID
FROM #Sites AS Sites
LEFT JOIN
(
	SELECT Sites.EDISID, CASE WHEN Products.IsWater = 1 THEN SUM(Volume) ELSE NULL END AS Volume
	FROM Sites
	JOIN #Sites AS CurrentSites ON CurrentSites.EDISID = Sites.EDISID
	LEFT JOIN MasterDates ON MasterDates.EDISID = Sites.EDISID AND MasterDates.[Date] BETWEEN @ThreeWeeksAgoWeekFrom AND @To
	LEFT JOIN WaterStack ON WaterStack.WaterID = MasterDates.[ID]
	LEFT JOIN PumpSetup ON PumpSetup.EDISID = CurrentSites.EDISID AND PumpSetup.Pump = WaterStack.Line AND PumpSetup.ValidTo IS NULL
	LEFT JOIN Products ON Products.[ID] = PumpSetup.ProductID AND Products.IsWater = 1
	GROUP BY Sites.EDISID, Products.IsWater
	HAVING Products.IsWater = 1
) AS WaterLineDispense ON WaterLineDispense.EDISID = Sites.EDISID
WHERE WaterLineDispense.Volume IS NULL
AND 
    ((Sites.SystemTypeID NOT IN (2,8)) --Exclude Comtech and edisBOX
     OR 
     (Sites.SystemTypeID = 2 AND Sites.Quality = 0) --Include non-iDraught edisBOX
    )

-- System Not Downloading
INSERT INTO #SitesNotDownloading
SELECT EDISID
FROM #Sites AS Sites
WHERE Hidden = 0
AND LastDownload < @To

-- EDIS Time Out
INSERT INTO #SitesEDISTimeOut
SELECT Sites.EDISID
FROM #Sites AS Sites
JOIN DownloadReports ON DownloadReports.EDISID = Sites.EDISID
WHERE Sites.Hidden = 0
AND DownloadedOn BETWEEN @LastSunday AND @Today
AND ReportText LIKE '%time is out%'
AND Sites.EDISID NOT IN 
(	SELECT EDISID 
	FROM SiteComments 
	JOIN SiteCommentHeadingTypes ON SiteCommentHeadingTypes.[ID] = SiteComments.HeadingType
	WHERE Type = 7
	AND SiteCommentHeadingTypes.[Description] = 'Date/Time Set'
	AND [Date] BETWEEN @LastSunday AND @Today
)
AND Sites.EDISID NOT IN
(
	SELECT Sites.EDISID
	FROM #Sites AS Sites
	JOIN DownloadReports ON DownloadReports.EDISID = Sites.EDISID
	WHERE Sites.Hidden = 0
	AND DownloadedOn BETWEEN @LastSunday AND @Today
	AND ReportText LIKE '%EDIS time set correctly%'
)
GROUP BY Sites.EDISID

-- Double-dispense check for EDIS2: Missing Shadow RAM
INSERT INTO #SitesMissingShadowRAM
SELECT Sites.EDISID
FROM FaultStack  WITH (NOLOCK)
JOIN MasterDates ON FaultStack.FaultID = MasterDates.ID AND MasterDates.[Date] BETWEEN CAST(CAST(YEAR(@WeekFromTwelveWeeks) AS VARCHAR(4)) + '/' + CAST(MONTH(@WeekFromTwelveWeeks) AS VARCHAR(2)) + '/01' AS DATETIME) AND CAST(CAST(YEAR(@To) AS VARCHAR(4)) + '/' + CAST(MONTH(@To) AS VARCHAR(2)) + '/01' AS DATETIME)
JOIN #Sites AS Sites ON Sites.EDISID = MasterDates.EDISID
WHERE (FaultStack.[Description] LIKE 'Shadow RAM Copied%' OR FaultStack.[Description] LIKE 'Data copied to shadow RAM%')
AND Sites.SystemTypeID = 1
GROUP BY Sites.EDISID, Sites.LastDownload
HAVING COUNT(*) < @MonthCount

-- Double-dispense check for EDIS2: DownloadReports check (!)
INSERT INTO #SitesMissingShadowRAM
SELECT LatestSuccess.EDISID AS EDISID
FROM (
	SELECT DownloadReports.EDISID, MAX(DownloadedOn) AS LastSuccess
	FROM DownloadReports
	JOIN #Sites AS Sites ON Sites.EDISID = DownloadReports.EDISID
	WHERE DownloadedOn >= @FourWeeksAgoWeekFrom
	AND ReportText LIKE 'Download successful (up to %'
	AND Sites.SystemTypeID = 1
	GROUP BY DownloadReports.EDISID
) AS LatestSuccess
JOIN (
	SELECT DownloadReports.EDISID, MAX(DownloadedOn) AS LastDD
	FROM DownloadReports
	JOIN #Sites AS Sites ON Sites.EDISID = DownloadReports.EDISID
	WHERE DownloadedOn >= @FourWeeksAgoWeekFrom
	AND ReportText LIKE 'Warning: Potential double-dispense'
	AND Sites.SystemTypeID = 1
	GROUP BY DownloadReports.EDISID
) AS LatestDD ON LatestDD.EDISID = LatestSuccess.EDISID
WHERE DATEDIFF(Second, LastDD, LastSuccess) < 30
AND LatestSuccess.EDISID NOT IN (SELECT EDISID FROM #SitesMissingShadowRAM)

-- Potential Missing Data (edisBOX)
INSERT INTO #SitesMissingData
SELECT MasterDates.EDISID
FROM FaultStack  WITH (NOLOCK)
JOIN MasterDates ON FaultStack.FaultID = MasterDates.ID AND MasterDates.[Date] BETWEEN @WeekFromTwelveWeeks AND @To
JOIN #Sites AS Sites ON Sites.EDISID = MasterDates.EDISID
WHERE FaultStack.[Description] LIKE 'Warning: Possibility of gap%'
AND Sites.SystemTypeID = 2
AND Sites.Hidden = 0
AND Sites.Quality = 0
GROUP BY MasterDates.EDISID

-- Font Setup To Action
INSERT INTO #SitesFontSetupsToAction
SELECT DISTINCT Sites.EDISID
FROM #Sites AS Sites
JOIN ProposedFontSetups ON ProposedFontSetups.EDISID = Sites.EDISID
WHERE ProposedFontSetups.Completed = 0
AND ProposedFontSetups.Available = 1
AND Sites.Hidden = 0

-- Service Call - On Hold
INSERT INTO #SitesCallsOnHold
SELECT DISTINCT Calls.EDISID
FROM CallStatusHistory
JOIN
(
SELECT CallID, MAX(ChangedOn) AS LatestChangeDate
FROM CallStatusHistory
GROUP BY CallID
) AS LatestCallChanges ON LatestCallChanges.CallID = CallStatusHistory.CallID
JOIN Calls ON Calls.[ID] = CallStatusHistory.CallID
AND LatestCallChanges.LatestChangeDate = CallStatusHistory.ChangedOn
WHERE CallStatusHistory.StatusID = 2

-- Site not audited for 3 (now configurable!) weeks
INSERT INTO #SitesNotAuditedThreeWeeks
SELECT Sites.EDISID
FROM #Sites AS Sites
LEFT JOIN SiteAudits ON SiteAudits.EDISID = Sites.EDISID 
					AND (SiteAudits.[TimeStamp] BETWEEN DATEADD(week, -@NotAuditedForWeeks, @Today) AND @Today)
					AND SiteAudits.AuditType = 1
WHERE Hidden = 0
GROUP BY Sites.EDISID
HAVING COUNT(SiteAudits.EDISID) = 0

-- Stopped line(s)
DECLARE @Reason VARCHAR(8000) 
INSERT INTO #SitesStoppedLinesReasons (EDISID, Reason)
SELECT Sites.EDISID, COALESCE(@Reason + ';', '') + CAST(Last2WeeksDispense.Pump AS VARCHAR) + ',' + CAST(ProductID AS VARCHAR) + ',' + CAST(Product AS VARCHAR)
FROM #Sites AS Sites
LEFT JOIN (	SELECT Sites.EDISID, Pump, SUM(Quantity) AS Volume
			FROM DLData
			JOIN MasterDates ON MasterDates.[ID] = DLData.DownloadID AND EDISID IN (SELECT EDISID FROM #Sites)
			JOIN #Sites AS Sites ON Sites.EDISID = MasterDates.EDISID
			WHERE MasterDates.[Date] BETWEEN @TwoWeeksAgoWeekFrom AND @OneWeekAgoSunday
			GROUP BY Sites.EDISID, Pump
			HAVING SUM(Quantity) >= 4) AS Last2WeeksDispense 
    ON Last2WeeksDispense.EDISID = Sites.EDISID
LEFT JOIN (	SELECT Sites.EDISID, Pump, SUM(Quantity) AS Volume
			FROM DLData
			JOIN MasterDates ON MasterDates.[ID] = DLData.DownloadID AND EDISID IN (SELECT EDISID FROM #Sites)
			JOIN #Sites AS Sites ON Sites.EDISID = MasterDates.EDISID
			WHERE MasterDates.[Date] BETWEEN @CurrentWeekFrom AND @To
			GROUP BY Sites.EDISID, Pump) AS LastWeeksDispense 
    ON LastWeeksDispense.EDISID = Last2WeeksDispense.EDISID
	AND LastWeeksDispense.Pump = Last2WeeksDispense.Pump
LEFT JOIN ( SELECT EDISID, Pump, ProductID, Products.[Description] AS Product
            FROM PumpSetup
            JOIN Products ON Products.ID = PumpSetup.ProductID
            WHERE InUse = 1
            AND ValidTo IS NULL
        ) AS PumpSetup 
    ON PumpSetup.EDISID = Sites.EDISID
    AND PumpSetup.Pump = Last2WeeksDispense.Pump
WHERE Sites.Hidden = 0
AND Last2WeeksDispense.Volume IS NOT NULL
AND LastWeeksDispense.Volume IS NULL

INSERT INTO #SitesStoppedLines (EDISID, Reasons)
SELECT  EDISID, SUBSTRING
    (
        (SELECT ';' + Reason 
        FROM #SitesStoppedLinesReasons WHERE 
            (EDISID = Results.EDISID) 
        FOR XML PATH 
            ('')
        )
    ,2,4000
    ) AS ResultValues
FROM #SitesStoppedLinesReasons Results
GROUP BY EDISID

-- Calibration issue (over/under recording)
-- DMG: This bit is *really* slow. Can it be improved at all? 95% of the query time is taken up here!
-- RW: Well, I've disabled the extra dispense calculations for key lines, so it might be faster!
INSERT INTO #SitesCalibrationIssueReasons (EDISID, Reason)
SELECT DISTINCT 
    Sites.EDISID, 
    --LastWeeksDispense.Volume / 8 AS LatestWeekVolume,
    --(Last4WeeksDispense.AvgVolume / Last4WeeksDispenseCount.DispenseWeekCount) / 8 AS Previous4WeekVolumeAverage,
    COALESCE(@Reason + ';', '') + CAST(Last4WeeksDispense.Pump AS VARCHAR) + ',' + CAST(PumpSetup.ProductID AS VARCHAR) + ',' + CAST(PumpSetup.Product AS VARCHAR)
FROM #Sites AS Sites
LEFT JOIN (	SELECT Sites.EDISID, Pump, Product AS ProductID, CAST(SUM(Quantity) AS FLOAT) AS AvgVolume
			FROM DLData
			INNER JOIN MasterDates ON MasterDates.[ID] = DLData.DownloadID
			INNER JOIN #Sites AS Sites ON Sites.EDISID = MasterDates.EDISID
			WHERE [Date] BETWEEN @FourWeeksAgoWeekFrom AND @OneWeekAgoSunday
			GROUP BY Sites.EDISID, Pump, Product) AS Last4WeeksDispense ON Last4WeeksDispense.EDISID = Sites.EDISID
LEFT JOIN (	SELECT Sites.EDISID, Pump, Product AS ProductID, CAST(SUM(Quantity) AS FLOAT) AS Volume
			FROM DLData
			INNER JOIN MasterDates ON MasterDates.[ID] = DLData.DownloadID
			INNER JOIN #Sites AS Sites ON Sites.EDISID = MasterDates.EDISID
			WHERE [Date] BETWEEN @CurrentWeekFrom AND @To
			GROUP BY Sites.EDISID, Pump, Product) AS LastWeeksDispense ON LastWeeksDispense.EDISID = Last4WeeksDispense.EDISID
                                                AND LastWeeksDispense.Pump = Last4WeeksDispense.Pump
                                                AND LastWeeksDispense.ProductID = Last4WeeksDispense.ProductID
LEFT JOIN ( SELECT Sites.EDISID, Pump, Product AS ProductID, COUNT(DISTINCT DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, [Date]) + 1, [Date]))) AS DispenseWeekCount
			FROM DLData
			INNER JOIN MasterDates ON MasterDates.[ID] = DLData.DownloadID
			INNER JOIN #Sites AS Sites ON Sites.EDISID = MasterDates.EDISID
			WHERE [Date] BETWEEN @FourWeeksAgoWeekFrom AND @OneWeekAgoSunday
			GROUP BY Sites.EDISID, Pump, Product) AS Last4WeeksDispenseCount ON Last4WeeksDispenseCount.EDISID = Last4WeeksDispense.EDISID
															AND Last4WeeksDispenseCount.Pump = Last4WeeksDispense.Pump
															AND Last4WeeksDispenseCount.ProductID = Last4WeeksDispense.ProductID
-- RW: removed 'key tap only' functionality
INNER JOIN ( SELECT EDISID, Pump, ProductID, Products.[Description] AS Product
            FROM PumpSetup
            JOIN Products ON Products.ID = PumpSetup.ProductID
            WHERE InUse = 1
            AND ValidTo IS NULL
        ) AS PumpSetup 
    ON PumpSetup.EDISID = Sites.EDISID
    AND PumpSetup.Pump = Last4WeeksDispenseCount.Pump --KeyPumps.Pump
    AND PumpSetup.ProductID = Last4WeeksDispenseCount.ProductID --KeyPumps.ProductID
-- RW: rule change relating to key vs. all taps
--     old: flag up if [current week] 40% > or < [a] 
--     new: Flag up if ([previous 4wk average] <50 gallons and [current week] > 500 gallons)  *OR*  ([previous 4wk average] >50 gallons and [current week] 80% > [previous 4wk average] )
WHERE Sites.Hidden = 0
AND (
		(Last4WeeksDispense.AvgVolume/Last4WeeksDispenseCount.DispenseWeekCount > 50*8) AND (LastWeeksDispense.Volume/(Last4WeeksDispense.AvgVolume/Last4WeeksDispenseCount.DispenseWeekCount)>1.8)
		OR
		(Last4WeeksDispense.AvgVolume/Last4WeeksDispenseCount.DispenseWeekCount < 50*8) AND (LastWeeksDispense.Volume > 500*8)
        
    )

INSERT INTO #SitesCalibrationIssue (EDISID, Reasons)
SELECT  EDISID, SUBSTRING
    (
        (SELECT ';' + Reason 
        FROM #SitesCalibrationIssueReasons WHERE 
            (EDISID = Results.EDISID) 
        FOR XML PATH 
            ('')
        )
    ,2,4000
    ) AS ResultValues
FROM #SitesCalibrationIssueReasons Results
GROUP BY EDISID


---- New Product - Keg
INSERT INTO #SitesNewProductKegReasons (EDISID, Reason)
--SELECT DISTINCT Sites.EDISID
SELECT Sites.EDISID, COALESCE(@Reason + ';', '') + '?,' + CAST(Products.ID AS VARCHAR) + ',' + CAST(Products.[Description] AS VARCHAR)
FROM #Sites AS Sites
JOIN PeriodCacheVarianceInternal ON PeriodCacheVarianceInternal.EDISID = Sites.EDISID 
						AND PeriodCacheVarianceInternal.WeekCommencing = @CurrentWeekFrom
						AND PeriodCacheVarianceInternal.Delivered > 0
JOIN Products ON Products.[ID] = PeriodCacheVarianceInternal.ProductID
LEFT JOIN
(
	SELECT PumpSetup.EDISID, COALESCE(CASE WHEN PGP.IsPrimary = 1 AND TypeID = 1 THEN PGP.ProductID ELSE NULL END, Products.[ID]) AS ProductID
	FROM PumpSetup
	JOIN #Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
	JOIN Products ON Products.[ID] = PumpSetup.ProductID
	LEFT JOIN ProductGroupProducts ON ProductGroupProducts.ProductID = Products.[ID]
	LEFT JOIN ProductGroups ON ProductGroups.[ID] = ProductGroupProducts.ProductGroupID AND TypeID = 1
	LEFT JOIN ProductGroupProducts AS PGP ON PGP.ProductGroupID = ProductGroups.ID
	WHERE ValidTo IS NULL
	GROUP BY PumpSetup.EDISID, COALESCE(CASE WHEN PGP.IsPrimary = 1 AND TypeID = 1 THEN PGP.ProductID ELSE NULL END, Products.[ID])
) AS ActivePumps ON ActivePumps.EDISID = PeriodCacheVarianceInternal.EDISID AND ActivePumps.ProductID = PeriodCacheVarianceInternal.ProductID
LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = PeriodCacheVarianceInternal.EDISID AND Products.[ID] = SiteProductTies.ProductID
LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = PeriodCacheVarianceInternal.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
WHERE ActivePumps.EDISID IS NULL
AND (Products.IsCask = 0 AND Products.IsMetric = 0)
AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1

INSERT INTO #SitesNewProductKeg (EDISID, Reasons)
SELECT  EDISID, SUBSTRING
    (
        (SELECT ';' + Reason 
        FROM #SitesNewProductKegReasons WHERE 
            (EDISID = Results.EDISID) 
        FOR XML PATH 
            ('')
        )
    ,2,4000
    ) AS ResultValues
FROM #SitesNewProductKegReasons Results
GROUP BY EDISID

-- New Product - Cask
INSERT INTO #SitesNewProductCaskReasons (EDISID, Reason)
--SELECT DISTINCT Sites.EDISID
SELECT Sites.EDISID, COALESCE(@Reason + ';', '') + '?,' + CAST(Products.ID AS VARCHAR) + ',' + CAST(Products.[Description] AS VARCHAR)
FROM #Sites AS Sites
JOIN PeriodCacheVarianceInternal ON PeriodCacheVarianceInternal.EDISID = Sites.EDISID 
						AND PeriodCacheVarianceInternal.WeekCommencing = @CurrentWeekFrom
						AND PeriodCacheVarianceInternal.Delivered > 0
JOIN Products ON Products.[ID] = PeriodCacheVarianceInternal.ProductID
LEFT JOIN
(
	SELECT PumpSetup.EDISID, COALESCE(CASE WHEN PGP.IsPrimary = 1 AND TypeID = 1 THEN PGP.ProductID ELSE NULL END, Products.[ID]) AS ProductID
	FROM PumpSetup
	JOIN #Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
	JOIN Products ON Products.[ID] = PumpSetup.ProductID
	LEFT JOIN ProductGroupProducts ON ProductGroupProducts.ProductID = Products.[ID]
	LEFT JOIN ProductGroups ON ProductGroups.[ID] = ProductGroupProducts.ProductGroupID AND TypeID = 1
	LEFT JOIN ProductGroupProducts AS PGP ON PGP.ProductGroupID = ProductGroups.ID
	WHERE ValidTo IS NULL
	GROUP BY PumpSetup.EDISID, COALESCE(CASE WHEN PGP.IsPrimary = 1 AND TypeID = 1 THEN PGP.ProductID ELSE NULL END, Products.[ID])
) AS ActivePumps ON ActivePumps.EDISID = PeriodCacheVarianceInternal.EDISID AND ActivePumps.ProductID = PeriodCacheVarianceInternal.ProductID
LEFT JOIN
(
	SELECT EDISID, ProductID, SUM(Delivered) AS Delivered
	FROM PeriodCacheVarianceInternal 
	WHERE PeriodCacheVarianceInternal.WeekCommencing BETWEEN @ThreeWeeksAgoWeekFrom AND @OneWeekAgoWeekFrom
	GROUP BY EDISID, ProductID
) AS PeriodCacheVarianceInternalPrevious3Weeks ON PeriodCacheVarianceInternalPrevious3Weeks.EDISID = Sites.EDISID AND PeriodCacheVarianceInternalPrevious3Weeks.ProductID = Products.[ID]
LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = PeriodCacheVarianceInternal.EDISID AND Products.[ID] = SiteProductTies.ProductID
LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = PeriodCacheVarianceInternal.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
WHERE ActivePumps.EDISID IS NULL
AND (PeriodCacheVarianceInternalPrevious3Weeks.Delivered IS NULL OR PeriodCacheVarianceInternalPrevious3Weeks.Delivered = 0)
AND Products.IsCask = 1
AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1

INSERT INTO #SitesNewProductCask (EDISID, Reasons)
SELECT  EDISID, SUBSTRING
    (
        (SELECT ';' + Reason 
        FROM #SitesNewProductCaskReasons WHERE 
            (EDISID = Results.EDISID) 
        FOR XML PATH 
            ('')
        )
    ,2,4000
    ) AS ResultValues
FROM #SitesNewProductCaskReasons Results
GROUP BY EDISID

---- Sites marked as closed
INSERT INTO #SitesClosed
SELECT DISTINCT Sites.EDISID
FROM #Sites AS Sites
LEFT JOIN (
	SELECT EDISID, SUM(Delivered) AS Delivered
	FROM PeriodCacheVarianceInternal
	WHERE WeekCommencing = @CurrentWeekFrom
	GROUP BY EDISID
) AS WeekDelivery ON WeekDelivery.EDISID = Sites.EDISID
LEFT JOIN (
	SELECT Sites.EDISID, SUM(Quantity) AS Dispensed
	FROM DLData
	JOIN MasterDates ON MasterDates.[ID] = DLData.DownloadID
	JOIN #Sites AS Sites ON Sites.EDISID = MasterDates.EDISID
	WHERE [Date] BETWEEN @CurrentWeekFrom AND @To
	GROUP BY Sites.EDISID
) AS WeekDispense ON WeekDispense.EDISID = Sites.EDISID
WHERE Sites.Closed = 1
AND ((WeekDelivery.Delivered IS NOT NULL AND WeekDelivery.Delivered > 0) OR (WeekDispense.Dispensed IS NOT NULL AND WeekDispense.Dispensed > 0))

UPDATE dbo.AuditExceptions
SET ValidTo = GETDATE()
WHERE EDISID IN (SELECT EDISID FROM #Sites)
AND ValidTo IS NULL

INSERT INTO dbo.AuditExceptions
(EDISID, ValidTo, Tampering, NoWater, NotDownloading, EDISTimeOut, MissingShadowRAM, MissingData,
FontSetupsToAction, CallOnHold, NotAuditedInThreeWeeks, StoppedLines, CalibrationIssue,
NewProductKeg, NewProductCask, ClosedWithDelivery, TrafficLightColour, TrafficLightFailReason,
RefreshedBy, RefreshedAllSites, [From], [To], RefreshedOn, CurrentTrafficLightColour,
StoppedLineReasons, CalibrationIssueReasons, NewProductKegReasons, NewProductCaskReasons, ClosedOrMissingShadowRAM)
SELECT	Sites.EDISID,
		NULL,
		CASE WHEN SitesTampering.EDISID IS NOT NULL AND Sites.Closed = 0 THEN 1 ELSE 0 END AS Tampering,
		CASE WHEN SitesNoWater.EDISID IS NOT NULL AND Sites.Closed = 0 THEN 1 ELSE 0 END AS NoWater,
		CASE WHEN SitesNotDownloading.EDISID IS NOT NULL AND Sites.Closed = 0 THEN 1 ELSE 0 END AS NotDownloading,
		CASE WHEN SitesEDISTimeOut.EDISID IS NOT NULL AND Sites.Closed = 0 THEN 1 ELSE 0 END AS EDISTimeOut,
		CASE WHEN SitesMissingShadowRAM.EDISID IS NOT NULL AND Sites.Closed = 0 THEN 1 ELSE 0 END AS MissingShadowRAM,
		CASE WHEN SitesMissingData.EDISID IS NOT NULL AND Sites.Closed = 0 THEN 1 ELSE 0 END AS MissingData,
		CASE WHEN SitesFontSetupsToAction.EDISID IS NOT NULL AND Sites.Closed = 0 THEN 1 ELSE 0 END AS FontSetupsToAction,
		CASE WHEN SitesCallsOnHold.EDISID IS NOT NULL AND Sites.Closed = 0 THEN 1 ELSE 0 END AS CallOnHold,
		CASE WHEN SitesNotAuditedThreeWeeks.EDISID IS NOT NULL AND Sites.Closed = 0 THEN 1 ELSE 0 END AS NotAuditedInThreeWeeks,
		CASE WHEN SitesStoppedLines.EDISID IS NOT NULL AND Sites.Closed = 0 THEN 1 ELSE 0 END AS StoppedLines,
		CASE WHEN SitesCalibrationIssue.EDISID IS NOT NULL AND Sites.Closed = 0 THEN 1 ELSE 0 END AS CalibrationIssue,
		CASE WHEN SitesNewProductKeg.EDISID IS NOT NULL AND Sites.Closed = 0 THEN 1 ELSE 0 END AS NewProductKeg,
		CASE WHEN SitesNewProductCask.EDISID IS NOT NULL AND Sites.Closed = 0 THEN 1 ELSE 0 END AS NewProductCask,
		CASE WHEN SitesClosed.EDISID IS NOT NULL THEN 1 ELSE 0 END AS Closed,
		/* RW: This was setting 'blue', which is nonsense, so I've changed it to 'grey' */
		/* RW: Note that this is how we deal with zero dispense and the default to grey */
		CASE WHEN SiteIssues.EDISID IS NULL OR Sites.Closed = 1 THEN 6 ELSE SiteIssues.TrafficLightNo END AS TrafficLightColour,
		CASE WHEN SiteIssues.EDISID IS NULL OR Sites.Closed = 1 THEN 'Closed or zero dispense, so defaulting to Grey' ELSE SiteIssues.TrafficLightDescription END AS TrafficLightDescription,
		SUSER_NAME(),
		CASE WHEN @OnlyCurrentUsersSites = 1 THEN 0 ELSE 1 END,
		@WeekFromTwelveWeeks,
		@To,
		GETDATE(),
		Sites.TrafficLight,
		CASE WHEN SitesStoppedLines.EDISID IS NOT NULL AND Sites.Closed = 0 THEN SitesStoppedLines.Reasons ELSE NULL END AS StoppedLinesReasons,
		CASE WHEN SitesCalibrationIssue.EDISID IS NOT NULL AND Sites.Closed = 0 THEN SitesCalibrationIssue.Reasons ELSE NULL END AS CalibrationIssueReasons,
		CASE WHEN SitesNewProductKeg.EDISID IS NOT NULL AND Sites.Closed = 0 THEN SitesNewProductKeg.Reasons ELSE NULL END AS NewProductKegReasons,
		CASE WHEN SitesNewProductCask.EDISID IS NOT NULL AND Sites.Closed = 0 THEN SitesNewProductCask.Reasons ELSE NULL END AS NewProductCaskReasons,
		CASE WHEN SitesClosed.EDISID IS NOT NULL THEN 1 ELSE CASE WHEN SitesMissingShadowRAM.EDISID IS NOT NULL AND Sites.Closed = 0 THEN 1 ELSE 0 END END AS ClosedOrMissingShadowRAM
		/* RW: New functionality to track product(s) responsible for TL suggestion */
		--CASE WHEN SiteIssues.EDISID IS NULL OR Sites.Closed = 1 THEN NULL ELSE SiteIssues.TrafficLightFailReasonProducts END AS TrafficLightFailReasonProducts
FROM #Sites AS Sites
LEFT JOIN #SitesTampering AS SitesTampering ON SitesTampering.EDISID = Sites.EDISID
LEFT JOIN #SitesNoWater AS SitesNoWater ON SitesNoWater.EDISID = Sites.EDISID
LEFT JOIN #SitesNotDownloading AS SitesNotDownloading ON SitesNotDownloading.EDISID = Sites.EDISID
LEFT JOIN #SitesEDISTimeOut AS SitesEDISTimeOut ON SitesEDISTimeOut.EDISID = Sites.EDISID
LEFT JOIN #SitesMissingShadowRAM AS SitesMissingShadowRAM ON SitesMissingShadowRAM.EDISID = Sites.EDISID
LEFT JOIN #SitesMissingData AS SitesMissingData ON SitesMissingData.EDISID = Sites.EDISID
LEFT JOIN #SitesFontSetupsToAction AS SitesFontSetupsToAction ON SitesFontSetupsToAction.EDISID = Sites.EDISID
LEFT JOIN #SitesCallsOnHold AS SitesCallsOnHold ON SitesCallsOnHold.EDISID = Sites.EDISID
LEFT JOIN #SitesNotAuditedThreeWeeks AS SitesNotAuditedThreeWeeks ON SitesNotAuditedThreeWeeks.EDISID = Sites.EDISID
LEFT JOIN #SitesStoppedLines AS SitesStoppedLines ON SitesStoppedLines.EDISID = Sites.EDISID
LEFT JOIN #SitesCalibrationIssue AS SitesCalibrationIssue ON SitesCalibrationIssue.EDISID = Sites.EDISID
LEFT JOIN #SitesNewProductKeg AS SitesNewProductKeg ON SitesNewProductKeg.EDISID = Sites.EDISID
LEFT JOIN #SitesNewProductCask AS SitesNewProductCask ON SitesNewProductCask.EDISID = Sites.EDISID
LEFT JOIN #SitesClosed AS SitesClosed ON SitesClosed.EDISID = Sites.EDISID
LEFT JOIN #SiteIssues AS SiteIssues ON SiteIssues.EDISID = Sites.EDISID
ORDER BY EDISID

DROP TABLE #StockTLRules
DROP TABLE #TrendsTLRules
DROP TABLE #ProductLastDispense
DROP TABLE #SiteProductTrends
DROP TABLE #StockTLData
DROP TABLE #TrendsTLData
DROP TABLE #VarianceTLData
DROP TABLE #PeriodCacheVarianceInternal
DROP TABLE #CumulativeVariance
DROP TABLE #PeriodAdjustedVariance
DROP TABLE #PeriodStockAdjustedVariance
DROP TABLE #SitesTampering
DROP TABLE #SitesNoWater
DROP TABLE #SitesNotDownloading
DROP TABLE #SitesEDISTimeOut
DROP TABLE #SitesMissingShadowRAM
DROP TABLE #SitesMissingData
DROP TABLE #SitesFontSetupsToAction
DROP TABLE #SitesCallsOnHold
DROP TABLE #SitesNotAuditedThreeWeeks
DROP TABLE #SitesStoppedLines
DROP TABLE #SitesStoppedLinesReasons
DROP TABLE #SitesCalibrationIssue
DROP TABLE #SitesCalibrationIssueReasons
DROP TABLE #SitesNewProductKeg
DROP TABLE #SitesNewProductKegReasons
DROP TABLE #SitesNewProductCask
DROP TABLE #SitesNewProductCaskReasons
DROP TABLE #SitesClosed
DROP TABLE #Sites
DROP TABLE #SiteIssues
DROP TABLE #Stock

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[RefreshAuditExceptions] TO PUBLIC
    AS [dbo];

