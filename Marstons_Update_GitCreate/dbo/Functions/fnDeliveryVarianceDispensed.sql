CREATE FUNCTION dbo.fnDeliveryVarianceDispensed
(
	@StartDate 	DATETIME, 
	@EndDate 	DATETIME,
	@EDISID		INT
)

RETURNS TABLE 

AS

RETURN (SELECT	Products.[ID] AS Product,
		dbo.fnGetMonday(MasterDates.[Date]) AS [Date],
		SUM(DLData.Quantity) AS Quantity
	FROM dbo.DLData
	JOIN dbo.Products ON Products.[ID] = DLData.Product
	JOIN dbo.MasterDates ON MasterDates.[ID] = DLData.DownloadID
	WHERE MasterDates.EDISID = @EDISID
	AND MasterDates.[Date] BETWEEN @StartDate AND @EndDate
	GROUP BY Products.[ID], dbo.fnGetMonday(MasterDates.[Date]))


