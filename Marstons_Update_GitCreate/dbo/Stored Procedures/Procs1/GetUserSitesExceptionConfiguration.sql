CREATE PROCEDURE [dbo].[GetUserSitesExceptionConfiguration]
(
	@UserID		INT
)
AS

/* Debugging */
--DECLARE @UserID		INT = 4
/* Debugging */

SET NOCOUNT ON

DECLARE @DatabaseID INT
DECLARE @LowSaneProductTemperature INT
DECLARE @HighSaneProductTemperature INT
DECLARE @LowSanePouringYieldPercent INT
DECLARE @HighSanePouringYieldPercent INT
DECLARE @LowSaneRetailYieldPercent INT
DECLARE @HighSaneRetailYieldPercent INT
DECLARE @LowSaneOverallYieldPercent INT
DECLARE @HighSaneOverallYieldPercent INT
DECLARE @DatabaseName VARCHAR(100)
DECLARE @DatabaseServer VARCHAR(100)

SELECT @DatabaseID = CAST(PropertyValue AS INT)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

SELECT @LowSaneProductTemperature = CAST(PropertyValue AS INT)
FROM Configuration
WHERE PropertyName = 'Low Sane Product Temperature'

SELECT @HighSaneProductTemperature = CAST(PropertyValue AS INT)
FROM Configuration
WHERE PropertyName = 'High Sane Product Temperature'

SELECT @LowSanePouringYieldPercent = CAST(PropertyValue AS INT)
FROM Configuration
WHERE PropertyName = 'Low Sane Pouring Yield Percent'

SELECT @HighSanePouringYieldPercent = CAST(PropertyValue AS INT)
FROM Configuration
WHERE PropertyName = 'High Sane Pouring Yield Percent'

SELECT @LowSaneRetailYieldPercent = CAST(PropertyValue AS INT)
FROM Configuration
WHERE PropertyName = 'Low Sane Retail Yield Percent'

SELECT @HighSaneRetailYieldPercent = CAST(PropertyValue AS INT)
FROM Configuration
WHERE PropertyName = 'High Sane Retail Yield Percent'

SELECT @LowSaneOverallYieldPercent = CAST(PropertyValue AS INT)
FROM Configuration
WHERE PropertyName = 'Low Sane Overall Yield Percent'

SELECT @HighSaneOverallYieldPercent = CAST(PropertyValue AS INT)
FROM Configuration
WHERE PropertyName = 'High Sane Overall Yield Percent'

SELECT	@DatabaseServer = [Server],
		@DatabaseName = [Name]
FROM [EDISSQL1\SQL1].ServiceLogger.dbo.EDISDatabases
WHERE ID = @DatabaseID

