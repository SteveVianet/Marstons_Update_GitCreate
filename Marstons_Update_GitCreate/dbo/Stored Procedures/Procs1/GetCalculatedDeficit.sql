CREATE PROCEDURE [dbo].[GetCalculatedDeficit]
(
	@From 						DATETIME,
	@To							DATETIME,
	@PeriodLength				INT = 4,
	@LowThresholdPercentage		INT = 10,
	@PeriodID					VARCHAR(20),
	@IncludeStockAdjusments		BIT = 0,
	@GroupByProduct				BIT = 1,
	@GroupByCategory			BIT = 1,
	@CaskDispenseMultiplier		FLOAT = 1.0,
	@OnlyUseAuditedData			BIT = 1
)
AS



--TESTING
--DECLARE @From 						DATETIME = '2014-10-20'
--DECLARE @To							DATETIME = '2014-11-10'
--DECLARE @PeriodLength					INT = 4
--DECLARE @LowThresholdPercentage		INT = 0.10
--DECLARE @PeriodID						VARCHAR(20) = '1415PD03'
--DECLARE @IncludeStockAdjusments		BIT = 0
--DECLARE @GroupByProduct				BIT = 0
--DECLARE @GroupByCategory				BIT = 0
--DECLARE @CaskDispenseMultiplier		FLOAT = 1
--DECLARE @OnlyUseAuditedData			BIT = 1
--/TESTING


DECLARE @FirstDayOfWeek				INT = 1
SET DATEFIRST @FirstDayOfWeek

DECLARE @DatabaseID	VARCHAR(3)
SELECT @DatabaseID = PropertyValue
FROM Configuration
WHERE PropertyName = 'Service Owner ID'


--Make sure that the category parameter is in sync with the product one. 
--Can't report on the product without also reporting on the category
IF @GroupByProduct = 1
BEGIN
	SET @GroupByCategory = 1
END

--Move dates to start of week
SET @From = DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, @From) + 1, @From)))
SET @To = DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, @To) + 1, @To)))

--Be aware that some calculations in this process are concerned with the report range (@From and @To)
--But some are in relation to the period which is from @PeriodCutoff to @To

--Get the start date of the preiod (using the @To date and the @PeriodLength)
DECLARE @PeriodCutoff DATETIME
SET @PeriodCutoff = DATEADD(dd, (-7*(@PeriodLength-1)), @To)

--These cutoff dates are used later after we check for "Low Dispense"
DECLARE @4WeekCutoff DATETIME
DECLARE @2WeekCutoff DATETIME
SET @4WeekCutoff = DATEADD(ww, -4, @PeriodCutoff)
SET @2WeekCutoff = DATEADD(ww, -2, @PeriodCutoff)


CREATE TABLE #PeriodAdjustedVariance (	EDISID INT, 
										CategoryID INT, 
										ProductID INT, 
										WeekCommencing DATETIME, 
										FullWeekDispensed FLOAT,
										Dispensed FLOAT, 
										Delivered FLOAT, 
										Variance FLOAT, 
										StockDate DATETIME)
										
CREATE TABLE #DateAdjustedVariance (EDISID INT, 
									CategoryID INT, 
									ProductID INT, 
									WC DATETIME, 
									Delivered FLOAT, 
									Dispense FLOAT, 
									Variance FLOAT, 
									LowDispenseThreshold INT,
									StockDate DATETIME, 
									LowDispDate DATETIME, 
									AdjustedStartDate DATETIME,
									InsufficientData BIT)
									
CREATE TABLE #CumulativeVariance (	EDISID INT, 
									CategoryID INT, 
									ProductID INT, 
									WC DATETIME, 
									Delivered FLOAT, 
									Dispense FLOAT, 
									Variance FLOAT,
									CumulativeVariance FLOAT, 
									LowDispenseThreshold INT, 
									InsufficientData BIT, 
									AdjustedStartDate DATETIME)
									

