
CREATE PROCEDURE [dbo].[GetMaximumCellarTemperature]
(
            @EDISID                      INT,
            @From             DATETIME,
            @To                 DATETIME
)
 
AS
 
SET NOCOUNT ON
 
DECLARE @Locations TABLE (LocationID INT NOT NULL)
 
INSERT INTO @Locations
SELECT [ID]
FROM Locations
WHERE UPPER(Locations.[Description]) LIKE '%CELLAR%'
 
SELECT MAX(EquipmentReadings.Value) As MaxCellarTemperature
FROM EquipmentReadings
JOIN @Locations AS Locations ON Locations.LocationID = EquipmentReadings.LocationID
WHERE EquipmentReadings.EquipmentTypeID = 1
AND EquipmentReadings.EDISID = @EDISID
AND EquipmentReadings.LogDate BETWEEN @From AND DATEADD(second, -1, DATEADD(day, 1, @To))

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetMaximumCellarTemperature] TO PUBLIC
    AS [dbo];

