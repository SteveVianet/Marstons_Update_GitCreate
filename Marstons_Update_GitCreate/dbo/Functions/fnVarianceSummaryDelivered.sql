CREATE FUNCTION dbo.fnVarianceSummaryDelivered
(
	@StartDate 	DATETIME, 
	@EndDate 	DATETIME,
	@ScheduleID	INT,
	@ProductTied	BIT
)

RETURNS TABLE 

AS

RETURN (SELECT	Sites.SiteID,
		SUM(Delivery.Quantity) * 4.546 / 0.568 AS Quantity,
		dbo.fnGetMonday(MasterDates.[Date]) AS [Date]
	FROM dbo.Sites
	INNER JOIN dbo.ScheduleSites ON ScheduleSites.EDISID = Sites.EDISID
	INNER JOIN dbo.MasterDates ON MasterDates.EDISID = Sites.EDISID
					AND MasterDates.[Date] BETWEEN @StartDate AND @EndDate
					AND MasterDates.[Date] >= Sites.SiteOnline
	INNER JOIN dbo.Delivery ON Delivery.DeliveryID = MasterDates.[ID]
	INNER JOIN dbo.Products ON Products.[ID] = Delivery.Product
					AND Products.Tied = @ProductTied
	WHERE ScheduleSites.ScheduleID = @ScheduleID
	GROUP BY Sites.SiteID, dbo.fnGetMonday(MasterDates.[Date]))