SELECT	@DatabaseID AS DatabaseID,
		@DatabaseName AS DatabaseName,
		@DatabaseServer AS DatabaseServer,
		COALESCE(CustomerSiteGroups.PrimaryEDISID, Sites.EDISID) AS EDISID,
		COALESCE(SiteExceptionConfiguration.ProductTempAlarmsEnabled, Owners.ProductTempAlarmsEnabled) AS ProductTempAlarmsEnabled,
		COALESCE(SiteExceptionConfiguration.ProductTempHighPercentThreshold, Owners.ProductTempHighPercentThreshold) AS ProductTempHighPercentThreshold,
		COALESCE(SiteExceptionConfiguration.CleaningAlarmsEnabled, Owners.CleaningAlarmsEnabled) AS CleaningAlarmsEnabled,
		COALESCE(SiteExceptionConfiguration.OverallYieldAlarmsEnabled, Owners.OverallYieldAlarmsEnabled) AS OverallYieldAlarmsEnabled,
		COALESCE(SiteExceptionConfiguration.OverallYieldLowPercentThreshold, Owners.OverallYieldLowPercentThreshold) AS OverallYieldLowPercentThreshold,
		COALESCE(SiteExceptionConfiguration.PouringYieldAlarmsEnabled, Owners.PouringYieldAlarmsEnabled) AS PouringYieldAlarmsEnabled,
		COALESCE(SiteExceptionConfiguration.PouringYieldLowPercentThreshold, Owners.PouringYieldLowPercentThreshold) AS PouringYieldLowPercentThreshold,
		COALESCE(SiteExceptionConfiguration.RetailYieldAlarmsEnabled, Owners.RetailYieldAlarmsEnabled) AS RetailYieldAlarmsEnabled,
		COALESCE(SiteExceptionConfiguration.RetailYieldLowPercentThreshold, Owners.RetailYieldLowPercentThreshold) AS RetailYieldLowPercentThreshold,
		COALESCE(SiteExceptionConfiguration.ThroughputAlarmsEnabled, Owners.ThroughputAlarmsEnabled) AS ThroughputAlarmsEnabled,
		COALESCE(SiteExceptionConfiguration.ThroughputMinThreshold, Owners.ThroughputMinThreshold) AS ThroughputMinThreshold,
		COALESCE(SiteExceptionConfiguration.OutOfHoursDispenseAlarmsEnabled, Owners.OutOfHoursDispenseAlarmsEnabled) AS OutOfHoursDispenseAlarmsEnabled,
		COALESCE(SiteExceptionConfiguration.OutOfHoursDispenseMinThreshold, Owners.OutOfHoursDispenseMinThreshold) AS OutOfHoursDispenseMinThreshold,
		COALESCE(SiteExceptionConfiguration.NoDataAlarmsEnabled, Owners.NoDataAlarmsEnabled) AS NoDataAlarmsEnabled,
		COALESCE(SiteExceptionConfiguration.CleaningLowVolumeThreshold, Owners.CleaningLowVolumeThreshold) AS CleaningLowVolumeThreshold,
		COALESCE(SiteExceptionConfiguration.OverallYieldHighVolumeThreshold, Owners.OverallYieldHighVolumeThreshold) AS OverallYieldHighVolumeThreshold,
		COALESCE(SiteExceptionConfiguration.RetailYieldHighVolumeThreshold, Owners.RetailYieldHighVolumeThreshold) AS RetailYieldHighVolumeThreshold,
		Owners.UseExceptionReporting,
		Owners.AllowSiteExceptionConfigurationOverride,
		Owners.AutoSendExceptions,
		Owners.ExceptionEmailHeaderHTML,
		Owners.ExceptionEmailFooterHTML,
		Owners.ExceptionEmailCleaningHTML,
		Owners.ExceptionEmailProductTempHTML,
		Owners.ExceptionEmailOverallYieldHTML,
		Owners.ExceptionEmailCellarTempHTML,
		Owners.ExceptionEmailCoolerTempHTML,
		Owners.ExceptionEmailOutOfHoursDispenseHTML,
		Owners.ExceptionEmailPouringYieldHTML,
		Owners.ExceptionEmailRetailYieldHTML,
		Owners.ExceptionEmailThroughputHTML,
		Owners.ExceptionEmailNoDataHTML,
		Owners.ExceptionEmailSubject,
		Owners.CellarAlarmEmailSubject,
		Owners.CoolerAlarmEmailSubject,
		Owners.NoDataAlarmEmailSubject,
		Owners.TargetPouringYieldPercent,
		Owners.TargetTillYieldPercent,
		@LowSaneProductTemperature AS LowSaneProductTemperature,
		@HighSaneProductTemperature AS HighSaneProductTemperature,
		@LowSanePouringYieldPercent AS LowSanePouringYieldPercent,
		@HighSanePouringYieldPercent AS HighSanePouringYieldPercent,
		@LowSaneRetailYieldPercent AS LowSaneRetailYieldPercent,
		@HighSaneRetailYieldPercent AS HighSaneRetailYieldPercent,
		@LowSaneOverallYieldPercent AS LowSaneOverallYieldPercent,
		@HighSaneOverallYieldPercent AS HighSaneOverallYieldPercent
 FROM Sites
 JOIN Owners ON Owners.ID = Sites.OwnerID
 JOIN UserSites ON UserSites.EDISID = Sites.EDISID
 LEFT JOIN 
 (
	SELECT SiteGroupSites.EDISID,
		   PrimaryGroupSites.EDISID AS PrimaryEDISID
	FROM SiteGroupSites
	JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID AND TypeID = 1
	JOIN (
		SELECT EDISID, SiteGroupID
		FROM SiteGroupSites
		WHERE IsPrimary = 1
	) AS PrimaryGroupSites ON PrimaryGroupSites.SiteGroupID = SiteGroups.ID
 ) AS CustomerSiteGroups ON CustomerSiteGroups.EDISID = Sites.EDISID
 LEFT JOIN SiteExceptionConfiguration ON SiteExceptionConfiguration.EDISID = COALESCE(CustomerSiteGroups.PrimaryEDISID, Sites.EDISID)
 WHERE 
    UserSites.UserID = @UserID
AND Sites.[Hidden] = 0


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetUserSitesExceptionConfiguration] TO PUBLIC
    AS [dbo];

