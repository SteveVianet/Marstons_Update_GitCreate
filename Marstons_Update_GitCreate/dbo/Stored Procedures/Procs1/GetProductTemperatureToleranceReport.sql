CREATE PROCEDURE dbo.[GetProductTemperatureToleranceReport]
(
	@ScheduleID		INT,
	@FromDate		DATETIME,
	@ToDate		DATETIME,
	@AmberTolerance	INT = 0
)

AS

SET NOCOUNT ON


SELECT DrinkSpecsSummary.ProductID,
	Products.TemperatureSpecification AS Specification,
	Products.TemperatureTolerance AS Tolerance,
	DrinkSpecsSummary.OutOfTolerance AS NumberOfPintsOutOfSpec,
	DrinkSpecsSummary.InTolerance AS NumberOfPintsInSpec
FROM	(SELECT	ProductID,
		SUM(OutOfTolerance)/100.0 AS OutOfTolerance,
		SUM(InTolerance)/100.0 AS InTolerance
	FROM	(SELECT	Products.[ID] AS ProductID,
			CASE	WHEN DispenseActions.MinimumTemperature > (Products.TemperatureSpecification + TemperatureTolerance + @AmberTolerance) THEN CAST(DispenseActions.Pints*100 AS INTEGER)
				WHEN DispenseActions.MinimumTemperature < (Products.TemperatureSpecification - TemperatureTolerance - @AmberTolerance) THEN CAST(DispenseActions.Pints*100 AS INTEGER)
				ELSE 0 END AS OutOfTolerance,
			CASE	WHEN DispenseActions.MinimumTemperature <= (Products.TemperatureSpecification + TemperatureTolerance + @AmberTolerance) AND DispenseActions.MinimumTemperature >= (Products.TemperatureSpecification - TemperatureTolerance - @AmberTolerance) THEN CAST(DispenseActions.Pints*100 AS INTEGER)
				ELSE 0 END AS InTolerance
		FROM DispenseActions
		JOIN ScheduleSites ON DispenseActions.EDISID = ScheduleSites.EDISID
		JOIN Products ON Products.ID = DispenseActions.Product
		JOIN Sites ON Sites.EDISID = ScheduleSites.EDISID
		WHERE DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) BETWEEN @FromDate AND @ToDate
		AND DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) >= Sites.SiteOnline
		AND ScheduleSites.ScheduleID = @ScheduleID
		AND (NOT Products.TemperatureSpecification IS NULL)
		AND (NOT Products.TemperatureTolerance IS NULL)
		AND Pints >= 0.3
		AND LiquidType = 2) AS DrinkSpecs
	GROUP BY ProductID) AS DrinkSpecsSummary JOIN Products ON Products.[ID] = DrinkSpecsSummary.ProductID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetProductTemperatureToleranceReport] TO PUBLIC
    AS [dbo];

