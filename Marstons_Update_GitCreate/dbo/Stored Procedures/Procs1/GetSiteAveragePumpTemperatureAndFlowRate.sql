CREATE PROCEDURE dbo.[GetSiteAveragePumpTemperatureAndFlowRate]
(
	@EDISID		INT,
	@PumpID		INT = NULL,
	@FromDate	DATETIME,
	@ToDate		DATETIME,
	@Hour		INT = NULL
)
AS

SET NOCOUNT ON


SELECT 	Pump,
		Product,
		AVG(MinimumTemperature) AS OldAverageTemperature,
		SUM(Pints*MinimumTemperature)/SUM(Pints) AS AverageTemperature,
		AVG(CAST(Duration AS FLOAT)/Pints*0.95) AS AverageFlowRate
		FROM DispenseActions
		JOIN Sites ON DispenseActions.EDISID = Sites.EDISID
		WHERE DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) BETWEEN @FromDate AND @ToDate
		AND DispenseActions.EDISID = @EDISID
		AND DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) >= Sites.SiteOnline
		AND (DispenseActions.Pump = @PumpID OR @PumpID IS NULL)
		AND DispenseActions.LiquidType = 2
		AND DispenseActions.Pints >= 0.3
		AND (DATEPART(hh, StartTime) = @Hour OR @Hour IS NULL )
GROUP BY	Product, Pump

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteAveragePumpTemperatureAndFlowRate] TO PUBLIC
    AS [dbo];

