CREATE PROCEDURE dbo.[GetSiteDispenseIntervalReportByPumpDay]
(
	@EDISID 	INT,
	@From 	SMALLDATETIME,
	@To 		SMALLDATETIME,
	@Interval	INT
)
AS

SET DATEFIRST 1
SET NOCOUNT ON

-- This should be enhanced to not include hours with line cleaning

SELECT	DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) AS Date,
	DATEPART(hh,DispenseActions.StartTime)+1 AS Shift,
	(DATEPART(n, DispenseActions.StartTime)/@Interval)*@Interval AS Interval,
	Pump,
	SUM(DispenseActions.Pints) AS Quantity,
	SUM(Pints*AverageTemperature)/SUM(Pints) AS AverageTemperature,
	AVG(Duration/Pints) AS AverageFlowRate
FROM dbo.DispenseActions
JOIN dbo.Sites ON Sites.EDISID = DispenseActions.EDISID
WHERE DispenseActions.EDISID = @EDISID
AND DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime))  BETWEEN @From AND @To
AND DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime))  >= Sites.SiteOnline
AND DispenseActions.LiquidType IN (0,2)
AND DispenseActions.Pints >= 0.10
GROUP BY DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)), DATEPART(hh,DispenseActions.StartTime)+1, (DATEPART(n, DispenseActions.StartTime)/@Interval), (DATEPART(n, DispenseActions.StartTime)/@Interval)*@Interval, Pump
ORDER BY DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)), DATEPART(hh,DispenseActions.StartTime)+1, (DATEPART(n, DispenseActions.StartTime)/@Interval), Pump

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteDispenseIntervalReportByPumpDay] TO PUBLIC
    AS [dbo];

