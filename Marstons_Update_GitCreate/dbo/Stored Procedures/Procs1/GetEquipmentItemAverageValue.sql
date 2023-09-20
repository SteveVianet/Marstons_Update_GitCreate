

CREATE PROCEDURE dbo.GetEquipmentItemAverageValue
(
	@EquipmentItemID	INT,
	@FromDate		DATETIME,
	@ToDate		DATETIME
)
AS

SET NOCOUNT ON

DECLARE @EDISID INT

SELECT @EDISID = EDISID
FROM EquipmentItems
WHERE ID = @EquipmentItemID

SELECT AVG(EquipmentReadings.Value) AS AverageValue,
	COUNT(*) AS NumberOfReadings
FROM EquipmentReadings
JOIN Sites ON Sites.EDISID = EquipmentReadings.EDISID
JOIN EquipmentItems ON EquipmentItems.EDISID = EquipmentReadings.EDISID
		AND EquipmentItems.InputID = EquipmentReadings.InputID
WHERE EquipmentItems.ID = @EquipmentItemID
AND EquipmentReadings.EDISID = @EDISID
AND LogDate BETWEEN @FromDate AND DATEADD(second, -1, DATEADD(day, 1, @ToDate))
AND LogDate >= Sites.SiteOnline

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetEquipmentItemAverageValue] TO PUBLIC
    AS [dbo];

