CREATE PROCEDURE [dbo].[GetAverageCellarTemperature]
(
            @EDISID                      INT,
            @From             DATETIME,
            @To                 DATETIME
)
 
AS
 
SET NOCOUNT ON
 
SELECT AVG(EquipmentReadings.Value) As AvgCellarTemperature
FROM EquipmentReadings
JOIN EquipmentItems ON EquipmentItems.InputID = EquipmentReadings.InputID AND EquipmentItems.EDISID = EquipmentReadings.EDISID
WHERE EquipmentItems.EquipmentTypeID = 12
AND EquipmentReadings.EDISID = @EDISID
AND LogDate BETWEEN @From AND DATEADD(second, -1, DATEADD(day, 1, @To))
AND EquipmentItems.InUse = 1

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAverageCellarTemperature] TO PUBLIC
    AS [dbo];