--Get data from PeriodCacheVariance but ensuring that Stock adjusted figures that fall within current period are ignored
--If @IncludeStockAdjusments is false then we ignore all stock adjusted figures and stock dates
--From now on when using this temp table we can refer to Dispensed/Delivered/Variance without worrying about adjusting figures		
--This SELECT is the only point in the SP that the PeriodCacheVariance table is read.							
INSERT INTO #PeriodAdjustedVariance (EDISID, CategoryID, ProductID, WeekCommencing, FullWeekDispensed, Dispensed, Delivered, Variance, StockDate)
SELECT EDISID, CategoryID, ProductID, WeekCommencing, 
SUM(FullWeekDispensed) AS FullWeekDispensed, --We include this value so we can get the unadjusted dispense later when checking for low dispense
SUM(StockAdjustedDispensed) AS Dispensed, --This may or may not be stock adjusted
SUM(StockAdjustedDelivered) AS Delivered, --This may or may not be stock adjusted
SUM(StockAdjustedVariance) AS Variance, --This may or may not be stock adjusted
StockDate
FROM (
	SELECT EDISID, 
			--If we are grouping by product and the product is cask then we set the ProductID to -1
			--This means that we need to bodge the CategoryID to -1 as well otherwise it messes with the grouping
			CASE @GroupByCategory WHEN 1 THEN 
				CASE @GroupByProduct WHEN 1 THEN
					CASE IsCask WHEN 1 THEN -1 ELSE Products.CategoryID END
				ELSE 
					Products.CategoryID 
				END
			ELSE NULL END AS CategoryID, 
			--Set any cask products to ProductID -1 so we can show them as consolidated cask
			CASE @GroupByProduct WHEN 1 THEN 
				CASE IsCask WHEN 1 THEN -1 ELSE ProductID END 
			ELSE NULL END AS ProductID, 
			WeekCommencing,
			
			CASE WHEN IsCask = 1 THEN Dispensed * @CaskDispenseMultiplier ELSE Dispensed END AS FullWeekDispensed,
			CASE WHEN IsCask = 1 THEN PeriodCacheVariance.StockAdjustedDispensed * @CaskDispenseMultiplier ELSE StockAdjustedDispensed END AS StockAdjustedDispensed,
			StockAdjustedDelivered,
			CASE 
                WHEN IsCask = 1 
                THEN (PeriodCacheVariance.StockAdjustedDelivered - PeriodCacheVariance.StockAdjustedDispensed) * @CaskDispenseMultiplier 
                ELSE StockAdjustedVariance 
                END AS StockAdjustedVariance,
			StockDate
    FROM PeriodCacheVariance
	JOIN Products ON Products.ID = PeriodCacheVariance.ProductID
	WHERE (WeekCommencing < @PeriodCutoff AND @IncludeStockAdjusments = 1) 
		AND (WeekCommencing BETWEEN @From AND @To) 
		AND IsTied = 1
		AND (IsAudited = 1 OR @OnlyUseAuditedData = 0)
	--The above select is only used when @IncludeStockAdjusments is true
	--It selects the values from the PeriodCache from before the start of the period.
	--The below selects from after the current period (or if IncludeStockAdjusments is false) and NULLs any stock info.
	--This is because all stock dates and stock adjustments in the current period is supposed to be ignored.
	--The result of this UNION is the periodcache values with all stock adjustments taken care of.
	UNION ALL
	SELECT EDISID, 
			--These CASE statements are the same as those above. Only diff should be the WHERE clause.
			CASE @GroupByCategory WHEN 1 THEN 
				CASE @GroupByProduct WHEN 1 THEN
					CASE IsCask WHEN 1 THEN -1 ELSE Products.CategoryID END
				ELSE 
					Products.CategoryID 
				END
			ELSE NULL END AS CategoryID, 
			CASE @GroupByProduct WHEN 1 THEN 
				CASE IsCask WHEN 1 THEN -1 ELSE ProductID END 
			ELSE NULL END AS ProductID, 
			WeekCommencing, 

			CASE WHEN IsCask = 1 THEN Dispensed * @CaskDispenseMultiplier ELSE Dispensed END AS FullWeekDispensed,
			CASE WHEN IsCask = 1 THEN Dispensed * @CaskDispenseMultiplier ELSE Dispensed END AS StockAdjustedDispensed,
			Delivered AS StockAdjustedDelivered, 
			--CASE WHEN IsCask = 1 THEN StockAdjustedDelivered-StockAdjustedDispensed*@CaskDispenseMultiplier ELSE Variance END AS StockAdjustedVariance,
            CASE 
                WHEN IsCask = 1 
                THEN (Delivered - CASE WHEN IsCask = 1 THEN Dispensed * @CaskDispenseMultiplier ELSE Dispensed END) * @CaskDispenseMultiplier 
                ELSE Variance 
                END AS StockAdjustedVariance,
			NULL AS StockDate
    FROM PeriodCacheVariance
	JOIN Products ON Products.ID = PeriodCacheVariance.ProductID
	WHERE (WeekCommencing >= @PeriodCutoff OR @IncludeStockAdjusments = 0) 
		AND (WeekCommencing BETWEEN @From AND @To) 
		AND IsTied = 1
		AND (IsAudited = 1 OR @OnlyUseAuditedData = 0)
) AS Variance
GROUP BY EDISID, CategoryID, ProductID, WeekCommencing, StockDate






