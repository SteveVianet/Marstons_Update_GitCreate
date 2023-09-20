CREATE PROCEDURE [dbo].[GetEquipmentExceptions]
(
       @From         DATETIME,
       @To           DATETIME
)
AS

DECLARE @EquipmentAlarmThresholds TABLE ([ID] INT NOT NULL, AlarmThreshold FLOAT NOT NULL, LowAlarmThreshold FLOAT NOT NULL, HighAlarmThreshold FLOAT NOT NULL)

SET NOCOUNT ON

INSERT INTO @EquipmentAlarmThresholds
([ID], AlarmThreshold, LowAlarmThreshold, HighAlarmThreshold)
SELECT EquipmentItems.[ID],
       ISNULL(EquipmentItems.HighAlarmThreshold, EquipmentTypes.DefaultHighAlarmThreshold),
       ISNULL(EquipmentItems.LowAlarmThreshold, EquipmentTypes.DefaultLowAlarmThreshold),
       ISNULL(EquipmentItems.HighAlarmThreshold, EquipmentTypes.DefaultHighAlarmThreshold)
FROM EquipmentItems
JOIN EquipmentTypes ON EquipmentTypes.[ID] = EquipmentItems.EquipmentTypeID
JOIN Sites ON Sites.EDISID = EquipmentItems.EDISID
WHERE Sites.Quality = 1
AND EquipmentTypes.[ID] >= 10

SELECT EquipmentItems.EDISID,
       EquipmentItems.InputID,
      CONVERT(VARCHAR(19), EquipmentReadings.LogDate, 20) AS ExceptionTime,
         Locations.[Description] AS LocationDescription,
      EquipmentTypes.[Description]  + ': ' + EquipmentItems.[Description] AS EquipmentDescription,
         EquipmentReadings.Value AS Value1,
         EquipmentItems.ValueSpecification,
         EquipmentItems.ValueTolerance,
         EquipmentAlarmThresholds.AlarmThreshold,
         EquipmentAlarmThresholds.LowAlarmThreshold,
         EquipmentAlarmThresholds.HighAlarmThreshold,
         EquipmentSubTypes.Description AS SubTypeDescription,
         cast( convert( varchar(8), EquipmentReadings.LogDate, 108) AS time(0)) AS TimeSetting,
         EquipmentItems.AlarmStartTime,
         EquipmentItems.AlarmEndTime
FROM EquipmentReadings
JOIN Sites On Sites.EDISID = EquipmentReadings.EDISID
JOIN Locations ON Locations.[ID] = EquipmentReadings.LocationID
JOIN EquipmentItems ON (EquipmentItems.EDISID = EquipmentReadings.EDISID AND
                       EquipmentItems.InputID = EquipmentReadings.InputID)
JOIN EquipmentTypes ON EquipmentTypes.[ID] = EquipmentItems.EquipmentTypeID
JOIN EquipmentSubTypes ON EquipmentSubTypes.ID = EquipmentTypes.EquipmentSubTypeID
JOIN @EquipmentAlarmThresholds AS EquipmentAlarmThresholds ON EquipmentAlarmThresholds.[ID] = EquipmentItems.[ID]
WHERE EquipmentReadings.LogDate BETWEEN DATEADD(HOUR, -1, @From) AND @To
AND (EquipmentReadings.Value > EquipmentAlarmThresholds.HighAlarmThreshold) --OR EquipmentReadings.Value < EquipmentAlarmThresholds.LowAlarmThreshold)
AND Sites.Quality = 1
AND Sites.Hidden = 0
AND EquipmentItems.AlarmStatus = 1
AND (cast( convert( varchar(8), EquipmentReadings.LogDate, 108) AS time(0)) BETWEEN EquipmentItems.AlarmStartTime AND DATEADD(SECOND, -1, EquipmentItems.AlarmEndTime)) -->= DATEPART(Hour,EquipmentItems.AlarmStartTime) AND (cast( convert( varchar(8), EquipmentReadings.LogDate, 108) AS time(0)) < EquipmentItems.AlarmEndTime)))
AND EquipmentTypes.CanRaiseAlarm = 1
ORDER BY CONVERT(VARCHAR(19), EquipmentReadings.LogDate, 20) DESC

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetEquipmentExceptions] TO PUBLIC
    AS [dbo];

