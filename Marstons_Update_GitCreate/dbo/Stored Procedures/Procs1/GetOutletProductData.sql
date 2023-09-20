---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetOutletProductData
(
	@SiteID	VARCHAR(50),
	@StartDate	DATETIME,
	@EndDate 	DATETIME
)

AS

SET DATEFIRST 1

SELECT	Products.[Description] AS Product, 
		[WeekDay],
		SUM([11to3]) AS [11to3],
		SUM([3to7]) AS [3to7],
		SUM([7to11]) AS [7to11],
		SUM([OutOfHours]) AS [OutOfHours]
FROM	(SELECT	Product,
			CASE WHEN Timeslot = 1 THEN Quantity ELSE 0 END AS [11to3],
			CASE WHEN Timeslot = 2 THEN Quantity ELSE 0 END AS [3to7],
			CASE WHEN Timeslot = 3 THEN Quantity ELSE 0 END AS [7to11],
			CASE WHEN Timeslot = 4 THEN Quantity ELSE 0 END AS [OutOfHours],
			[WeekDay]
	FROM	(SELECT	DLData.Product, 
				DATEPART(w, MasterDates.[Date]) AS [WeekDay], 
				CASE 
				WHEN DLData.Shift >= 12 AND DLData.Shift <= 15 THEN 1
				WHEN DLData.Shift >= 16 AND DLData.Shift <= 19 THEN 2
				WHEN DLData.Shift >= 20 AND DLData.Shift <= 23 THEN 3
				ELSE 4 END AS Timeslot,
				DLData.Quantity
		FROM dbo.DLData
		JOIN dbo.MasterDates ON MasterDates.[ID] = DLData.DownloadID
		JOIN dbo.Sites ON MasterDates.EDISID = Sites.EDISID
		WHERE Sites.SiteID = @SiteID
		AND MasterDates.[Date] BETWEEN @StartDate AND @EndDate
		AND MasterDates.[Date] >= Sites.SiteOnline) AS DayTimes) AS Timeslots
JOIN dbo.Products ON Products.[ID] = Timeslots.Product
GROUP BY Products.[Description], [WeekDay]
ORDER BY Products.[Description], [WeekDay]


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetOutletProductData] TO PUBLIC
    AS [dbo];

