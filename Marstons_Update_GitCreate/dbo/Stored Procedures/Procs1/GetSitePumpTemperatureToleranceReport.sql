CREATE PROCEDURE dbo.[GetSitePumpTemperatureToleranceReport]
(
	@EDISID		INT,
	@FromDate		DATETIME,
	@ToDate		DATETIME,
	@AmberTolerance	INT = 0,
	@IgnoreBelowSpec	BIT = 0
)
AS

SET NOCOUNT ON

SELECT	DrinkSpecsSummary.Pump,
	DrinkSpecsSummary.ProductID,
	Products.TemperatureSpecification AS Specification,
	Products.TemperatureTolerance AS Tolerance,
	DrinkSpecsSummary.OutOfTolerance AS NumberOfPintsOutOfSpec,
	DrinkSpecsSummary.InTolerance AS NumberOfPintsInSpec
FROM	(SELECT	Pump, ProductID,
		SUM(OutOfTolerance)/100.0 AS OutOfTolerance,
		SUM(InTolerance)/100.0 AS InTolerance
	FROM	(SELECT	Pump,
				Products.[ID] AS ProductID,
			CASE	WHEN DispenseActions.MinimumTemperature > (Products.TemperatureSpecification + TemperatureTolerance + @AmberTolerance) THEN CAST(DispenseActions.Pints*100 AS INTEGER)
				WHEN DispenseActions.MinimumTemperature < (Products.TemperatureSpecification - TemperatureTolerance - @AmberTolerance) THEN CAST(DispenseActions.Pints*100 AS INTEGER)
				ELSE 0 END AS OutOfTolerance,
			CASE	WHEN DispenseActions.MinimumTemperature <= (Products.TemperatureSpecification + TemperatureTolerance + @AmberTolerance) AND DispenseActions.MinimumTemperature >= (Products.TemperatureSpecification - TemperatureTolerance - @AmberTolerance) THEN CAST(DispenseActions.Pints*100 AS INTEGER)
				ELSE 0 END AS InTolerance
		FROM DispenseActions
		JOIN Products ON Products.ID = DispenseActions.Product
		JOIN Sites ON Sites.EDISID = DispenseActions.EDISID
		WHERE DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) BETWEEN @FromDate AND @ToDate
		AND DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) >= Sites.SiteOnline
		AND DispenseActions.EDISID = @EDISID
		AND Pints >= 0.3
		AND LiquidType = 2) AS DrinkSpecs
	GROUP BY Pump, ProductID) AS DrinkSpecsSummary JOIN Products ON Products.[ID] = DrinkSpecsSummary.ProductID
ORDER BY Pump

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSitePumpTemperatureToleranceReport] TO PUBLIC
    AS [dbo];

