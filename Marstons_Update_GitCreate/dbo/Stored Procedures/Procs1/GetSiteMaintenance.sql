
CREATE PROCEDURE GetSiteMaintenance
(
	@OnlySitesWithMaintenance	BIT = 0,
	@IncludeHistorical			BIT = 0,
	@EDISID						INT = NULL
)
AS

SET NOCOUNT ON

CREATE TABLE #Suggested (EDISID INT NOT NULL, PowerSupplyType INT, AccountLive DATE, PanelLive DATE, ContractStart DATE,
						 LatestInstallation DATE, LatestMaintenance DATE, LatestPAT DATE, LatestCalibration DATE, 
						 MaintenanceDue DATE, MinorWorksStatus INT, KeyItemsCalibrated INT)

SELECT 
	Sites.EDISID, 
	SiteMaintenance.ID AS MaintenanceID,
	SiteMaintenance.PowerSupplyType,
	SiteMaintenance.AccountLive,
	SiteMaintenance.PanelLive,
	SiteMaintenance.ContractStart,
	SiteMaintenance.LatestInstallation,
	SiteMaintenance.LatestMaintenance,
	SiteMaintenance.LatestPAT,
	SiteMaintenance.LatestCalibration,
	SiteMaintenance.MaintenanceDue,
	SiteMaintenance.MinorWorksStatus,
	SiteMaintenance.KeyItemsCalibrated,
	SiteMaintenance.EngineerID,
	SiteMaintenance.DateUpdated,
	SiteMaintenance.UpdatedBy,
	SiteMaintenance.Historic,
	Suggested.PowerSupplyType AS SuggestedPowerSupplyType,
	Suggested.AccountLive AS SuggestedAccountLive,
	Suggested.PanelLive AS SuggestedPanelLive,
	Suggested.ContractStart AS SuggestedContractStart,
	Suggested.LatestInstallation AS SuggestedLatestInstallation,
	Suggested.LatestMaintenance AS SuggestedLatestMaintenance,
	Suggested.LatestPAT AS SuggestedLatestPAT,
	Suggested.LatestCalibration AS SuggestedLatestCalibration,
	Suggested.MaintenanceDue AS SuggestedMaintenanceDue,
	Suggested.MinorWorksStatus AS SuggestedMinorWorksStatus,
	Suggested.KeyItemsCalibrated AS SuggestedKeyItemsCalibrated
FROM Sites
LEFT JOIN SiteMaintenance ON SiteMaintenance.EDISID = Sites.EDISID
LEFT JOIN #Suggested AS Suggested ON Suggested.EDISID = Sites.EDISID
WHERE 
	((@EDISID IS NULL) OR (@EDISID IS NOT NULL AND Sites.EDISID = @EDISID))
	AND
	((@OnlySitesWithMaintenance = 0) OR (@OnlySitesWithMaintenance = 1 AND SiteMaintenance.ID IS NOT NULL))
	AND
	((@IncludeHistorical = 1) OR (@IncludeHistorical = 0 AND (SiteMaintenance.Historic = 0)))

DROP TABLE #Suggested
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteMaintenance] TO PUBLIC
    AS [dbo];

