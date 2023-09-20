CREATE PROCEDURE [dbo].[LineCleaningGetPulseLiquidOverflowSites]
(
	@EDISID int = NULL,
	@Auditor varchar(255) = NULL
)
AS

--DECLARE @EDISID int = NULL
--DECLARE @Auditor varchar(255) = NULL

SET DATEFIRST 1;

DECLARE @ChangeDispense BIT = 0

DECLARE @CurrentWeek	DATETIME = GETDATE()
SET @CurrentWeek = DATEADD(dd, 1-DATEPART(dw, @CurrentWeek), @CurrentWeek)

DECLARE @CurrentWeekFrom		DATETIME
DECLARE @To						DATETIME
DECLARE @Today					DATETIME
DECLARE @MasterDateID int
DECLARE @Line int
DECLARE @TimeHour int
DECLARE @Vol float
DECLARE @timeDate DATETIME = '1899-12-30 00:00:00'
DECLARE @tempTimeDate DATETIME  = '1899-12-30 00:00:00'

SET @CurrentWeekFrom = CAST(DATEADD(week, -2, @CurrentWeek) AS DATE)
SET @To = DATEADD(week, -1, DATEADD(day, 6, @CurrentWeek))

CREATE TABLE #Sites(EDISID INT, Hidden BIT, BirthDate DATETIME)
CREATE TABLE #MasterDates(ID INT, EDISID INT, MasterDate DATETIME)
CREATE TABLE #OutOfHoursWater(MasterDateID INT, [Shift] INT)

CREATE TABLE #BeerToWater(MasterDateID INT, Line INT, [Shift] INT, Volume FLOAT)

/*
Get non-idraught sites that are Active, FOT or Legals
*/
INSERT INTO #Sites
(EDISID, Hidden, BirthDate)
SELECT Sites.EDISID, Hidden, BirthDate
FROM Sites
WHERE Hidden = 0
AND (@EDISID IS NULL OR Sites.EDISID = @EDISID)
AND SiteOnline <= @To
AND [Status] IN (1,10,3)
AND Quality = 0
AND	(@Auditor IS NULL OR SiteUser = @Auditor)

---- Relevant MasterDates
INSERT INTO #MasterDates(ID, EDISID, MasterDate)
SELECT	MasterDates.ID, 
		MasterDates.EDISID, 
		MasterDates.[Date]
FROM	MasterDates 
INNER JOIN #Sites ON MasterDates.EDISID = #Sites.EDISID
WHERE	MasterDates.[Date] >= @CurrentWeekFrom and MasterDates.[Date] <= @To

INSERT INTO #OutOfHoursWater (MasterDateID, [Shift])
SELECT	DISTINCT md.ID, (DATEPART(hh, ws.[Time]) + 1)
FROM	#MasterDates md
INNER JOIN WaterStack ws ON md.ID = ws.WaterID
INNER JOIN PumpSetup ps ON ws.Line = ps.Pump AND ps.ValidTo IS NULL
INNER JOIN Products p ON ps.ProductID = p.ID AND p.IsWater = 1 AND p.IsCask = 0 and p.IsMetric = 0
WHERE	DATEPART(hh, ws.[Time]) >= 1 AND DATEPART(hh, ws.[Time]) < 10

--get dispenses where there is a water in the same day/hour
INSERT INTO #BeerToWater
SELECT	DISTINCT d.DownloadID, 
		d.Pump, 
		d.[Shift], 
		d.Quantity
FROM	#OutOfHoursWater oow
INNER JOIN DLData d ON d.DownloadID = oow.MasterDateID AND oow.[Shift] = d.[Shift]
INNER JOIN Products p ON d.Product = p.ID
WHERE	p.IsWater = 0

IF @ChangeDispense = 1
BEGIN
	IF (SELECT COUNT(*) FROM #BeerToWater) > 0
	BEGIN
		PRINT 'Changing Dispense'

		DECLARE @AddWaterRemoveBeerDispenseCursor AS CURSOR

		SET @AddWaterRemoveBeerDispenseCursor = CURSOR FOR (select MasterDateID, Line, [Shift] - 1, Volume FROM #BeerToWater)
		OPEN @AddWaterRemoveBeerDispenseCursor;
		FETCH NEXT FROM @AddWaterRemoveBeerDispenseCursor INTO  @MasterDateID,@Line,@TimeHour,@Vol

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @tempTimeDate = DATEADD(hh,@TimeHour,@timeDate)

			IF EXISTS(SELECT * FROM WaterStack ws WHERE	ws.WaterID = @MasterDateID AND ws.Line = @Line AND ws.[Time] = @tempTimeDate)
			BEGIN
				UPDATE	WaterStack SET Volume = Volume + @Vol
				FROM	WaterStack ws 
				WHERE	ws.WaterID = @MasterDateID AND ws.Line = @Line AND ws.[Time] = @tempTimeDate
			END
			ELSE
			BEGIN
				INSERT INTO dbo.WaterStack(WaterID, [Time], Line, Volume)
				VALUES (@MasterDateID, @tempTimeDate, @Line, @Vol)
			END

			DELETE FROM dbo.DLData
			WHERE DownloadID = @MasterDateID and DLData.[Shift] = (@TimeHour + 1) and @Line = DLData.Pump

			SET @tempTimeDate = @timeDate

			FETCH NEXT FROM @AddWaterRemoveBeerDispenseCursor INTO  @MasterDateID,@Line,@TimeHour,@Vol
		END

		CLOSE @AddWaterRemoveBeerDispenseCursor
		DEALLOCATE @AddWaterRemoveBeerDispenseCursor;
	END
END
ELSE
BEGIN
	PRINT 'Change Dispense Turned off'
	IF (SELECT COUNT(*) FROM #BeerToWater) > 0
	BEGIN
		DECLARE @WaterBeerDispenseCursor AS CURSOR

		SET @WaterBeerDispenseCursor = CURSOR FOR (select MasterDateID, Line, [Shift] - 1, Volume FROM #BeerToWater)
		OPEN @WaterBeerDispenseCursor;
		FETCH NEXT FROM @WaterBeerDispenseCursor INTO  @MasterDateID,@Line,@TimeHour,@Vol

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @tempTimeDate = DATEADD(hh,@TimeHour,@timeDate)

			IF EXISTS(SELECT * FROM WaterStack ws WHERE	ws.WaterID = @MasterDateID AND ws.Line = @Line AND ws.[Time] = @tempTimeDate)
			BEGIN
				PRINT 'Updating Water Stack'
			END
			ELSE
			BEGIN
				PRINT 'New Water Stack'
			END

			SET @tempTimeDate = @timeDate

			FETCH NEXT FROM @WaterBeerDispenseCursor INTO  @MasterDateID,@Line,@TimeHour,@Vol
		END

		CLOSE @WaterBeerDispenseCursor
		DEALLOCATE @WaterBeerDispenseCursor;
	END
END

SELECT EDISID, MasterDate --return the list of sites/dates to record in SiteNotification
FROM #MasterDates
inner join #BeerToWater as beer on #MasterDates.ID = beer.MasterDateID

DROP TABLE #Sites
DROP TABLE #MasterDates
DROP TABLE #BeerToWater
DROP TABLE #OutOfHoursWater
