
CREATE PROCEDURE dbo.GetEquipmentItemAverageValueByDay
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

SELECT	CAST(CONVERT(VARCHAR(10), LogDate, 12) AS DATETIME) AS [Date],
		AVG(EquipmentReadings.Value) AS AverageValue,
		SUM(EquipmentReadings.Value) AS TotalValue,
		MAX(EquipmentReadings.Value) AS MAXValue,
		MIN(EquipmentReadings.Value) AS MINValue,
		MAX(EquipmentReadings.Value) - MIN(EquipmentReadings.Value) as RateChange,
		COUNT(*) AS NumberOfReadings
FROM EquipmentReadings
JOIN Sites ON Sites.EDISID = EquipmentReadings.EDISID
JOIN EquipmentItems ON EquipmentItems.EDISID = EquipmentReadings.EDISID
		AND EquipmentItems.InputID = EquipmentReadings.InputID
WHERE EquipmentItems.ID = @EquipmentItemID
AND EquipmentReadings.EDISID = @EDISID
AND LogDate BETWEEN @FromDate AND DATEADD(second, -1, DATEADD(day, 1, @ToDate))
AND LogDate >= Sites.SiteOnline
GROUP BY CAST(CONVERT(VARCHAR(10), LogDate, 12) AS DATETIME)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetEquipmentItemAverageValueByDay] TO PUBLIC
    AS [dbo];

