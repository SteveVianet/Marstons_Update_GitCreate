CREATE PROCEDURE [dbo].[zRS_WeeklyVarianceTrend]

AS

SET NOCOUNT ON

SET DATEFIRST 1

DECLARE @TodayDayOfWeek INT
DECLARE @EndOfPrevWeek DateTime
DECLARE @StartOfPrevWeek DateTime

--get number of a current day (1-Monday, 2-Tuesday... 7-Sunday)
SET @TodayDayOfWeek = datepart(dw, GetDate())

--get the first day of the previous week (the Monday before last)
SET @StartOfPrevWeek = DATEADD(dd, -(@TodayDayOfWeek+6), CAST(GETDATE() AS DATE))

--Now we can use above expressions in our query:
PRINT @TodayDayOfWeek
PRINT @StartOfPrevWeek 
PRINT @StartOfPrevWeek - 161

CREATE TABLE #Variance(	Customer			VARCHAR(100)
						,EDISID				INT
						, WeekCommencing	DATETIME
						, Delivered			FLOAT
						, Dispensed			FLOAT
						, Variance			FLOAT)

CREATE TABLE #SiteWeekTotals (Customer			VARCHAR(100)
							, WeekCommencing	DATETIME
							, Delivered			FLOAT
							, Dispensed			FLOAT
							, Variance			FLOAT)


INSERT INTO #Variance
			(Customer
			, EDISID
			, WeekCommencing
			, Delivered
			, Dispensed
			, Variance)

			SELECT	Configuration.PropertyValue AS Customer
					, PeriodCacheVariance.EDISID
					, PeriodCacheVariance.WeekCommencing
			--		, SUM(PeriodCacheVariance.Delivered) AS Delivered
					, CASE WHEN SUM(PeriodCacheVariance.Dispensed) = 0 THEN 0 ELSE SUM(PeriodCacheVariance.Delivered) END AS Delivered
			
					, SUM(PeriodCacheVariance.Dispensed)  AS Dispensed
			--		, SUM(PeriodCacheVariance.Variance) AS Variance
					, CASE WHEN SUM(PeriodCacheVariance.Dispensed) = 0 THEN 0 ELSE SUM(PeriodCacheVariance.Delivered)-SUM(PeriodCacheVariance.Dispensed) END AS Variance

			FROM PeriodCacheVariance

					JOIN Sites ON Sites.EDISID = PeriodCacheVariance.EDISID

					JOIN Configuration ON PropertyName = 'Company Name'

					JOIN     Products                         ON PeriodCacheVariance.ProductID = Products.ID
					JOIN     ProductCategories                ON Products.CategoryID  = ProductCategories.ID 

			WHERE

					PeriodCacheVariance.WeekCommencing BETWEEN (@StartOfPrevWeek-161) AND @StartOfPrevWeek

					AND ProductCategories.Description <>'Syrup'

					AND Sites.Status IN (1,2,3)
					AND Sites.Hidden = 0
					AND Sites.SiteID NOT IN
					(
					SELECT s.SiteID FROM Sites AS s
					INNER JOIN SiteProperties sp ON sp.EDISID = s.EDISID
					INNER JOIN Properties p ON p.ID = sp.PropertyID
					WHERE p.Name = 'Exclude From Reds' AND Value = ''
					)



			GROUP BY Configuration.PropertyValue 
					 ,PeriodCacheVariance.WeekCommencing
					 , PeriodCacheVariance.EDISID


--		SELECT * FROM #Variance


INSERT INTO #SiteWeekTotals

			SELECT Customer
					,WeekCommencing
					,SUM(Delivered)
					,SUM(Dispensed)
					,SUM(Variance)

			FROM #Variance

			GROUP BY Customer, WeekCommencing


--		SELECT * FROM #SiteWeekTotals
--		ORDER BY WeekCommencing


SELECT  WeekTotalsA.Customer
        , WeekTotalsA.WeekCommencing
        , WeekTotalsA.Delivered/8 AS Delivered
        , WeekTotalsA.Dispensed/8 AS Dispensed
        , WeekTotalsA.Variance/8 AS Variance
        , SUM(WeekTotalsB.Variance)/8 AS CumulativeVariance

      FROM #SiteWeekTotals AS WeekTotalsA
      
      CROSS JOIN #SiteWeekTotals AS WeekTotalsB

      WHERE ((WeekTotalsA.Customer = WeekTotalsB.Customer) 
--     AND (VarianceA.EDISID = VarianceB.EDISID OR VarianceA.EDISID IS NULL) 
      AND (WeekTotalsB.WeekCommencing <= WeekTotalsA.WeekCommencing))
      GROUP BY		WeekTotalsA.Customer
				  , WeekTotalsA.Delivered/8
				  , WeekTotalsA.Dispensed/8
				  , WeekTotalsA.WeekCommencing
				  , WeekTotalsA.Variance

	ORDER BY WeekTotalsA.WeekCommencing


DROP TABLE #Variance
DROP TABLE #SiteWeekTotals
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_WeeklyVarianceTrend] TO PUBLIC
    AS [dbo];

