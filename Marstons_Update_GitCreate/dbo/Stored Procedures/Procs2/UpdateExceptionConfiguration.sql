
CREATE PROCEDURE [dbo].[UpdateExceptionConfiguration]
(
	@OwnerID									INT = NULL,
	@EDISID										INT = NULL,
	@OverallYieldAlarmsEnabled					BIT,
	@OverallYieldLowPercentThreshold			INT,
	@RetailYieldAlarmsEnabled					BIT,
	@RetailYieldLowPercentThreshold				INT,
	@PouringYieldAlarmsEnabled					BIT,
	@PouringYieldLowPercentThreshold			INT,
	@CleaningAlarmsEnabled						BIT,
	@CleaningLowVolumeThreshold					FLOAT,
	@OverallYieldHighVolumeThreshold			FLOAT,
	@RetailYieldHighVolumeThreshold				FLOAT,
	@ProductTempAlarmsEnabled					BIT,
	@ProductTempHighPercentThreshold			INT,
	@OutOfHoursDispenseAlarmsEnabled			BIT,
	@OutOfHoursDispenseMinThreshold				FLOAT,
	@NoDataAlarmsEnabled						BIT,
	@AllowSiteExceptionConfigurationOverride	BIT = 0
)
AS

SET NOCOUNT ON

IF @OwnerID IS NOT NULL
BEGIN
	UPDATE dbo.Owners
	SET	OverallYieldAlarmsEnabled =	@OverallYieldAlarmsEnabled,
		OverallYieldLowPercentThreshold = @OverallYieldLowPercentThreshold,
		RetailYieldAlarmsEnabled = @RetailYieldAlarmsEnabled,
		RetailYieldLowPercentThreshold = @RetailYieldLowPercentThreshold,
		PouringYieldAlarmsEnabled = @PouringYieldAlarmsEnabled,
		PouringYieldLowPercentThreshold = @PouringYieldLowPercentThreshold,
		CleaningAlarmsEnabled = @CleaningAlarmsEnabled,
		CleaningLowVolumeThreshold = @CleaningLowVolumeThreshold,
		OverallYieldHighVolumeThreshold = @OverallYieldHighVolumeThreshold,
		RetailYieldHighVolumeThreshold = @RetailYieldHighVolumeThreshold,
		ProductTempAlarmsEnabled = @ProductTempAlarmsEnabled,
		ProductTempHighPercentThreshold = @ProductTempHighPercentThreshold,
		OutOfHoursDispenseAlarmsEnabled = @OutOfHoursDispenseAlarmsEnabled,
		OutOfHoursDispenseMinThreshold = @OutOfHoursDispenseMinThreshold,
		NoDataAlarmsEnabled = @NoDataAlarmsEnabled,
		AllowSiteExceptionConfigurationOverride = @AllowSiteExceptionConfigurationOverride
	WHERE ID = @OwnerID