--This returns variance figures with the ranged variance for each week based on the max dispense.
;WITH cte_RangedVariance AS (	
	SELECT VarianceDates.EDISID, VarianceDates.CategoryID, VarianceDates.ProductID, Mondays.date AS WC, 
		   ISNULL(Variance.FullWeekDispensed, 0) AS FullWeekDispensed, ISNULL(Variance.Dispense, 0) AS Dispensed, 
		   ISNULL(Variance.Delivered, 0) AS Delivered, ISNULL(Variance.Variance, 0) AS Variance, 
		   CASE WHEN ISNULL(Variance.Dispense, 0) = 0 THEN NULL ELSE ISNULL(Variance.RangedDispense, 0) END AS RangedDispense, 
		   Variance.StockDate
	FROM (
		--Gets a table of Mondays between the From and To dates
		SELECT CalendarDate AS [date] 
		FROM [EDISSQL1\SQL1].[ServiceLogger].dbo.Calendar
		WHERE CalendarDate BETWEEN @From AND @To
		AND DayOfWeek = 1
	) AS Mondays
	CROSS JOIN (
		--This cross join lets us have rows for each week/site/cat/product even if there's no variance data
		SELECT EDISID, CategoryID, ProductID
		FROM #PeriodAdjustedVariance
		GROUP BY EDISID, CategoryID, ProductID
	) AS VarianceDates 
	LEFT JOIN (
		--This is where we join onto the variance data itself.
		SELECT PeriodCacheVariance.EDISID, PeriodCacheVariance.CategoryID, PeriodCacheVariance.ProductID, PeriodCacheVariance.WeekCommencing, 
			   FullWeekDispensed/8 AS FullWeekDispensed,
			   Dispensed/8 AS Dispense, 
			   Delivered/8 AS Delivered, 
			   Variance/8 AS Variance, 
			   --The following rounds down the FullWeekDispensed to the nearest x. Where x is the range classification (worked out in next join)
			   (FLOOR((FullWeekDispensed/8)/RangeClass.Class) * RangeClass.Class) AS RangedDispense,
			   StockDate
		FROM #PeriodAdjustedVariance AS PeriodCacheVariance
		LEFT JOIN (
			--This detirmines the dispanse range classification: 10, 20 or 50. Based on the maximum weekly dispense value in the report range.
			SELECT EDISID, CategoryID, ProductID, MAX(FullWeekDispensed/8) AS MaxDispense,
				   CASE WHEN MAX(FullWeekDispensed/8) >= 200 THEN 50 ELSE CASE WHEN MAX(FullWeekDispensed/8) >= 50.0 THEN 20.0 ELSE 10.0 END END AS Class

			FROM #PeriodAdjustedVariance AS PeriodCacheVariance
			GROUP BY EDISID, CategoryID, ProductID
			
		) AS RangeClass ON RangeClass.EDISID = PeriodCacheVariance.EDISID
						AND (RangeClass.CategoryID = PeriodCacheVariance.CategoryID OR PeriodCacheVariance.CategoryID IS NULL)
						AND (RangeClass.ProductID = PeriodCacheVariance.ProductID OR PeriodCacheVariance.ProductID IS NULL)
						
		WHERE (WeekCommencing BETWEEN @From AND @To)
		
	) AS Variance ON Variance.EDISID = VarianceDates.EDISID 
				  AND (Variance.CategoryID = VarianceDates.CategoryID OR VarianceDates.CategoryID IS NULL)
				  AND (Variance.ProductID = VarianceDates.ProductID OR VarianceDates.ProductID IS NULL)
				  AND Variance.WeekCommencing = Mondays.date
)

