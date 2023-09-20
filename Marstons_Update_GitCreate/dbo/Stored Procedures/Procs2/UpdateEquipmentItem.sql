
CREATE PROCEDURE [dbo].[UpdateEquipmentItem]
(
	@ID						INT,
	@SlaveID				INT = NULL,
	@IsDigital				BIT = NULL,
	@InputID				INT = NULL,
	@LocationID				INT = NULL,
	@EquipmentTypeID		INT,
	@Description			VARCHAR(1024) = NULL,
	@ValueSpecification		FLOAT = NULL,
	@ValueTolerance			FLOAT = NULL,
	@AlarmThreshold			FLOAT = NULL,
	@ValueLowSpecification	FLOAT = NULL,
	@ValueHighSpecification	FLOAT = NULL,
	@LowAlarmThreshold		FLOAT = NULL,
	@HighAlarmThreshold		FLOAT = NULL,
	@AlarmStartTime			DATETIME = NULL,
	@AlarmEndTime			DATETIME = NULL,
	@InUse					BIT = NULL,
	@AlarmStatus			BIT = NULL
)
AS

SET NOCOUNT ON

IF @EquipmentTypeID = 1
BEGIN
	SET @EquipmentTypeID = 12
END

UPDATE dbo.EquipmentItems
SET	LocationID = COALESCE(@LocationID, Existing.LocationID),
	EquipmentTypeID = @EquipmentTypeID,
	[Description] = COALESCE(@Description, Existing.Description, 'No name'),
	ValueSpecification = COALESCE(@ValueSpecification, Existing.ValueSpecification),
	ValueTolerance = COALESCE(@ValueTolerance, Existing.ValueTolerance),
	AlarmThreshold = COALESCE(@AlarmThreshold, Existing.AlarmThreshold),
	ValueLowSpecification = COALESCE(@ValueLowSpecification, Existing.ValueLowSpecification, DefaultLowSpecification),
	ValueHighSpecification = COALESCE(@ValueHighSpecification, Existing.ValueHighSpecification, DefaultHighSpecification),
	LowAlarmThreshold = COALESCE(@LowAlarmThreshold, Existing.LowAlarmThreshold, DefaultLowAlarmThreshold),
	HighAlarmThreshold = COALESCE(@HighAlarmThreshold, Existing.HighAlarmThreshold, DefaultHighAlarmThreshold),
	InUse = COALESCE(@InUse, Existing.InUse),
	AlarmStartTime = COALESCE(@AlarmStartTime, Existing.AlarmStartTime),
	AlarmEndTime = COALESCE(@AlarmEndTime, Existing.AlarmEndTime),
	AlarmStatus = COALESCE(@AlarmStatus, Existing.AlarmStatus)
FROM dbo.EquipmentItems
JOIN dbo.EquipmentItems AS Existing ON Existing.ID = @ID
LEFT JOIN dbo.EquipmentTypes ON dbo.EquipmentTypes.ID = @EquipmentTypeID
WHERE dbo.EquipmentItems.[ID] = @ID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateEquipmentItem] TO PUBLIC
    AS [dbo];

