CREATE PROCEDURE dbo.[GetProductTemperatureToleranceReport2]
(
	@ScheduleID		INT,
	@FromDate		DATETIME,
	@ToDate		DATETIME,
	@AmberTolerance	INT = 0
)

AS

SET NOCOUNT ON

DECLARE @InnerScheduleID INT
DECLARE @InnerFromDate DATETIME
DECLARE @InnerToDate DATETIME
DECLARE @InnerAmberTolerance INT
SET @InnerScheduleID = @ScheduleID
SET @InnerFromDate = @FromDate
SET @InnerToDate = @ToDate
SET @InnerAmberTolerance = @AmberTolerance


SELECT DrinkSpecsSummary.ProductID,
	Products.TemperatureSpecification AS Specification,
	Products.TemperatureTolerance AS Tolerance,
	DrinkSpecsSummary.OutOfTolerance AS NumberOfPintsOutOfSpec,
	DrinkSpecsSummary.InTolerance AS NumberOfPintsInSpec
FROM	(SELECT ProductID,
		SUM(OutOfTolerance)/100.0 AS OutOfTolerance,
		SUM(InTolerance)/100.0 AS InTolerance
	FROM	(SELECT Products.[ID] AS ProductID,
			CASE	WHEN DispenseActions.MinimumTemperature >= (Products.TemperatureSpecification + TemperatureTolerance + @InnerAmberTolerance) THEN DispenseActions.Pints/100
				ELSE 0 END AS OutOfTolerance,
			CASE	WHEN DispenseActions.MinimumTemperature < (Products.TemperatureSpecification + TemperatureTolerance + @InnerAmberTolerance) THEN DispenseActions.Pints/100
				ELSE 0 END AS InTolerance
		FROM DispenseActions
		JOIN ScheduleSites ON DispenseActions.EDISID = ScheduleSites.EDISID
		JOIN Products ON Products.ID = DispenseActions.Product
		JOIN Sites ON Sites.EDISID = ScheduleSites.EDISID
		WHERE ScheduleSites.ScheduleID = @InnerScheduleID
		AND DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime))  BETWEEN @InnerFromDate AND @InnerToDate
		AND Pints >= 0.3
		AND LiquidType = 2
		AND DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) >= Sites.SiteOnline
		AND (NOT Products.TemperatureSpecification IS NULL)
		AND (NOT Products.TemperatureTolerance IS NULL)) AS DrinkSpecs
	GROUP BY ProductID) AS DrinkSpecsSummary 
JOIN Products ON Products.[ID] = DrinkSpecsSummary.ProductID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetProductTemperatureToleranceReport2] TO PUBLIC
    AS [dbo];