--TESTING
--SELECT * FROM cte_RangedVariance
--ORDER BY EDISID, ProductID, WC
--DROP TABLE #PeriodAdjustedVariance 
--DROP TABLE #DateAdjustedVariance
--DROP TABLE #CumulativeVariance
--/TESTING


--Selects from above RangedVariance with anything considered Low Dispense flagged
,cte_ThresholdVariance AS
(	SELECT Variance.EDISID, Variance.CategoryID, Variance.ProductID, Variance.WC, 
		   ISNULL(Variance.FullWeekDispensed, 0) AS FullWeekDispensed,
		   ISNULL(Variance.Dispensed, 0) AS Dispense, 
		   ISNULL(Variance.Delivered, 0) AS Delivered, 
		   ISNULL(Variance.Variance, 0) AS Variance, 
		   --We set any 0 dispense threshold to 0.5 as a hard coded floor.
		   CASE WHEN ISNULL(Thresholod.LowDispenseThreshold, 0) <= 0.5 THEN 0.5 ELSE ISNULL(Thresholod.LowDispenseThreshold, 0) END AS LowDispenseThreshold, 
		   Variance.StockDate, 
		   --If FullWeekDispensed is <= the low dispense threshold then flag as LowDispense
		   CASE WHEN Variance.FullWeekDispensed <= CASE WHEN ISNULL(Thresholod.LowDispenseThreshold, 0) <= 0.5 THEN 0.5 ELSE ISNULL(Thresholod.LowDispenseThreshold, 0) END THEN 1 ELSE 0 END AS LowDispense,
		   --This is the cut off point for the LowDispense adjusted from date
		   ISNULL(Thresholod.MinimumCutoff, @4WeekCutoff) AS MinimumCutoff
	FROM (
		--Selects the variance data
		SELECT RangedVariance.EDISID, RangedVariance.CategoryID, RangedVariance.ProductID, RangedVariance.WC, 
			   RangedVariance.FullWeekDispensed, RangedVariance.Dispensed, 
			   RangedVariance.Delivered, RangedVariance.Variance, 
			   RangedVariance.RangedDispense, RangedVariance.StockDate
		FROM cte_RangedVariance AS RangedVariance
		
	) AS Variance
	LEFT JOIN (
		--Here the RangedDispense is the most frequently occuring range classification for the site/cat/product. 
		--We select MIN() so in the event of multiple classifications having the same # of occurences we take the lowest.
		--The LowDispenseThreshold it x percent of the MIN(RangedDispense) where x is @LowThresholdPercentage
		SELECT EDISID, CategoryID, ProductID, MIN(RangedDispense) AS FreqRange, ISNULL((MIN(RangedDispense)/100)*@LowThresholdPercentage, 0) AS LowDispenseThreshold,
		CASE WHEN ISNULL(MIN(RangedDispense), 0) < 10 THEN @4WeekCutoff ELSE @2WeekCutoff END AS MinimumCutoff
		FROM (
			--The RANK() OVER function ranks the occurences of each RangedDispense value grouped by EDISID/Category/Product (rank of 1 is the most frequent)
			--In there parent querey it restricts the results to RankedRange=1 thus leaving only the most frequent range classification.
			SELECT EDISID, CategoryID, ProductID, RangedDispense, RANK() OVER (PARTITION BY EDISID, CategoryID, ProductID ORDER BY COUNT(*) DESC) AS RankedRange
			FROM (	   
				SELECT RangedVariance.EDISID, RangedVariance.CategoryID, RangedVariance.ProductID, RangedVariance.WC, 
					   RangedVariance.Dispensed, RangedVariance.Delivered, RangedVariance.Variance, 
					   RangedVariance.RangedDispense, RangedVariance.StockDate
				FROM cte_RangedVariance AS RangedVariance
				WHERE RangedDispense IS NOT NULL
				
			) AS RangedValueFreq
			GROUP BY EDISID, CategoryID, ProductID, RangedDispense
		) AS RangedValueTopFreq
		WHERE RankedRange = 1
		GROUP BY EDISID, CategoryID, ProductID

	) AS Thresholod ON Variance.EDISID = Thresholod.EDISID
					AND (Thresholod.CategoryID = Variance.CategoryID OR Variance.CategoryID IS NULL)
					AND (Thresholod.ProductID = Variance.ProductID OR Variance.ProductID IS NULL)
)
--TESTING
--SELECT * FROM cte_ThresholdVariance
--ORDER BY EDISID, ProductID, WC
--DROP TABLE #PeriodAdjustedVariance 
--DROP TABLE #DateAdjustedVariance
--DROP TABLE #CumulativeVariance
--/TESTING


