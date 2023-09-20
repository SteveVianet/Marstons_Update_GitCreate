CREATE PROCEDURE [dbo].[GetTotalWaterDays]
(
	@EDISID	INT,
	@StartDate	DATETIME,
	@EndDate	DATETIME
)

AS

SELECT COUNT(*) 
FROM	(SELECT MasterDates.[Date]
		FROM dbo.WaterStack
		JOIN dbo.MasterDates
		ON MasterDates.[ID] = WaterStack.WaterID
		WHERE MasterDates.EDISID = @EDISID
		AND MasterDates.[Date] BETWEEN @StartDate AND @EndDate
		GROUP BY MasterDates.[Date])
AS TotalWaterDays