CREATE PROCEDURE [dbo].[RebuildTradingDispenseCache]
(
	@EDISID INT = NULL,
	@From	DATETIME = NULL,
	@To		DATETIME = NULL
)
AS

--DECLARE	@EDISID INT = 270
----DECLARE	@EDISID INT = 174   -- DMS
----DECLARE	@EDISID INT = 1325  -- iDraught
--DECLARE	@From	DATETIME = DATEADD(WEEK, -1, GETDATE())
--DECLARE	@To		DATETIME = GETDATE()

SET NOCOUNT ON
SET DATEFIRST 1

DECLARE @RebuildStart DATE

IF @EDISID IS NOT NULL
BEGIN
	SET @RebuildStart = CAST(DATEADD(WEEK, -4, GETDATE()) AS DATE)
END
ELSE
BEGIN
	SET @RebuildStart = CAST(DATEADD(MONTH, -6, GETDATE()) AS DATE)
END

-- If you supply a from date, it overrides the above defaulting of 'from'
IF @From IS NOT NULL
BEGIN
	SET @RebuildStart = @From
END

-- To is defaulted to today if not suplied
IF @To IS NULL
BEGIN
	SET @To = GETDATE()
END

-- Create a temporary stable place to store the dispense we wish to work against.
-- Not strictly required, but it probably makes the MERGE statement easier to read.

IF OBJECT_ID('tempdb..#TempTradingDispense') IS NOT NULL
BEGIN
    DROP TABLE #TempTradingDispense
END

CREATE TABLE #TempTradingDispense (
	[EDISID] [int] NOT NULL,
	[TradingDay] [date] NOT NULL,
	[Pump] [int] NOT NULL,
	[LocationID] [int] NULL,
	[ProductID] [int] NOT NULL,
	[Volume] [float] NULL,
	[WastedVolume] [float] NULL
)


---- Per-Pour Trading Dispense
INSERT INTO #TempTradingDispense
    (EDISID, TradingDay, Pump, LocationID, ProductID, Volume, WastedVolume)
SELECT	DispenseActions.EDISID, 
		DispenseActions.TradingDay,
		DispenseActions.Pump,
		DispenseActions.[Location],
		DispenseActions.Product,
		SUM(CASE WHEN LiquidType = 2
			 THEN Pints
			 ELSE 0
		END) AS TotalVolume, --Beer
		SUM(CASE WHEN LiquidType = 5
			 THEN Pints
			 ELSE 0
		END) AS TotalWastedVolume --Beer in clean
FROM Sites
JOIN DispenseActions ON DispenseActions.EDISID = Sites.EDISID
WHERE (Sites.EDISID = @EDISID OR @EDISID IS NULL)
  AND LiquidType IN (2, 5) --Beer, Beer in clean
  AND DispenseActions.TradingDay BETWEEN @RebuildStart AND @To
GROUP BY	DispenseActions.EDISID,
			DispenseActions.TradingDay,
			DispenseActions.Pump,
			DispenseActions.[Location],
			DispenseActions.Product
OPTION (MAXDOP 2)

-- DMS Trading Dispense
-- (only do this where we have not inserted Per-Pour dispense)

DECLARE @TradingStart DATE = DATEADD(DAY, -1, @RebuildStart)
DECLARE @TradingEnd DATE = DATEADD(DAY, 1, @To)

INSERT INTO #TempTradingDispense
    (EDISID, TradingDay, Pump, LocationID, ProductID, Volume, WastedVolume)
SELECT
    RelevantDLData.EDISID,
    RelevantDLData.[Date],
    RelevantDLData.Pump,
    RelevantDLData.[Location],
    RelevantDLData.[Product],
    RelevantDLData.[TotalVolume],
    RelevantDLData.[WastedVolume]
FROM (
    SELECT 
        Sites.EDISID AS [EDISID],
        CASE WHEN (DLData.[Shift]-1) < 5 
             THEN DATEADD(DAY, -1, MasterDates.[Date])
             ELSE MasterDates.[Date]
        END AS [Date],
        DLData.Pump,
        dbo.fnGetLocationFromPump(Sites.EDISID, DLData.Pump, CASE WHEN (DLData.[Shift]-1) < 5 THEN DATEADD(DAY, -1, MasterDates.[Date]) ELSE MasterDates.[Date] END) AS [Location],
        DLData.Product AS [Product],
        SUM(DLData.Quantity) AS [TotalVolume],
        0 AS [WastedVolume]
    FROM Sites 
    JOIN MasterDates ON Sites.EDISID = MasterDates.EDISID
    JOIN DLData ON DLData.DownloadID = MasterDates.ID
    WHERE (Sites.EDISID = @EDISID OR @EDISID IS NULL)
    AND MasterDates.[Date] BETWEEN @TradingStart AND @TradingEnd -- Extend the date range by 1 day as "Trading Days" will move data before 5am
    GROUP BY Sites.EDISID, 
		     CASE WHEN DLData.[Shift]-1 < 5 THEN DATEADD(DAY, -1, MasterDates.[Date]) ELSE MasterDates.[Date] END, 
		     DLData.Pump, 
		     DLData.Product
    ) AS RelevantDLData 
LEFT JOIN #TempTradingDispense 
    AS TD
    ON RelevantDLData.EDISID = TD.EDISID
    AND RelevantDLData.[Date] =  TD.TradingDay
WHERE TD.EDISID IS NULL
AND RelevantDLData.[Date] BETWEEN @RebuildStart AND @To
OPTION (MAXDOP 2)

-- This is where the magic happens
MERGE PeriodCacheTradingDispense AS TARGET
USING #TempTradingDispense AS SOURCE
    ON (TARGET.EDISID = SOURCE.EDISID AND TARGET.TradingDay = SOURCE.TradingDay AND TARGET.Pump = SOURCE.Pump AND TARGET.LocationID = SOURCE.LocationID AND TARGET.ProductID = SOURCE.ProductID)
-- When records are matched, update the records if there is any change
WHEN MATCHED AND (TARGET.Volume <> SOURCE.Volume OR TARGET.WastedVolume <> SOURCE.WastedVolume) THEN 
    UPDATE 
        SET TARGET.Volume = SOURCE.Volume,
            TARGET.WastedVolume = SOURCE.WastedVolume
--When no records are matched, insert the data
WHEN NOT MATCHED BY TARGET THEN
    INSERT (EDISID, TradingDay, Pump, LocationID, ProductID, Volume, WastedVolume)
    VALUES (SOURCE.EDISID, SOURCE.TradingDay, SOURCE.Pump, SOURCE.LocationID, SOURCE.ProductID, SOURCE.Volume, SOURCE.WastedVolume)
-- When a record exists that isn't in the source, remove it
WHEN NOT MATCHED BY SOURCE AND (TARGET.TradingDay BETWEEN @RebuildStart AND @To AND TARGET.EDISID IN (SELECT DISTINCT EDISID FROM #TempTradingDispense)) THEN
    DELETE
-- The following is for debugging only. This places a huge burden on disk when enabled (e.g. 22k (off) vs 9.2 million (on))
--OUTPUT $action, DELETED.EDISID AS TargetEDISID, DELETED.TradingDay AS TargetDay, DELETED. Pump AS TargetPump, INSERTED.EDISID AS SourceEDISID, INSERTED.TradingDay AS SourceDay, INSERTED.Pump AS SourcePump
OPTION (MAXDOP 2)
; -- A MERGE must be ended with a semi-colon

-- Tidy up
DROP TABLE #TempTradingDispense


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[RebuildTradingDispenseCache] TO PUBLIC
    AS [dbo];