--WeekCommenging date of the most recent stock take at the site
,cte_RecentStockDates AS
(	SELECT EDISID, MAX(WC) AS WC 
	FROM cte_ThresholdVariance AS Variance
	WHERE StockDate IS NOT NULL
	GROUP BY EDISID
)
--WeekCommenging date of the most recent occurence of low dispense on the Site/Category/Product
,cte_RecentLowThreshold AS
(	SELECT EDISID, CategoryID, ProductID, MAX(WC) AS WC 
	FROM cte_ThresholdVariance AS Variance
	WHERE LowDispense = 1
	GROUP BY EDISID, CategoryID, ProductID	
)

--Variance with @From date adjusted to either the most recent stocktake 
--or the week *following* the most recent LowDispense, whichever is the most recent.
INSERT INTO #DateAdjustedVariance (EDISID, CategoryID, ProductID, WC, Delivered, Dispense, Variance, LowDispenseThreshold, StockDate, LowDispDate, AdjustedStartDate, InsufficientData)
SELECT Variance.EDISID, Variance.CategoryID, Variance.ProductID, Variance.WC, Variance.Delivered, Variance.Dispense, Variance.Variance, LowDispenseThreshold,
		RecentStock.WC AS StockDate, RecentLow.WC AS LowDispDate, 
		--AdjustedStartDate is whichever is more recent latest stock or (the week following) latest low dispense.
		CASE WHEN ISNULL(RecentStock.WC, @From) > ISNULL(RecentLow.WC, @From) THEN RecentStock.WC ELSE DATEADD(ww, 1, RecentLow.WC) END AS AdjustedStartDate,
		--If the week following the most recent low dispense is more recent than the MinimumCutoff week and there is not a more recent stocktake
		--We mark the site/cat/product as having InsufficientData with which to work out the CD value
		CASE WHEN (RecentLow.WC >= Variance.MinimumCutoff) AND (ISNULL(RecentStock.WC, @From) <= RecentLow.WC) THEN 1 ELSE 0 END AS InsufficientData
