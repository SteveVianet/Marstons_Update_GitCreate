CREATE PROCEDURE AddSiteMaintenance
(
	@EDISID			INT,
	@AccountLive	DATE,
	@PanelLive		DATE,
	@LatestInstallation		DATE,
	@ContractStart			DATE,
	@LastMaintenance		DATE,
	@MaintenanceDue			DATE,
	@LatestPAT				DATE,
	@LatestCalibration		DATE,
	@EngineerID				INT,
	@KeyItemsCalibrated		INT,
	@PowerSupplyType		INT,
	@MinorWorksStatus		INT,
	@NewID					INT OUTPUT
)
AS

SET NOCOUNT ON

INSERT INTO SiteMaintenance
 (EDISID, AccountLive, PanelLive, LatestInstallation, ContractStart, LatestMaintenance, MaintenanceDue, LatestPAT, LatestCalibration,
  EngineerID, KeyItemsCalibrated, PowerSupplyType, MinorWorksStatus)
VALUES
 (@EDISID, @AccountLive, @PanelLive, @LatestInstallation, @ContractStart, @LastMaintenance, @MaintenanceDue, @LatestPAT, @LatestCalibration,
  @EngineerID, @KeyItemsCalibrated, @PowerSupplyType, @MinorWorksStatus)

SET @NewID = @@IDENTITY

--Mark old entries as historic
UPDATE SiteMaintenance SET Historic = 1 WHERE EDISID = @EDISID AND Historic = 0 AND ID <> @NewID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSiteMaintenance] TO PUBLIC
    AS [dbo];

