CREATE PROCEDURE [dbo].[ExceptionTrafficLightTrends]
(
	@EDISID int = NULL
)
AS

SET DATEFIRST 1;

DECLARE @CurrentWeek	DATETIME = GETDATE()
SET @CurrentWeek = DATEADD(dd, 1-DATEPART(dw, @CurrentWeek), @CurrentWeek)

DECLARE @CurrentWeekFrom		DATETIME
DECLARE @To						DATETIME
DECLARE @Today					DATETIME
DECLARE @UseStock BIT

SET @CurrentWeekFrom = @CurrentWeek
SET @To = DATEADD(day, 6, @CurrentWeekFrom)
DECLARE @WeekFromTwelveWeeks datetime = DATEADD(week, -12, @CurrentWeekFrom)
DECLARE @MonthCount int = DATEDIFF(MONTH, CAST(CAST(YEAR(@WeekFromTwelveWeeks) AS VARCHAR(4)) + '/' + CAST(MONTH(@WeekFromTwelveWeeks) AS VARCHAR(2)) + '/01' AS DATETIME), CAST(CAST(YEAR(@To) AS VARCHAR(4)) + '/' + CAST(MONTH(@To) AS VARCHAR(2)) + '/01' AS DATETIME)) + 1

SELECT @UseStock = ShowApproxVarianceStock
FROM [EDISSQL1\SQL1].ServiceLogger.dbo.EDISDatabases
WHERE [Name] = DB_NAME()

CREATE TABLE #Sites(EDISID INT, Hidden BIT, LastDownload datetime, SystemTypeID int, SiteOnline datetime, WeekCount int, TrafficLight int)

INSERT INTO #Sites
(EDISID, Hidden, LastDownload, SystemTypeID, SiteOnline, WeekCount, TrafficLight)
SELECT Sites.EDISID, Hidden, LastDownload, SystemTypeID, SiteOnline, DATEDIFF(week, CASE WHEN SiteOnline > @WeekFromTwelveWeeks THEN SiteOnline ELSE @WeekFromTwelveWeeks END, @CurrentWeekFrom) + 1, SiteRankingCurrent.[Audit]
FROM Sites
LEFT JOIN SiteRankingCurrent ON SiteRankingCurrent.EDISID = Sites.EDISID
WHERE Hidden = 0
AND (@EDISID IS NULL OR Sites.EDISID = @EDISID)
AND SiteOnline <= @To
AND [Status] IN (1, 3)

CREATE TABLE #SiteIssues(EDISID INT, TrafficLightNo INT, TrafficLightDescription VARCHAR(4000))
CREATE TABLE #TrendsTLRules(EDISID INT, ProductID INT, Product VARCHAR(500), Dispensed FLOAT, RuleTriggered FLOAT, NewTrafficLight INT, RuleDescription VARCHAR(4000))
CREATE TABLE #TrendsTLData(EDISID INT, ProductID INT, SiteOnline DATETIME, CurrentVariance FLOAT, Trend FLOAT, Dispensed FLOAT, TwentyPercentOfDispense FLOAT, TenPercentOfDispense FLOAT, FivePercentOfDispense FLOAT, MultipleTimesDeliveryAverage FLOAT)
CREATE TABLE #PeriodCacheVarianceInternal(EDISID INT, ProductID INT, WeekCommencing DATETIME, Variance FLOAT)
CREATE TABLE #Stock(EDISID INT, [Date] DATETIME, StockMonday DATETIME)
CREATE TABLE #CumulativeVariance(EDISID INT, ProductID INT, WeekCommencing DATETIME, Variance FLOAT, CumulativeVariance FLOAT, IsPurple BIT)
CREATE TABLE #SiteProductTrends(EDISID INT, ProductID INT, Trend FLOAT)

DECLARE @TrafficLightProductVarianceMultiplier INT
SET @TrafficLightProductVarianceMultiplier = (SELECT TrafficLightProductVarianceMultiplier FROM AuditExceptionConfiguration)

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

DECLARE @CurEDISID INT
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
FETCH NEXT FROM curSiteProductVarianceWeeks INTO @CurEDISID, @ProductID, @WeekCommencing, @Variance, @CumulativeVariance, @IsPurple

WHILE @@FETCH_STATUS = 0
BEGIN

	IF @PreviousEDISID IS NULL
	BEGIN
		SET @PreviousEDISID = @CurEDISID
		SET @PreviousProductID = @ProductID
		SET @PreviousVariance = @Variance
		SET @PreviousCumulativeVariance = @CumulativeVariance
		SET @PreviousIsPurple = @IsPurple
		
	END
			
	IF (@PreviousProductID <> @ProductID OR @PreviousEDISID <> @CurEDISID) AND (@ProductTrendTotal <> 0 OR @CurrentVarianceTotal <> 0 )
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
		
	SET @PreviousEDISID = @CurEDISID
	SET @PreviousProductID = @ProductID
	SET @PreviousVariance = @Variance
	SET @PreviousCumulativeVariance = @CumulativeVariance
	SET @PreviousIsPurple = @IsPurple
	SET @PreviousVarianceTotal = @CurrentVarianceTotal
		
	FETCH NEXT FROM curSiteProductVarianceWeeks INTO @CurEDISID, @ProductID, @WeekCommencing, @Variance, @CumulativeVariance, @IsPurple

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


SELECT	si.EDISID,
	(CASE
		WHEN si.TrafficLightNo = 1 THEN 'Red'
		WHEN si.TrafficLightNo = 2 THEN 'Amber'
		WHEN si.TrafficLightNo = 3 THEN 'Green'
		WHEN si.TrafficLightNo = 6 THEN 'Grey'
	END) + ' - ' + ISNULL(si.TrafficLightDescription,'No Issue') AS Detail
FROM	#SiteIssues si

DROP TABLE #SiteIssues
DROP TABLE #TrendsTLRules
DROP TABLE #TrendsTLData
DROP TABLE #PeriodCacheVarianceInternal
DROP TABLE #Stock
DROP TABLE #CumulativeVariance
DROP TABLE #SiteProductTrends


DROP TABLE #Sites

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ExceptionTrafficLightTrends] TO PUBLIC
    AS [dbo];

