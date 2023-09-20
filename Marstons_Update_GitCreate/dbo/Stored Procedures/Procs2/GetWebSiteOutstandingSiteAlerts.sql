CREATE PROCEDURE [dbo].[GetWebSiteOutstandingSiteAlerts] 
(
	@EDISID	INTEGER
)
AS

--DECLARE @DatabaseID	INTEGER

--SELECT @DatabaseID = CAST(PropertyValue AS INTEGER) 
--FROM Configuration
--WHERE PropertyName = 'Service Owner ID'

--EXEC [SQL1\SQL1].ServiceLogger.dbo.GetOutstandingSiteBQMAlerts @DatabaseID, @EDISID

SELECT	EquipmentItems.InputID AS EquipmentInputID, 
		EquipmentItems.LastAlarmingReading AS AlertDate, 
		EquipmentReadings.Value AS EquipmentValue
FROM EquipmentItems
JOIN EquipmentReadings ON EquipmentReadings.EDISID = @EDISID
					  AND EquipmentReadings.InputID = EquipmentItems.InputID
					  AND EquipmentReadings.LogDate = EquipmentItems.LastAlarmingReading
WHERE LastAlarmingReading >= DATEADD(day, -7, GETDATE())

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteOutstandingSiteAlerts] TO PUBLIC
    AS [dbo];

