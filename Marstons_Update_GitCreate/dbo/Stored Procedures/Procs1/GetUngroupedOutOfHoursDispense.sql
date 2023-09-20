---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetUngroupedOutOfHoursDispense
(
	@EDISID INT,
	@FromDate DATETIME,
	@ToDate DATETIME,
	@FromHour INT = NULL,
	@ToHour INT = NULL
)

AS

SET DATEFIRST 1

SELECT	MasterDates.[Date],
	DLData.Shift,
	SUM(DLData.Quantity) AS Quantity
FROM Sites
JOIN MasterDates ON MasterDates.EDISID = Sites.EDISID
JOIN DLData ON MasterDates.[ID] = DLData.DownloadID
JOIN SiteClosingHours ON MasterDates.EDISID = SiteClosingHours.EDISID 
			AND SiteClosingHours.HourOfDay = (DLData.Shift - 1)
			AND SiteClosingHours.[WeekDay] = DATEPART(dw, MasterDates.[Date])
WHERE MasterDates.EDISID = @EDISID
AND MasterDates.[Date] BETWEEN @FromDate AND @ToDate
AND Sites.SiteOnline <= MasterDates.[Date]
AND (SiteClosingHours.HourOfDay >= @FromHour OR @FromHour IS NULL)
AND (SiteClosingHours.HourOfDay >= @ToHour OR @ToHour IS NULL)
GROUP BY MasterDates.[Date], DLData.Shift
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetUngroupedOutOfHoursDispense] TO PUBLIC
    AS [dbo];

