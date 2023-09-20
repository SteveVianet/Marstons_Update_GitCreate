
CREATE PROCEDURE [dbo].[GetWebOwnerExceptionConfiguration]
(
	@OwnerID		INT = NULL
)
AS

SET NOCOUNT ON

SELECT	ID AS OwnerID,
		OverallYieldAlarmsEnabled,
		OverallYieldLowPercentThreshold,
		RetailYieldAlarmsEnabled,
		RetailYieldLowPercentThreshold,
		PouringYieldAlarmsEnabled,
		PouringYieldLowPercentThreshold,
		CleaningAlarmsEnabled,
		CleaningLowVolumeThreshold,
		OverallYieldHighVolumeThreshold,
		RetailYieldHighVolumeThreshold,
		ProductTempAlarmsEnabled,
		ProductTempHighPercentThreshold,
		OutOfHoursDispenseAlarmsEnabled,
		OutOfHoursDispenseMinThreshold,
		NoDataAlarmsEnabled,
		AllowSiteExceptionConfigurationOverride
FROM Owners
WHERE ID = @OwnerID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebOwnerExceptionConfiguration] TO PUBLIC
    AS [dbo];

