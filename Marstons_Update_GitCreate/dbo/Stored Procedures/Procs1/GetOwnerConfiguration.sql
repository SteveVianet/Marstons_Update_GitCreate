
CREATE PROCEDURE [dbo].[GetOwnerConfiguration]
(
	@OwnerID					INT
)
AS

SET NOCOUNT ON

SELECT	ID AS OwnerID,
		Name,
		PouringYieldCashValue,
		CleaningCashValue,
		POSYieldCashValue,
		ThroughputLowValue, 	
		ThroughputAmberTaps, 	
		ThroughputRedTaps,
		TargetPouringYieldPercent,
		PouringYieldAmberPercentFromTarget, 
		PouringYieldRedPercentFromTarget,
		TargetTillYieldPercent,
		TillYieldAmberPercentFromTarget,
		TillYieldRedPercentFromTarget, 
		TemperatureAmberPercentTarget, 	
		TemperatureRedPercentTarget, 		
		CleaningAmberPercentTarget, 	
		CleaningRedPercentTarget
FROM Owners
WHERE ID = @OwnerID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetOwnerConfiguration] TO PUBLIC
    AS [dbo];