END
ELSE IF @EDISID IS NOT NULL
BEGIN

	MERGE SiteExceptionConfiguration
	USING (
		SELECT	@EDISID AS EDISID,
				@OverallYieldAlarmsEnabled AS OverallYieldAlarmsEnabled,
				@OverallYieldLowPercentThreshold AS OverallYieldLowPercentThreshold,
				@RetailYieldAlarmsEnabled AS RetailYieldAlarmsEnabled,
				@RetailYieldLowPercentThreshold AS RetailYieldLowPercentThreshold,
				@PouringYieldAlarmsEnabled AS PouringYieldAlarmsEnabled,
				@PouringYieldLowPercentThreshold AS PouringYieldLowPercentThreshold,
				@CleaningAlarmsEnabled AS CleaningAlarmsEnabled,
				@CleaningLowVolumeThreshold AS CleaningLowVolumeThreshold,
				@OverallYieldHighVolumeThreshold AS OverallYieldHighVolumeThreshold,
				@RetailYieldHighVolumeThreshold AS RetailYieldHighVolumeThreshold,
				@ProductTempAlarmsEnabled AS ProductTempAlarmsEnabled,
				@ProductTempHighPercentThreshold AS ProductTempHighPercentThreshold,
				0 AS ThroughputAlarmsEnabled,
				0 AS ThroughputMinThreshold,
				@OutOfHoursDispenseAlarmsEnabled AS OutOfHoursDispenseAlarmsEnabled,
				@OutOfHoursDispenseMinThreshold AS OutOfHoursDispenseMinThreshold,
				@NoDataAlarmsEnabled AS NoDataAlarmsEnabled
	) AS ProposedSiteConfiguration
	ON SiteExceptionConfiguration.EDISID = ProposedSiteConfiguration.EDISID
	WHEN MATCHED THEN
	UPDATE SET	SiteExceptionConfiguration.OverallYieldAlarmsEnabled = @OverallYieldAlarmsEnabled,
				SiteExceptionConfiguration.OverallYieldLowPercentThreshold = @OverallYieldLowPercentThreshold,
				SiteExceptionConfiguration.RetailYieldAlarmsEnabled = @RetailYieldAlarmsEnabled,
				SiteExceptionConfiguration.RetailYieldLowPercentThreshold = @RetailYieldLowPercentThreshold,
				SiteExceptionConfiguration.PouringYieldAlarmsEnabled = @PouringYieldAlarmsEnabled,
				SiteExceptionConfiguration.PouringYieldLowPercentThreshold = @PouringYieldLowPercentThreshold,
				SiteExceptionConfiguration.CleaningAlarmsEnabled = @CleaningAlarmsEnabled,
				SiteExceptionConfiguration.CleaningLowVolumeThreshold = @CleaningLowVolumeThreshold,
				SiteExceptionConfiguration.OverallYieldHighVolumeThreshold = @OverallYieldHighVolumeThreshold,
				SiteExceptionConfiguration.RetailYieldHighVolumeThreshold = @RetailYieldHighVolumeThreshold,
				SiteExceptionConfiguration.ProductTempAlarmsEnabled = @ProductTempAlarmsEnabled,
				SiteExceptionConfiguration.ProductTempHighPercentThreshold = @ProductTempHighPercentThreshold,
				SiteExceptionConfiguration.OutOfHoursDispenseAlarmsEnabled = @OutOfHoursDispenseAlarmsEnabled,
				SiteExceptionConfiguration.OutOfHoursDispenseMinThreshold = @OutOfHoursDispenseMinThreshold,
				SiteExceptionConfiguration.NoDataAlarmsEnabled = @NoDataAlarmsEnabled
	WHEN NOT MATCHED THEN
	INSERT(EDISID, ProductTempAlarmsEnabled, ProductTempHighPercentThreshold, CleaningAlarmsEnabled, CleaningLowVolumeThreshold, OverallYieldHighVolumeThreshold, RetailYieldHighVolumeThreshold, OverallYieldAlarmsEnabled, OverallYieldLowPercentThreshold, PouringYieldAlarmsEnabled, PouringYieldLowPercentThreshold, RetailYieldAlarmsEnabled, RetailYieldLowPercentThreshold, ThroughputAlarmsEnabled, ThroughputMinThreshold, OutOfHoursDispenseAlarmsEnabled, OutOfHoursDispenseMinThreshold, NoDataAlarmsEnabled)
	VALUES(ProposedSiteConfiguration.EDISID, ProposedSiteConfiguration.ProductTempAlarmsEnabled, ProposedSiteConfiguration.ProductTempHighPercentThreshold, ProposedSiteConfiguration.CleaningAlarmsEnabled, ProposedSiteConfiguration.CleaningLowVolumeThreshold, ProposedSiteConfiguration.OverallYieldHighVolumeThreshold, ProposedSiteConfiguration.RetailYieldHighVolumeThreshold, ProposedSiteConfiguration.OverallYieldAlarmsEnabled, ProposedSiteConfiguration.OverallYieldLowPercentThreshold, ProposedSiteConfiguration.PouringYieldAlarmsEnabled, ProposedSiteConfiguration.PouringYieldLowPercentThreshold, ProposedSiteConfiguration.RetailYieldAlarmsEnabled, ProposedSiteConfiguration.RetailYieldLowPercentThreshold, ProposedSiteConfiguration.ThroughputAlarmsEnabled, ProposedSiteConfiguration.ThroughputMinThreshold, ProposedSiteConfiguration.OutOfHoursDispenseAlarmsEnabled, ProposedSiteConfiguration.OutOfHoursDispenseMinThreshold, ProposedSiteConfiguration.NoDataAlarmsEnabled);
	
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateExceptionConfiguration] TO PUBLIC
    AS [dbo];

