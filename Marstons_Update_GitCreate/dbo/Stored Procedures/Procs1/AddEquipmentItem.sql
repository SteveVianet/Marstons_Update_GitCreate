CREATE PROCEDURE [dbo].[AddEquipmentItem]
(
	@EDISID			    INT,
	@SlaveID			INT = NULL,
	@IsDigital			BIT = NULL,
	@InputID			INT,
	@LocationID			INT = NULL,
	@EquipmentTypeID	INT,
	@Description		VARCHAR(1024),
	@ValueSpecification	FLOAT = NULL,
	@ValueTolerance		FLOAT = NULL,
	@NewID			    INT OUTPUT,
	@AlarmThreshold		FLOAT = NULL
)
AS

SET NOCOUNT ON

DECLARE @GlobalEDISID	INTEGER
DECLARE @GlobalLocationID	INTEGER
DECLARE @ExistingID INT
DECLARE @EquipmentTypeValueLowSpecification FLOAT
DECLARE @EquipmentTypeValueHighSpecification FLOAT
DECLARE @EquipmentTypeLowAlarmThreshold FLOAT
DECLARE @EquipmentTypeHighAlarmThreshold FLOAT

IF @EquipmentTypeID = 1
BEGIN
	SET @EquipmentTypeID = 12
END

IF @LocationID IS NULL
BEGIN
    SELECT @LocationID = MIN(ID) FROM Locations
END

SET @ExistingID = 0

SELECT @ExistingID = [ID]
FROM dbo.EquipmentItems
WHERE EDISID = @EDISID AND InputID = @InputID

SELECT @EquipmentTypeValueLowSpecification = DefaultLowSpecification,
	 @EquipmentTypeValueHighSpecification = DefaultHighSpecification,
	 @EquipmentTypeLowAlarmThreshold = DefaultLowAlarmThreshold,
	 @EquipmentTypeHighAlarmThreshold = DefaultHighAlarmThreshold
FROM EquipmentTypes
WHERE [ID] = @EquipmentTypeID

IF @ExistingID = 0
BEGIN
	INSERT INTO dbo.EquipmentItems
	(EDISID, InputID, LocationID, EquipmentTypeID, [Description], ValueSpecification, ValueTolerance, InUse, AlarmThreshold, ValueLowSpecification, ValueHighSpecification, LowAlarmThreshold, HighAlarmThreshold, AlarmStartTime, AlarmEndTime)
	VALUES
	(@EDISID, @InputID, @LocationID, @EquipmentTypeID, @Description, COALESCE(@ValueSpecification,1), COALESCE(@ValueTolerance,1), 1, COALESCE(@AlarmThreshold,1), @EquipmentTypeValueLowSpecification, @EquipmentTypeValueHighSpecification, @EquipmentTypeLowAlarmThreshold, @EquipmentTypeHighAlarmThreshold, '00:00:00', '23:59:59')
	SET @NewID = @@IDENTITY
END
ELSE
BEGIN
	SET @NewID = @ExistingID

	UPDATE dbo.EquipmentItems
	SET LocationID = @LocationID, 
	        EquipmentTypeID = @EquipmentTypeID, 
	        [Description] = @Description, 
	        ValueLowSpecification = @EquipmentTypeValueLowSpecification,
	        ValueHighSpecification = @EquipmentTypeValueHighSpecification,
	        LowAlarmThreshold = @EquipmentTypeLowAlarmThreshold,
	        HighAlarmThreshold = @EquipmentTypeHighAlarmThreshold
	WHERE [ID] = @ExistingID
END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddEquipmentItem] TO PUBLIC
    AS [dbo];

