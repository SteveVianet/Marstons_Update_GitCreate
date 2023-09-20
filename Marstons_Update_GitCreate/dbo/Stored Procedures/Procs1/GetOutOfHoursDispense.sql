---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetOutOfHoursDispense
(
	@EDISID INT,
	@FromDate DATETIME,
	@ToDate DATETIME,
	@FromHour INT = NULL,
	@ToHour INT = NULL
)

AS

SET DATEFIRST 1

SELECT	DATEPART(dw, DailyDispenses.[Date]) AS [WeekDay],
	SUM(DailyDispenses.Quantity) AS Quantity,
	COUNT(*) AS Occurences
FROM	(SELECT	MasterDates.[Date],
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
	GROUP BY MasterDates.[Date]) AS DailyDispenses
GROUP BY DATEPART(dw, DailyDispenses.[Date])
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetOutOfHoursDispense] TO PUBLIC
    AS [dbo];

