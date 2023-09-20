CREATE PROCEDURE [dbo].[AddDispenseConditionRaw]
(
	@EDISID 			INT, 
	@StartDateAndTime		DATETIME,
	@FlowmeterAddress		INT,
	@Duration 			FLOAT, 
	@PulseCount	 		INT, 
	@LiquidType			INT,
	@AverageTemperature	FLOAT, 
	@MinimumTemperature	FLOAT, 
	@MaximumTemperature	FLOAT, 
	@AverageConductivity		INT, 
	@MinimumConductivity		INT, 
	@MaximumConductivity		INT
)

AS

-- Takes unscaled pulse count: will lookup scalar, logical address and product details

DECLARE @ProductIsMetric	BIT
DECLARE @ProductID		INT
DECLARE @Prescalar		INT
DECLARE @StartTime		DATETIME
DECLARE @StartDate		DATETIME
DECLARE @TradingDate	DATETIME
DECLARE @Pump		INT
DECLARE @Location		INT
DECLARE @Pints		FLOAT

DECLARE @Error VARCHAR(1024)

SET NOCOUNT ON

SET @StartDate = CAST(CONVERT(VARCHAR(10), @StartDateAndTime, 12) AS DATETIME)
SET @StartTime = CAST('1899-12-30 ' + CONVERT(VARCHAR(10), @StartDateAndTime, 8) AS DATETIME)
SELECT @TradingDate = CASE WHEN DATEPART(Hour, @StartTime) < 5 THEN DATEADD(Day, -1, @StartDate) ELSE @StartDate END

-- Find logical address (required)
SET @Pump = dbo.fnGetPumpFromFlowmeterAddress(@EDISID, @FlowmeterAddress, @StartDate)

-- Find pump location (required)
SET @Location = dbo.fnGetLocationFromPump(@EDISID, @Pump, @StartDate)

IF @Pump IS NOT NULL
BEGIN
	IF @Location IS NOT NULL
	BEGIN
		-- Find scalar and scale data
		SET @Prescalar = dbo.fnGetPrescalar(@EDISID, @Pump, @StartDate)
		IF @Prescalar IS NOT NULL
		BEGIN
			SET @Pints = CAST(@PulseCount AS FLOAT) / (CAST(@Prescalar AS FLOAT) * 2)
		END

		IF @Prescalar IS NOT NULL
		BEGIN
			-- Find historical product
			SELECT @ProductID = ProductID, @ProductIsMetric = IsMetric
			FROM dbo.PumpSetup
			JOIN dbo.Products ON dbo.Products.ID = dbo.PumpSetup.ProductID
			WHERE EDISID = @EDISID
			AND Pump = @Pump
			AND ValidFrom <= @StartDate
			AND (ValidTo >= @StartDate OR ValidTo IS NULL)
			
			IF @ProductID IS NULL
			BEGIN
				SELECT @ProductID = ID, @ProductIsMetric = IsMetric
				FROM dbo.Products
				WHERE [Description] = '0'
			END
			
			IF @ProductIsMetric = 1
			BEGIN
				SET @Pints = (@Pints / 5.0) * 1.75975326
			END
			
			SELECT @LiquidType = (CASE 
					WHEN @ProductIsMetric = 1 THEN 2
					ELSE @LiquidType
				END)

			IF (@Pints > 0.009) OR (@ProductIsMetric = 1)
			BEGIN
				INSERT INTO dbo.DispenseActions
				(EDISID, StartTime, TradingDay, Pump, Location, Product, Duration, AverageTemperature, MinimumTemperature, MaximumTemperature, LiquidType, IFMLiquidType, AverageConductivity, MinimumConductivity, MaximumConductivity, Pints, EstimatedDrinks)
				VALUES
				(@EDISID, @StartDateAndTime, @TradingDate, @Pump, @Location, @ProductID, @Duration, @AverageTemperature, @MinimumTemperature, @MaximumTemperature, @LiquidType, NULL, @AverageConductivity, @MinimumConductivity, @MaximumConductivity, @Pints, dbo.fnGetSiteDrinkVolume(@EDISID, @Pints*100, @ProductID) )
				
			END
		END
		ELSE
		BEGIN
			SET @Error = 'Prescalar cannot be found for EDISID ' + CAST(@EDISID AS VARCHAR) + ' Pump ' + CAST(@Pump AS VARCHAR) + ' Date ' + CAST(@StartDate AS VARCHAR)
			EXEC dbo.LogError 100, @Error, 'Data Import Service', 'AddDispenseConditionRaw'
		END
	END
	ELSE
	BEGIN
		SET @Error = 'Location cannot be found for EDISID ' + CAST(@EDISID AS VARCHAR) + ' Pump ' + CAST(@Pump AS VARCHAR) + ' Date ' + CAST(@StartDate AS VARCHAR)
		EXEC dbo.LogError 100, @Error, 'Data Import Service', 'AddDispenseConditionRaw'
	END
END
ELSE
BEGIN
	SET @Error = 'Pump cannot be found for EDISID ' + CAST(@EDISID AS VARCHAR) + ' FlowmeterAddress ' + CAST(@FlowmeterAddress AS VARCHAR) + ' Date ' + CAST(@StartDate AS VARCHAR)
	EXEC dbo.LogError 101, @Error, 'Data Import Service', 'AddDispenseConditionRaw'
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddDispenseConditionRaw] TO PUBLIC
    AS [dbo];

