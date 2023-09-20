CREATE PROCEDURE GetOutOfHoursDispenseByPump
(
	@EDISID INT,
	@FromDate DATETIME,
	@ToDate DATETIME,
	@FromHour INT = NULL,
	@ToHour INT = NULL,
	@Pump INT = NULL
)

AS

SET DATEFIRST 1

SELECT DATEPART(dw, DailyDispenses.[Date]) AS [WeekDay],
	 DailyDispenses.Pump,
	 SUM(DailyDispenses.Quantity) AS Quantity,
	 COUNT(*) AS Occurences

FROM	(SELECT MasterDates.[Date],
		  DLData.Pump,
		  SUM(DLData.Quantity) AS Quantity
	FROM Sites
	JOIN MasterDates ON MasterDates.EDISID = Sites.EDISID
	JOIN DLData ON MasterDates.[ID] = DLData.DownloadID
	JOIN SiteClosingHours ON MasterDates.EDISID = SiteClosingHours.EDISID 
				AND SiteClosingHours.HourOfDay = (DLData.Shift - 1)
				AND SiteClosingHours.[WeekDay] = DATEPART(dw, MasterDates.[Date])
	WHERE MasterDates.EDISID = @EDISID
	AND MasterDates.[Date] BETWEEN @FromDate AND @ToDate
	AND Sites.SiteOnline <= @FromDate
	AND (SiteClosingHours.HourOfDay >= @FromHour OR @FromHour IS NULL)
	AND (SiteClosingHours.HourOfDay >= @ToHour OR @ToHour IS NULL)
	AND (DLData.Pump = @Pump OR @Pump IS NULL)
	GROUP BY MasterDates.[Date], DLData.Pump) AS DailyDispenses

GROUP BY DATEPART(dw, DailyDispenses.[Date]), DailyDispenses.Pump

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetOutOfHoursDispenseByPump] TO PUBLIC
    AS [dbo];

