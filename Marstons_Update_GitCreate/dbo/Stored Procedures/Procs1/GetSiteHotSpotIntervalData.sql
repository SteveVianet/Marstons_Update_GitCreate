CREATE PROCEDURE dbo.[GetSiteHotSpotIntervalData]
(
	@EDISID	INT,
	@From		DATETIME,
	@To		DATETIME,
	@Interval	INT
)

AS

SET DATEFIRST 1

SELECT	DATEPART(dw, StartTime) AS DayOfWeek,
	DATEPART(hh,DispenseActions.StartTime)+1 AS Shift,
	(DATEPART(n, DispenseActions.StartTime)/@Interval)*@Interval AS Interval,
	SUM(DispenseActions.Pints) AS Quantity,
	AVG(AverageTemperature) AS AverageTemperature,
	AVG(Duration/Pints) AS AverageFlowRate
FROM dbo.DispenseActions
JOIN dbo.Sites ON Sites.EDISID = DispenseActions.EDISID
WHERE DispenseActions.EDISID = @EDISID
AND DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) BETWEEN @From AND @To
AND DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) >= Sites.SiteOnline
AND DispenseActions.LiquidType = 2
GROUP BY DATEPART(dw, StartTime), DATEPART(hh,DispenseActions.StartTime)+1, (DATEPART(n, DispenseActions.StartTime)/@Interval), (DATEPART(n, DispenseActions.StartTime)/@Interval)*@Interval
ORDER BY DATEPART(dw, StartTime), DATEPART(hh,DispenseActions.StartTime)+1, (DATEPART(n, DispenseActions.StartTime)/@Interval)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteHotSpotIntervalData] TO PUBLIC
    AS [dbo];