FROM cte_ThresholdVariance AS Variance
LEFT JOIN cte_RecentLowThreshold AS RecentLow ON RecentLow.EDISID = Variance.EDISID 
											  AND (RecentLow.CategoryID = Variance.CategoryID OR Variance.CategoryID IS NULL)
											  AND (RecentLow.ProductID = Variance.ProductID OR Variance.ProductID IS NULL)
LEFT JOIN cte_RecentStockDates AS RecentStock ON RecentStock.EDISID = Variance.EDISID
WHERE ((RecentLow.WC IS NULL AND RecentStock.WC IS NULL) 
	OR ((Variance.WC > RecentLow.WC OR RecentLow.WC IS NULL) OR (Variance.WC >= RecentLow.WC AND Variance.WC > @PeriodCutoff)) 
	AND (Variance.WC >= RecentStock.WC OR RecentStock.WC IS NULL))
	
	
--TESTING
--SELECT * FROM #DateAdjustedVariance
--ORDER BY EDISID, ProductID, WC
--DROP TABLE #PeriodAdjustedVariance 
--DROP TABLE #DateAdjustedVariance
--DROP TABLE #CumulativeVariance
--/TESTING

--Calculate a cummulative variance from the #DateAdjustedVariance
INSERT INTO #CumulativeVariance (EDISID, CategoryID, ProductID, WC, Delivered, Dispense, Variance, CumulativeVariance, LowDispenseThreshold, InsufficientData, AdjustedStartDate)
SELECT VarianceA.EDISID, VarianceA.CategoryID, VarianceA.ProductID, VarianceA.WC, VarianceA.Delivered, VarianceA.Dispense, VarianceA.Variance,
SUM(VarianceB.Variance) AS CumulativeVariance, VarianceA.LowDispenseThreshold, VarianceA.InsufficientData, VarianceA.AdjustedStartDate
FROM #DateAdjustedVariance AS VarianceA
CROSS JOIN #DateAdjustedVariance AS VarianceB
WHERE ((VarianceA.EDISID = VarianceB.EDISID) 
AND (VarianceA.CategoryID = VarianceB.CategoryID OR VarianceA.CategoryID IS NULL) 
AND (VarianceA.ProductID = VarianceB.ProductID OR VarianceA.ProductID IS NULL) 
AND (VarianceB.WC <= VarianceA.WC))
GROUP BY VarianceA.EDISID, VarianceA.CategoryID, VarianceA.ProductID, VarianceA.WC, VarianceA.Delivered, VarianceA.Dispense, VarianceA.Variance, VarianceA.InsufficientData, VarianceA.AdjustedStartDate, VarianceA.LowDispenseThreshold


--TESTING
--SELECT * FROM #CumulativeVariance
--ORDER BY EDISID, ProductID, WC
--DROP TABLE #PeriodAdjustedVariance 
--DROP TABLE #DateAdjustedVariance
--DROP TABLE #CumulativeVariance
--/TESTING

