CREATE PROCEDURE [dbo].[GetDispenseConditions]
(
	@EDISID			        INT,
	@Date				    SMALLDATETIME,
	@PumpID			        INT = NULL,
	@MinDuration			INT = NULL,
	@MaxDuration			INT = NULL,
	@LiquidType			    INT = NULL,
	@MinMinimumTemperature	FLOAT = NULL,
	@MaxMinimumTemperature	FLOAT = NULL,
	@MinAverageTemperature	FLOAT = NULL,
	@MaxAverageTemperature	FLOAT = NULL,
	@MinDrinks			    FLOAT = NULL,
	@MinMaximumTemperature	FLOAT = NULL,
	@MaxMaximumTemperature	FLOAT = NULL
)

AS

SELECT	DispenseActions.Pump,
		DispenseActions.StartTime,
		DispenseActions.Duration,
		DispenseActions.Pints,
		DispenseActions.AverageTemperature,
		DispenseActions.MinimumTemperature,
		DispenseActions.LiquidType,
		DispenseActions.Product AS ProductID,
		DispenseActions.OriginalLiquidType,
		EstimatedDrinks AS Drinks,
		DispenseActions.MaximumTemperature,
		DispenseActions.AverageConductivity,
		DispenseActions.MinimumConductivity,
		DispenseActions.MaximumConductivity
FROM dbo.DispenseActions
JOIN dbo.Products ON Products.[ID] = DispenseActions.Product
WHERE DispenseActions.EDISID = @EDISID
AND DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) = @Date
AND (@PumpID IS NULL			OR 	Pump = @PumpID)
AND (@MinDuration IS NULL			OR	Duration >= @MinDuration)
AND (@MaxDuration IS NULL			OR	Duration <= @MaxDuration)
AND (@LiquidType IS NULL			OR 	LiquidType = @LiquidType)
AND (@MinMinimumTemperature IS NULL	OR	MinimumTemperature >= @MinMinimumTemperature)
AND (@MaxMinimumTemperature IS NULL	OR	MinimumTemperature <= @MaxMinimumTemperature)
AND (@MinAverageTemperature IS NULL	OR	AverageTemperature >= @MinAverageTemperature)
AND (@MaxAverageTemperature IS NULL	OR	AverageTemperature <= @MaxAverageTemperature)
AND (@MinDrinks IS NULL			OR	EstimatedDrinks  >= @MinDrinks)
AND (@MinMaximumTemperature IS NULL	OR	MaximumTemperature >= @MinMaximumTemperature)
AND (@MaxMaximumTemperature IS NULL	OR	MaximumTemperature <= @MaxMaximumTemperature)
ORDER BY DispenseActions.Pump, DispenseActions.StartTime


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDispenseConditions] TO PUBLIC
    AS [dbo];

