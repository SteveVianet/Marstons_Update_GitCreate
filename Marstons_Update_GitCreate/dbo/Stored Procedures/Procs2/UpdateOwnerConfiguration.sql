CREATE PROCEDURE [dbo].[UpdateOwnerConfiguration]
(
	@OwnerID					INT,
	@PouringYieldCashValue		FLOAT,
	@CleaningCashValue			FLOAT,
	@POSYieldCashValue			FLOAT,
	@ThroughputLowValue			INT,
	@ThroughputAmberTaps		INT,
	@ThroughputRedTaps			INT,
	@TargetPouringYieldPercent	INT,
	@PouringYieldAmberPercent	INT,
	@PouringYieldRedPercent		INT,
	@TargetTillYieldPercent		INT,
	@TillYieldAmberPercent		INT,
	@TillYieldRedPercent		INT,
	@TemperatureAmberPercent	INT,
	@TemperatureRedPercent		INT,
	@CleaningAmberPercent		INT,
	@CleaningRedPercent			INT
)
AS

SET NOCOUNT ON

UPDATE dbo.Owners
SET	PouringYieldCashValue = @PouringYieldCashValue,
	CleaningCashValue = @CleaningCashValue,
	POSYieldCashValue = @POSYieldCashValue,
	ThroughputLowValue = @ThroughputLowValue,		
	ThroughputAmberTaps = @ThroughputAmberTaps,		
	ThroughputRedTaps = @ThroughputRedTaps,
	TargetPouringYieldPercent = @TargetPouringYieldPercent,			
	PouringYieldAmberPercentFromTarget = @PouringYieldAmberPercent,	
	PouringYieldRedPercentFromTarget = @PouringYieldRedPercent,
	TargetTillYieldPercent = @TargetTillYieldPercent,
	TillYieldAmberPercentFromTarget = @TillYieldAmberPercent,		
	TillYieldRedPercentFromTarget = @TillYieldRedPercent,		
	TemperatureAmberPercentTarget = @TemperatureAmberPercent,	
	TemperatureRedPercentTarget = @TemperatureRedPercent,		
	CleaningAmberPercentTarget = @CleaningAmberPercent,		
	CleaningRedPercentTarget = @CleaningRedPercent			
WHERE ID = @OwnerID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateOwnerConfiguration] TO PUBLIC
    AS [dbo];

