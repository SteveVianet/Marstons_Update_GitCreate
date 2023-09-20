CREATE PROCEDURE [dbo].[GetUserSitesAlarmConfiguration]
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

SELECT	@DatabaseServer = [Server],
		@DatabaseName = [Name]
FROM [EDISSQL1\SQL1].ServiceLogger.dbo.EDISDatabases
WHERE ID = @DatabaseID

SELECT	@DatabaseID AS DatabaseID,
		@DatabaseName AS DatabaseName,
		@DatabaseServer AS DatabaseServer,
		COALESCE(CustomerSiteGroups.PrimaryEDISID, Sites.EDISID) AS EDISID,
		--COALESCE(SiteExceptionConfiguration.ProductTempAlarmsEnabled, Owners.ProductTempAlarmsEnabled) AS ProductTempAlarmsEnabled,
		--COALESCE(SiteExceptionConfiguration.CleaningAlarmsEnabled, Owners.CleaningAlarmsEnabled) AS CleaningAlarmsEnabled,
		COALESCE(SiteExceptionConfiguration.OverallYieldAlarmsEnabled, Owners.OverallYieldAlarmsEnabled) AS OverallYieldAlarmsEnabled
		--COALESCE(SiteExceptionConfiguration.PouringYieldAlarmsEnabled, Owners.PouringYieldAlarmsEnabled) AS PouringYieldAlarmsEnabled,
		--COALESCE(SiteExceptionConfiguration.RetailYieldAlarmsEnabled, Owners.RetailYieldAlarmsEnabled) AS RetailYieldAlarmsEnabled,
		--COALESCE(SiteExceptionConfiguration.ThroughputAlarmsEnabled, Owners.ThroughputAlarmsEnabled) AS ThroughputAlarmsEnabled,
		--COALESCE(SiteExceptionConfiguration.OutOfHoursDispenseAlarmsEnabled, Owners.OutOfHoursDispenseAlarmsEnabled) AS OutOfHoursDispenseAlarmsEnabled,
		--COALESCE(SiteExceptionConfiguration.NoDataAlarmsEnabled, Owners.NoDataAlarmsEnabled) AS NoDataAlarmsEnabled,
		--Owners.UseExceptionReporting,
		--Owners.AllowSiteExceptionConfigurationOverride
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
    ON OBJECT::[dbo].[GetUserSitesAlarmConfiguration] TO PUBLIC
    AS [dbo];