--Final output. 
--Many of these fields are simply the paramaters that were passed in regurgitated in the result set.
SELECT @DatabaseID AS DatabaseID, @PeriodID AS PeriodName, Cumulative.EDISID, Cumulative.CategoryID, Cumulative.ProductID, @IncludeStockAdjusments AS AreValuesStockAdjusted, @From AS FromWeek, Cumulative.AdjustedStartDate AS AdjustedFromWeek, @To AS ToWeek, DATEDIFF(ww, @From, @To) + 1 AS ReportWeeks, DATEDIFF(ww, Cumulative.AdjustedStartDate, @To) + 1 AS AdjustedReportWeeks, @PeriodLength AS PeriodWeeks,
	   --Variance figures for the period only, not the whole report range.
	   ISNULL(ROUND(MAX(PeriodTotals.Delivered), 4, 1), 0) AS PeriodDelivered,
	   ISNULL(ROUND(MAX(PeriodTotals.Dispensed), 4, 1), 0) AS PeriodDispensed,
	   ISNULL(ROUND(MAX(PeriodTotals.Variance), 4, 1), 0) AS PeriodVariance,
	   CASE WHEN Cumulative.LowDispenseThreshold <= 0.5 THEN 0.5 ELSE Cumulative.LowDispenseThreshold END AS LowDispenseThreshold,
	   Cumulative.InsufficientData,
	   --The minimum cumulative variance figure between the AdjustedStartDate and the To date
	   CASE Cumulative.InsufficientData WHEN 0 THEN ROUND(MIN(Cumulative.CumulativeVariance), 4, 1) ELSE NULL END AS MinimumCumulative,	
	   --The minimum cumulative variance figure between the AdjustedStartDate and the period start date
	   CASE Cumulative.InsufficientData WHEN 0 THEN ISNULL(ROUND(MIN(CumulativePrePeriod.CumulativeVariance), 4, 1), 0) ELSE NULL END AS MinimumCumulativePrePeriod,
	   --MinimumCumulative minus the MinimumCumulativePrePeriod with posetive values replaced with zeros
	   --This is the CD value. Ta Da.
	   CASE Cumulative.InsufficientData WHEN 0 THEN 
		   ROUND(
				(CASE WHEN MIN(Cumulative.CumulativeVariance) > 0 THEN 0 ELSE ROUND(MIN(Cumulative.CumulativeVariance), 4, 1) END 
			   - CASE WHEN ISNULL(MIN(CumulativePrePeriod.CumulativeVariance), 0) > 0 THEN 0 ELSE ISNULL(ROUND(MIN(CumulativePrePeriod.CumulativeVariance), 4, 1), 0) END) 
		   , 4, 1)
	   ELSE NULL END AS CD
FROM #CumulativeVariance AS Cumulative
--As well as the whole #CumulativeVariance 
--we join on the #CumulativeVariance restricted to the weeks before the period start date
LEFT JOIN (
	SELECT *
	FROM #CumulativeVariance AS Variance
	WHERE Variance.WC < @PeriodCutoff
) AS CumulativePrePeriod ON Cumulative.EDISID =  CumulativePrePeriod.EDISID 
						 AND (Cumulative.CategoryID = CumulativePrePeriod.CategoryID OR Cumulative.CategoryID IS NULL)
						 AND (Cumulative.ProductID = CumulativePrePeriod.ProductID OR Cumulative.ProductID IS NULL)
						 AND Cumulative.WC = CumulativePrePeriod.WC
--We also join onto #PeriodAdjustedVariance to get the varinace figures for the period (not the whole report) 						 
LEFT JOIN (
	SELECT EDISID, CategoryID, ProductID, 
		SUM(Dispensed)/8 AS Dispensed, 
		SUM(Delivered)/8 AS Delivered, 
		SUM(Variance)/8 AS Variance 
	FROM #PeriodAdjustedVariance
	WHERE WeekCommencing >= @PeriodCutoff
	GROUP BY EDISID, CategoryID, ProductID
	
) AS PeriodTotals ON Cumulative.EDISID =  PeriodTotals.EDISID 
				  AND (Cumulative.CategoryID = PeriodTotals.CategoryID OR Cumulative.CategoryID IS NULL)
				  AND (Cumulative.ProductID = PeriodTotals.ProductID OR Cumulative.ProductID  IS NULL)
		 					 
GROUP BY Cumulative.EDISID, Cumulative.CategoryID, Cumulative.ProductID, Cumulative.InsufficientData, Cumulative.AdjustedStartDate, Cumulative.LowDispenseThreshold
ORDER BY EDISID, ProductID

DROP TABLE #PeriodAdjustedVariance 
DROP TABLE #DateAdjustedVariance
DROP TABLE #CumulativeVariance

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCalculatedDeficit] TO PUBLIC
    AS [dbo];

