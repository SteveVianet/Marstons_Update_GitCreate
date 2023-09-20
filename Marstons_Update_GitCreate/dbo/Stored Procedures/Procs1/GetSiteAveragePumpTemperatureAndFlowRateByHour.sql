CREATE PROCEDURE dbo.[GetSiteAveragePumpTemperatureAndFlowRateByHour]
(
	@EDISID	INT,
	@PumpID	INT = NULL,
	@FromDate	DATETIME,
	@ToDate	DATETIME
)
AS

SET NOCOUNT ON

DECLARE @MasterDates TABLE([ID] INT NOT NULL, MDate DATETIME NOT NULL)

INSERT INTO @MasterDates
	SELECT MasterDates.[ID],MasterDates.[Date]
	FROM MasterDates
	JOIN Sites ON MasterDates.EDISID = Sites.EDISID
	WHERE MasterDates.Date BETWEEN @FromDate AND @ToDate
	AND MasterDates.EDISID = @EDISID
	AND MasterDates.Date >= Sites.SiteOnline


SELECT 	DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) AS [Date],
		Pump,
		Product,
		AVG(MinimumTemperature) AS OldAverageTemperature,
		SUM(Pints*MinimumTemperature)/SUM(Pints) AS AverageTemperature,
		AVG(CAST(Duration AS FLOAT)/Pints*0.95) AS AverageFlowRate,
		DATEPART(hh, StartTime) As [Hour]
		FROM DispenseActions
		JOIN Sites ON DispenseActions.EDISID = Sites.EDISID
		WHERE DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) BETWEEN @FromDate AND @ToDate
		AND DispenseActions.EDISID = @EDISID
		AND DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) >= Sites.SiteOnline
		AND (DispenseActions.Pump = @PumpID OR @PumpID IS NULL)
		AND DispenseActions.LiquidType = 2
		AND DispenseActions.Pints >= 0.3
GROUP BY	DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)), Product, Pump, DATEPART(hh, StartTime)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteAveragePumpTemperatureAndFlowRateByHour] TO PUBLIC
    AS [dbo];

