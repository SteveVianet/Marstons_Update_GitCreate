
CREATE PROCEDURE [dbo].[GetAllEquipmentLogs]
(
	@EDISID		INT,
	@DateFrom	SMALLDATETIME = NULL,
	@DateTo		SMALLDATETIME = NULL
)

AS
 
SELECT EquipmentReadings.LogDate,
	EquipmentReadings.TradingDate,
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
	EquipmentReadings.Value 
FROM dbo.EquipmentReadings
JOIN EquipmentItems ON (EquipmentItems.EDISID = EquipmentReadings.EDISID AND EquipmentItems.InputID = EquipmentReadings.InputID)
JOIN Locations ON Locations.[ID] = EquipmentReadings.LocationID
JOIN EquipmentTypes ON EquipmentTypes.[ID] = EquipmentReadings.EquipmentTypeID
WHERE EquipmentReadings.EDISID = @EDISID
AND ((LogDate >= @DateFrom) OR (@DateFrom IS NULL))
AND ((LogDate <= @DateTo) OR (@DateTo IS NULL))

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAllEquipmentLogs] TO PUBLIC
    AS [dbo];

