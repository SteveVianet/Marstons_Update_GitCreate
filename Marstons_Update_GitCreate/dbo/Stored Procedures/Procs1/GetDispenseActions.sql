CREATE PROCEDURE [dbo].[GetDispenseActions]
(
	@EDISID 			INT, 
	@MinTradingDate		DATETIME = NULL,
	@MaxTradingDate		DATETIME = NULL
)

AS

SELECT	StartTime, 
		TradingDay, 
		Pump, 
		Location, 
		Product, 
		Duration, 
		AverageTemperature, 
		MinimumTemperature,
		MaximumTemperature, 
		LiquidType, 
		OriginalLiquidType, 
		AverageConductivity, 
		MinimumConductivity, 
		MaximumConductivity, 
		Pints, 
		PintsBackup, 
		EstimatedDrinks, 
		IFMLiquidType
FROM
	dbo.DispenseActions
WHERE
	EDISID = @EDISID
AND
	( (TradingDay >= @MinTradingDate) OR (@MinTradingDate IS NULL) )
AND 
	( (TradingDay <= @MaxTradingDate) OR (@MaxTradingDate IS NULL) )

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDispenseActions] TO PUBLIC
    AS [dbo];

