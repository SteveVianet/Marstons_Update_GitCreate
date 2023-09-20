CREATE FUNCTION dbo.fnVarianceSummaryDispensed
(
	@StartDate 	DATETIME, 
	@EndDate 	DATETIME,
	@ScheduleID	INT,
	@ProductTied	BIT
)

RETURNS TABLE 

AS

RETURN (SELECT	Sites.SiteID, 	
		SUM(DLData.Quantity) AS Quantity,
		dbo.fnGetMonday(MasterDates.[Date]) AS [Date]
	FROM dbo.Sites
	INNER JOIN dbo.ScheduleSites ON ScheduleSites.EDISID = Sites.EDISID
	INNER JOIN dbo.MasterDates ON MasterDates.EDISID = Sites.EDISID
					AND MasterDates.[Date] BETWEEN @StartDate AND @EndDate
					AND MasterDates.[Date] >= Sites.SiteOnline
	INNER JOIN dbo.DLData ON DLData.DownloadID = MasterDates.[ID]
	INNER JOIN dbo.Products ON Products.[ID] = DLData.Product
					AND Products.Tied = @ProductTied
	WHERE ScheduleSites.ScheduleID = @ScheduleID
	GROUP BY Sites.SiteID, dbo.fnGetMonday(MasterDates.[Date]))


