CREATE PROCEDURE [dbo].[GetAuditorEquipmentAlerts]
AS

SET NOCOUNT ON

DECLARE @CustomerID INT

SELECT @CustomerID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

SELECT	@CustomerID AS Customer,
		EquipmentItems.EDISID,
		'Equipment' AS AlertType,
		EquipmentItems.LastAlarmingReading AS AlertDate, 
		EquipmentReadings.Value AS AlertReading,
		SiteQualityComments.[Text] AS LastQualityComment,
		'' AS [Action]
FROM EquipmentItems
JOIN EquipmentReadings ON EquipmentReadings.EDISID = EquipmentItems.EDISID
					  AND EquipmentReadings.InputID = EquipmentItems.InputID
					  AND EquipmentReadings.LogDate = EquipmentItems.LastAlarmingReading
LEFT JOIN 
(
	SELECT SiteComments.EDISID, SiteComments.[Text] 
	FROM
	(
	SELECT EDISID, MAX([ID]) AS LastID
	FROM SiteComments 
	WHERE HeadingType = 1009
	GROUP BY EDISID
	) AS LastSiteQualityComments
	JOIN SiteComments ON SiteComments.[ID] = LastSiteQualityComments.LastID
) AS SiteQualityComments ON SiteQualityComments.EDISID = EquipmentItems.EDISID
WHERE LastAlarmingReading >= DATEADD(day, -7, GETDATE())

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAuditorEquipmentAlerts] TO PUBLIC
    AS [dbo];

