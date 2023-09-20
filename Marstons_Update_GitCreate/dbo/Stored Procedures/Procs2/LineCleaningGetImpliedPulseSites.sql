CREATE PROCEDURE [dbo].[LineCleaningGetImpliedPulseSites]
(
	@EDISID int = NULL,
	@Auditor varchar(255) = NULL
)
AS

--DECLARE @EDISID int = NULL
--DECLARE @Auditor varchar(255) = NULL

SET DATEFIRST 1;

DECLARE @CurrentWeek	DATETIME = GETDATE()
SET @CurrentWeek = DATEADD(dd, 1-DATEPART(dw, @CurrentWeek), @CurrentWeek)

DECLARE @CurrentWeekFrom		DATETIME
DECLARE @To						DATETIME
DECLARE @Today					DATETIME

SET @CurrentWeekFrom = CAST(DATEADD(week, -2, @CurrentWeek) AS DATE)
SET @To = DATEADD(week, -1, DATEADD(day, 6, @CurrentWeek))

CREATE TABLE #Sites(EDISID INT, Hidden BIT, BirthDate DATETIME)
CREATE TABLE #SitesToRaise(EDISID INT, DateOfInterest DATETIME)
CREATE TABLE #MasterDates(ID INT, EDISID INT, MasterDate DATETIME)

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

DECLARE @TotalShiftOOHVolumeThreshold INT = 15
DECLARE @TotalShiftCaskVolumeThreshold INT = 10

---- Relevant Master Dates
INSERT INTO #MasterDates(ID, EDISID, MasterDate)
SELECT	DISTINCT MasterDates.ID, MasterDates.EDISID, MasterDates.[Date]
FROM	MasterDates 
INNER JOIN #Sites ON MasterDates.EDISID = #Sites.EDISID
WHERE	MasterDates.[Date] >= @CurrentWeekFrom and MasterDates.[Date] <= @To

---- Get all 'out of hours' dispense (between 1:00 and 10:00) where no volume is showing on water line at the same time, over a threshold
INSERT INTO #SitesToRaise
SELECT #MasterDates.EDISID, MasterDate
FROM #MasterDates
INNER JOIN DLData on #MasterDates.ID = DownloadID
INNER JOIN Products p ON DLData.Product = p.ID AND p.IsWater = 0
LEFT OUTER JOIN WaterStack ws ON #MasterDates.ID = ws.WaterID AND (DLData.[Shift] - 1) = ws.[Time]
LEFT OUTER JOIN PumpSetup wps ON wps.Pump = ws.Line AND wps.ValidTo IS NULL
LEFT OUTER JOIN Products wp ON wps.ProductID = wp.ID AND wp.IsWater = 1
WHERE	(DLData.[Shift] - 1) >= 1 AND (DLData.[Shift] - 1) < 10
AND		wp.ID IS NULL
GROUP BY #MasterDates.EDISID, #MasterDates.MasterDate, DLData.[Shift]
HAVING SUM(DLData.Quantity) > @TotalShiftOOHVolumeThreshold 

---- Get all 'out of hours' cask dispense (between 1:00 and 10:00) where no volume is showing on water line at the same time, over a threshold
INSERT INTO #SitesToRaise
SELECT #MasterDates.EDISID, MasterDate
FROM #MasterDates
INNER JOIN DLData on #MasterDates.ID = DownloadID
INNER JOIN Products p ON DLData.Product = p.ID
LEFT OUTER JOIN WaterStack ws ON #MasterDates.ID = ws.WaterID AND (DLData.[Shift] - 1) = ws.[Time]
LEFT OUTER JOIN PumpSetup wps ON wps.Pump = ws.Line AND wps.ValidTo IS NULL
LEFT OUTER JOIN Products wp ON wps.ProductID = wp.ID AND wp.IsWater = 1
WHERE	p.IsCask = 1 AND p.IsWater = 0 AND p.IsMetric = 0
AND		wp.ID IS NULL
GROUP BY #MasterDates.EDISID, DLData.[Shift], #MasterDates.MasterDate
HAVING SUM(DLData.Quantity) > @TotalShiftCaskVolumeThreshold

-- Volume on water line in hours (10:00 to 1:00)
INSERT INTO #SitesToRaise
SELECT #MasterDates.EDISID, #MasterDates.[MasterDate]
FROM #MasterDates
INNER JOIN WaterStack on #MasterDates.ID = WaterID
INNER JOIN PumpSetup ON PumpSetup.Pump = WaterStack.Line AND PumpSetup.ValidTo IS NULL
INNER JOIN Products ON PumpSetup.ProductID = Products.ID AND Products.IsWater = 1
WHERE DATEPART(hour, WaterStack.[Time]) < 1 AND DATEPART(hour, WaterStack.[Time]) >= 10

SELECT	DISTINCT EDISID, DateOfInterest
FROM	#SitesToRaise

DROP TABLE #Sites
DROP TABLE #SitesToRaise
DROP TABLE #MasterDates

