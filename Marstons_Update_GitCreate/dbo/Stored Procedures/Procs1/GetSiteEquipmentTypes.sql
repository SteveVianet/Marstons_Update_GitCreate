CREATE PROCEDURE [dbo].[GetSiteEquipmentTypes]
(
	@EDISID	INT
)

AS

SET NOCOUNT ON

CREATE TABLE #EquipmentTypes ([ID] INT NOT NULL, 
							  [Description] VARCHAR(255), 
							  [EquipmentSubTypeID] INT, 
							  [DefaultSpecification] FLOAT,
							  [DefaultTolerance] FLOAT,
							  [DefaultAlarmThreshold] FLOAT,
							  [DefaultLowSpecification] FLOAT,
							  [DefaultHighSpecification] FLOAT,
							  [DefaultLowAlarmThreshold] FLOAT,
							  [DefaultHighAlarmThreshold] FLOAT,
							  [CanRaiseAlarm] BIT
							  )

INSERT INTO #EquipmentTypes ([ID])
SELECT DISTINCT EquipmentTypeID
FROM dbo.EquipmentReadings AS EquipmentReadings
WHERE EDISID = @EDISID

UPDATE #EquipmentTypes
SET 	[Description] = EquipmentTypes.[Description],
		[EquipmentSubTypeID] = EquipmentTypes.[EquipmentSubTypeID],
		[DefaultSpecification] = EquipmentTypes.[DefaultSpecification],
		[DefaultTolerance] = EquipmentTypes.[DefaultTolerance],
		[DefaultAlarmThreshold] = EquipmentTypes.[DefaultAlarmThreshold],
		[DefaultLowSpecification] = EquipmentTypes.[DefaultLowSpecification],
		[DefaultHighSpecification] = EquipmentTypes.[DefaultHighSpecification],
		[DefaultLowAlarmThreshold] = EquipmentTypes.[DefaultLowAlarmThreshold],
		[DefaultHighAlarmThreshold] = EquipmentTypes.[DefaultHighAlarmThreshold],
		[CanRaiseAlarm] = EquipmentTypes.[CanRaiseAlarm]
FROM dbo.EquipmentTypes AS EquipmentTypes
JOIN #EquipmentTypes ON #EquipmentTypes.ID =  EquipmentTypes.ID

SELECT	[ID], [Description], [EquipmentSubTypeID], [DefaultSpecification], [DefaultTolerance], 
		[DefaultAlarmThreshold], [DefaultLowSpecification], [DefaultHighSpecification], 
		[DefaultLowAlarmThreshold], [DefaultHighAlarmThreshold], [CanRaiseAlarm]
FROM #EquipmentTypes
ORDER BY [ID]

DROP TABLE #EquipmentTypes

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteEquipmentTypes] TO PUBLIC
    AS [dbo];

