CREATE PROCEDURE [dbo].[AddDispenseCondition]
(
	@EDISID 			INT, 
	@Date				DATETIME,
	@Pump			INT,
	@StartTime			DATETIME,
	@Duration 			FLOAT, 
	@PercentageOfPint 		FLOAT, 
	@AverageTemperature	FLOAT = NULL, 
	@MinimumTemperature	FLOAT =NULL, 
	@LiquidType			INT,
	@ProductID			INT = NULL,
	@MaximumTemperature	FLOAT = NULL, 
	@AverageConductivity		INT=NULL, 
	@MinimumConductivity		INT =NULL, 
	@MaximumConductivity		INT=NULL
)

AS

DECLARE @ProductIsMetric		BIT
DECLARE @NewPercentageOfPint	FLOAT
DECLARE @TradingDate		DATETIME
DECLARE @Location		INT
DECLARE @DateAndTime	DATETIME
DECLARE @Error VARCHAR(1024)

SET NOCOUNT ON

-- Get Trading Day
SELECT @TradingDate = CASE WHEN DATEPART(Hour, @StartTime) < 5 THEN DATEADD(Day, -1, @Date) ELSE @Date END

SET @DateAndTime = @Date + CONVERT(VARCHAR(10), @StartTime, 8)

-- Get LocationID from Pump Number
SET @Location = dbo.fnGetLocationFromPump(@EDISID, @Pump, @Date)

IF @Location IS NOT NULL
BEGIN
	-- Find historical product if we need to
	IF @ProductID IS NULL
	BEGIN
		SELECT @ProductID = ProductID, @ProductIsMetric = IsMetric
		FROM dbo.PumpSetup
		JOIN dbo.Products ON dbo.Products.ID = dbo.PumpSetup.ProductID
		WHERE EDISID = @EDISID
		AND Pump = @Pump
		AND ValidFrom <= @Date
		AND (ValidTo >= @Date OR ValidTo IS NULL)

		IF @ProductID IS NULL
		BEGIN
			SELECT @ProductID = ID, @ProductIsMetric = IsMetric
			FROM dbo.Products
			WHERE [Description] = '0'
		END

		IF @ProductIsMetric = 1
		BEGIN
			SET @NewPercentageOfPint = (@PercentageOfPint / 5.0) * 1.75975326
		END
		ELSE
		BEGIN
			SET @NewPercentageOfPint = @PercentageOfPint
		END

	END
	ELSE
	BEGIN
		SELECT @ProductIsMetric = IsMetric
		FROM dbo.Products
		WHERE [ID] = @ProductID

		SET @NewPercentageOfPint = @PercentageOfPint
	END

	SELECT @LiquidType = (CASE 
			WHEN @ProductIsMetric = 1 THEN 2
			ELSE @LiquidType
		END)
		
	SET NOCOUNT OFF

	IF (@NewPercentageOfPint > 0.009) OR (@ProductIsMetric = 1)
	BEGIN
		INSERT INTO dbo.DispenseActions
		(EDISID, StartTime, TradingDay, Pump, Location, Product, Duration, AverageTemperature, MinimumTemperature, MaximumTemperature, LiquidType, IFMLiquidType, AverageConductivity, MinimumConductivity, MaximumConductivity, Pints, EstimatedDrinks)
		VALUES
		(@EDISID, @DateAndTime, @TradingDate, @Pump, @Location, @ProductID, @Duration, @AverageTemperature, @MinimumTemperature, @MaximumTemperature, @LiquidType, NULL, @AverageConductivity, @MinimumConductivity, @MaximumConductivity, @NewPercentageOfPint, dbo.fnGetSiteDrinkVolume(@EDISID, @NewPercentageOfPint*100, @ProductID) )
	END

END
ELSE
BEGIN
	SET @Error = 'Location cannot be found for EDISID ' + CAST(@EDISID AS VARCHAR) + ' Pump ' + CAST(@Pump AS VARCHAR) + ' Date ' + CAST(@Date AS VARCHAR)
	EXEC dbo.LogError 101, @Error, 'SP', 'AddDispenseCondition'
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddDispenseCondition] TO PUBLIC
    AS [dbo];

