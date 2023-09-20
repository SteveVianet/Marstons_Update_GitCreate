CREATE PROCEDURE [dbo].[AddEquipmentType]
(
	@Description VARCHAR(255), 
	@CanRaiseAlarm BIT,
	@ID INT OUTPUT,
	@EquipmentSubTypeID INT = NULL, 
	@DefaultSpecification FLOAT = NULL,
	@DefaultTolerance FLOAT = NULL,
	@DefaultAlarmThreshold FLOAT = NULL,
	@DefaultLowSpecification FLOAT = NULL,
	@DefaultHighSpecification FLOAT = NULL,
	@DefaultLowAlarmThreshold FLOAT = NULL,
	@DefaultHighAlarmThreshold FLOAT = NULL
)

AS

INSERT INTO dbo.EquipmentTypes 
	([Description], [EquipmentSubTypeID], [DefaultSpecification], [DefaultTolerance], [DefaultAlarmThreshold], [DefaultLowSpecification], [DefaultHighSpecification], [DefaultLowAlarmThreshold], [DefaultHighAlarmThreshold], [CanRaiseAlarm])
VALUES
	(@Description, @EquipmentSubTypeID, @DefaultSpecification, @DefaultTolerance, @DefaultAlarmThreshold, @DefaultLowSpecification, @DefaultHighSpecification, @DefaultLowAlarmThreshold, @DefaultHighAlarmThreshold, @CanRaiseAlarm)
 
SET @ID = @@IDENTITY

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddEquipmentType] TO PUBLIC
    AS [dbo];

