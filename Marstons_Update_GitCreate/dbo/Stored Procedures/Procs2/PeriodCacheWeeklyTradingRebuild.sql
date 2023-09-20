CREATE PROCEDURE [dbo].[PeriodCacheWeeklyTradingRebuild]
(
       @FromMonday          DATE = NULL,
       @To                  DATE = NULL
)
AS

SET DATEFIRST 1

-- Default to last six months
IF @FromMonday IS NULL AND @To IS NULL
BEGIN
       SET @To = GETDATE()
       SET @FromMonday = DATEADD(MONTH, -6, GETDATE())
END

-- Ensure from date is Monday
SELECT @FromMonday = FirstDateOfWeek
FROM Calendar
WHERE Calendar.CalendarDate = @FromMonday

-- Ensure to date is a Sunday
SELECT @To = LastDateOfWeek
FROM Calendar
WHERE Calendar.CalendarDate = @To


IF OBJECT_ID('tempdb..#TempTradingDispenseWeekly') IS NOT NULL
BEGIN
    DROP TABLE #TempTradingDispenseWeekly
END

CREATE TABLE #TempTradingDispenseWeekly
(
       EDISID [int] NOT NULL,
       WeekCommencing [date] NOT NULL, 
       Pump [int] NOT NULL, 
       LocationID [int] NULL, 
       ProductID [int] NOT NULL, 
       Volume [float] NULL, 
       WastedVolume [float] NULL
)

INSERT INTO #TempTradingDispenseWeekly 
(EDISID, WeekCommencing, Pump, LocationID, ProductID, Volume, WastedVolume)
SELECT PeriodCacheTradingDispense.EDISID,
              DATEADD(dw, -DATEPART(dw, PeriodCacheTradingDispense.TradingDay) + 1, PeriodCacheTradingDispense.TradingDay) AS TradingDate,
              PeriodCacheTradingDispense.Pump,
              PeriodCacheTradingDispense.LocationID,
              PeriodCacheTradingDispense.ProductID,
              SUM(PeriodCacheTradingDispense.Volume) AS WeeklyVolume,
              SUM(PeriodCacheTradingDispense.WastedVolume) AS WeeklyWastedVolume
FROM PeriodCacheTradingDispense
JOIN Products ON Products.ID = PeriodCacheTradingDispense.ProductID
JOIN ProductCategories ON ProductCategories.ID = Products.CategoryID
WHERE PeriodCacheTradingDispense.TradingDay BETWEEN @FromMonday AND @To
AND Products.IncludeInLowVolume = 1
AND Products.IsMetric = 0
AND ProductCategories.IncludeInEstateReporting = 1
GROUP BY      PeriodCacheTradingDispense.EDISID,
                     DATEADD(dw, -DATEPART(dw, PeriodCacheTradingDispense.TradingDay) + 1, PeriodCacheTradingDispense.TradingDay),
                     PeriodCacheTradingDispense.Pump,
                     PeriodCacheTradingDispense.ProductID,
                     PeriodCacheTradingDispense.LocationID
OPTION (MAXDOP 2)



-- This is where the magic happens
MERGE PeriodCacheTradingDispenseWeekly AS TARGET
USING #TempTradingDispenseWeekly AS SOURCE
    ON (TARGET.EDISID = SOURCE.EDISID AND TARGET.WeekCommencing = SOURCE.WeekCommencing AND TARGET.Pump = SOURCE.Pump AND TARGET.LocationID = SOURCE.LocationID AND TARGET.ProductID = SOURCE.ProductID)
-- When records are matched, update the records if there is any change
WHEN MATCHED AND (TARGET.Volume <> SOURCE.Volume OR TARGET.WastedVolume <> SOURCE.WastedVolume) THEN 
    UPDATE 
        SET TARGET.Volume = SOURCE.Volume,
            TARGET.WastedVolume = SOURCE.WastedVolume
--When no records are matched, insert the data
WHEN NOT MATCHED BY TARGET THEN
    INSERT (EDISID, WeekCommencing, Pump, LocationID, ProductID, Volume, WastedVolume)
    VALUES (SOURCE.EDISID, SOURCE.WeekCommencing, SOURCE.Pump, SOURCE.LocationID, SOURCE.ProductID, SOURCE.Volume, SOURCE.WastedVolume)
-- When a record exists that isn't in the source, remove it
WHEN NOT MATCHED BY SOURCE AND (TARGET.WeekCommencing BETWEEN @FromMonday AND @To AND TARGET.EDISID IN (SELECT DISTINCT EDISID FROM #TempTradingDispenseWeekly)) THEN
    DELETE
OPTION (MAXDOP 2)
; -- A MERGE must be ended with a semi-colon

-- Tidy up
DROP TABLE #TempTradingDispenseWeekly

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[PeriodCacheWeeklyTradingRebuild] TO PUBLIC
    AS [dbo];

