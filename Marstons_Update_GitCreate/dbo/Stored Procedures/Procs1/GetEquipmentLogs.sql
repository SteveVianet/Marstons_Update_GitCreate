
CREATE PROCEDURE dbo.GetEquipmentLogs
(
	@EDISID	INT,
	@Date		SMALLDATETIME,
	@SlaveID	INT = NULL,
	@IsDigital	BIT = NULL,
	@InputID	INT = NULL
)

AS
 
SELECT EquipmentReadings.LogDate AS [Time],
	EquipmentReadings.Value AS Value1,
	0 AS Value2,
	0 AS Value3,
	0 AS SlaveID,
	0 AS IsDigital,
	EquipmentReadings.InputID,
	EquipmentReadings.LocationID,
	EquipmentReadings.EquipmentTypeID,
	EquipmentItems.ValueSpecification,
	EquipmentItems.ValueTolerance,
	EquipmentItems.[Description] AS EquipmentDescription,
	Locations.[Description] AS EquipmentLocationDescription,
	EquipmentTypes.[Description] AS EquipmentTypeDescription,
	CASE WHEN EquipmentReadings.Value > (EquipmentItems.ValueSpecification + EquipmentItems.ValueTolerance) OR EquipmentReadings.Value 
< (EquipmentItems.ValueSpecification - EquipmentItems.ValueTolerance) THEN 0 ELSE 1 END AS InSpec
FROM dbo.EquipmentReadings
JOIN EquipmentItems ON (EquipmentItems.EDISID = EquipmentReadings.EDISID AND EquipmentItems.InputID = EquipmentReadings.InputID)
JOIN Locations ON Locations.[ID] = EquipmentReadings.LocationID
JOIN EquipmentTypes ON EquipmentTypes.[ID] = EquipmentReadings.EquipmentTypeID
WHERE EquipmentReadings.EDISID = @EDISID
AND LogDate BETWEEN @Date AND DATEADD(second, -1, DATEADD(day, 1, @Date))
AND (@InputID IS NULL
OR 	(EquipmentReadings.InputID = @InputID))
ORDER BY EquipmentReadings.InputID, EquipmentReadings.LogDate

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetEquipmentLogs] TO PUBLIC
    AS [dbo];

