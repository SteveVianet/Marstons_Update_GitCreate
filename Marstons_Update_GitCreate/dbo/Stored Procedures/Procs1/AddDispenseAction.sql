CREATE PROCEDURE [dbo].[AddDispenseAction]
(
	@EDISID 			INT, 
	@StartTime			DATETIME,
	@TradingDate		DATETIME,
	@Pump				INT,
	@ProductID			INT,
	@LiquidType			INT,
	@OriginalLiquidType	INT = NULL,
	@IFMLiquidType		INT = NULL,
	@Location			INT = NULL,
	@Duration 			FLOAT = NULL,
	@Pints				FLOAT = NULL,
	@PintsBackup		FLOAT = NULL,
	@EstimatedDrinks	FLOAT = NULL,
	@AverageTemperature	FLOAT = NULL,
	@MinimumTemperature	FLOAT = NULL,
	@MaximumTemperature	FLOAT = NULL, 
	@AverageConductivity		INT = NULL, 
	@MinimumConductivity		INT = NULL, 
	@MaximumConductivity		INT = NULL
)

AS

INSERT INTO DispenseActions
	(EDISID, StartTime, TradingDay, Pump, Location, Product, Duration, AverageTemperature, MinimumTemperature,
	 MaximumTemperature, LiquidType, OriginalLiquidType, AverageConductivity, MinimumConductivity, 
	 MaximumConductivity, Pints, PintsBackup, EstimatedDrinks, IFMLiquidType)
VALUES
	(@EDISID, @StartTime, @TradingDate, @Pump, @Location, @ProductID, @Duration, @AverageTemperature, @MinimumTemperature,
	 @MaximumTemperature, @LiquidType, @OriginalLiquidType, @AverageConductivity, @MinimumConductivity,
	 @MaximumConductivity, @Pints, @PintsBackup, @EstimatedDrinks, @IFMLiquidType)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddDispenseAction] TO PUBLIC
    AS [dbo];

