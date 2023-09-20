
CREATE PROCEDURE dbo.GetEquipmentItemAverageValueByShift
(
 	@EquipmentItemID	INT,
 	@From			DATETIME,
 	@To			DATETIME
)

AS

SET NOCOUNT ON
SET DATEFIRST 1

DECLARE @EDISID INT

SELECT @EDISID = EDISID
FROM EquipmentItems
WHERE ID = @EquipmentItemID

SELECT	DATEPART(hh,EquipmentReadings.LogDate)+1 AS Shift,
		AVG(EquipmentReadings.Value) AS AverageValue,
		AVG(EquipmentReadings.Value) AS AverageTemperature,
		SUM(EquipmentReadings.Value) AS TotalValue,
		MAX(EquipmentReadings.Value) AS MAXValue,
		MIN(EquipmentReadings.Value) AS MINValue,
		MAX(EquipmentReadings.Value) - MIN(EquipmentReadings.Value) AS RateChange,
		COUNT(*) AS NumberOfReadings
FROM EquipmentReadings
JOIN Sites ON Sites.EDISID = EquipmentReadings.EDISID
JOIN EquipmentItems ON EquipmentItems.EDISID = EquipmentReadings.EDISID
		AND EquipmentItems.InputID = EquipmentReadings.InputID
WHERE EquipmentItems.ID = @EquipmentItemID
AND EquipmentReadings.EDISID = @EDISID
AND LogDate BETWEEN @From AND DATEADD(second, -1, DATEADD(day, 1, @To))
AND LogDate >= Sites.SiteOnline
GROUP BY DATEPART(hh,EquipmentReadings.LogDate)+1
ORDER BY DATEPART(hh,EquipmentReadings.LogDate)+1

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetEquipmentItemAverageValueByShift] TO PUBLIC
    AS [dbo];

