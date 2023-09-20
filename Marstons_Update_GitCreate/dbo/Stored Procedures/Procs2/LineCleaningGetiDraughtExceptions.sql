CREATE PROCEDURE [dbo].[LineCleaningGetiDraughtExceptions]
(
	@EDISID int = NULL,
	@Auditor varchar(50) = NULL
)


AS

SET DATEFIRST 1;

DECLARE @CurrentWeek	DATETIME = GETDATE()
SET @CurrentWeek = DATEADD(dd, 1-DATEPART(dw, @CurrentWeek), @CurrentWeek)

DECLARE @CurrentWeekFrom		DATETIME
DECLARE @To						DATETIME
DECLARE @Today					DATETIME

SET @CurrentWeekFrom = CAST(DATEADD(week, -2, @CurrentWeek) AS DATE)
SET @To = DATEADD(week, -1, DATEADD(day, 6, @CurrentWeek))


DECLARE @CleanerLiquidType INT
SET @CleanerLiquidType = 3

DECLARE @WaterLiquidType INT
SET @WaterLiquidType = 1

CREATE TABLE #Sites(EDISID INT, IsBQM bit)
CREATE TABLE #SitesToRaise(EDISID INT, DateOfInterest DATETIME)


INSERT INTO #Sites
(EDISID, IsBQM)
SELECT Sites.EDISID, Quality
FROM Sites
WHERE Hidden = 0
AND (@EDISID IS NULL OR Sites.EDISID = @EDISID)
AND(@Auditor IS NULL OR SiteUser = @Auditor)
AND SiteOnline <= @To
AND [Status] IN (1,10,3)

insert into #SitesToRaise(EDISID, DateOfInterest)
SELECT #Sites.EDISID, CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, DispenseActions.TradingDay))) as [Date]
from DispenseActions
inner join #Sites on #Sites.EDISID = DispenseActions.EDISID
where IsBQM = 1
and (TradingDay >= @CurrentWeekFrom AND TradingDay <= @To) 
AND LiquidType IN (@CleanerLiquidType, @WaterLiquidType)
--doe it need a group?


SELECT	DISTINCT EDISID, DateOfInterest
FROM	#SitesToRaise

DROP TABLE #Sites
DROP TABLE #SitesToRaise

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[LineCleaningGetiDraughtExceptions] TO PUBLIC
    AS [dbo];

