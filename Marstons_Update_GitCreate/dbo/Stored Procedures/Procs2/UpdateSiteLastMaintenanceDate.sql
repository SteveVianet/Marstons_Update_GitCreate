CREATE PROCEDURE [dbo].[UpdateSiteLastMaintenanceDate]
(
	@EDISID	INT,
	@LastMaintenanceDate	DATETIME
)
AS

SET NOCOUNT ON

DECLARE @DatabaseID INT
DECLARE @IsDueMaintenance BIT

UPDATE Sites
SET LastMaintenanceDate = @LastMaintenanceDate
WHERE EDISID = @EDISID

SELECT @DatabaseID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

SELECT @IsDueMaintenance = CASE WHEN DATEDIFF(MONTH, @LastMaintenanceDate, GETDATE()) >= Contracts.MaintenancePeriodMax THEN 1 ELSE 0 END
FROM SiteContracts
JOIN Contracts ON Contracts.ID = SiteContracts.ContractID
WHERE EDISID = @EDISID

EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.UpdateSiteMaintenanceDate @DatabaseID, @EDISID, @LastMaintenanceDate, @IsDueMaintenance

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteLastMaintenanceDate] TO PUBLIC
    AS [dbo];

