CREATE PROCEDURE [dbo].[AddSiteEquipmentItem] 
	@EDISID INT,
	@InputID INT,
	@LocationID INT,
	@EquipmentTypeID INT,
	@Description VARCHAR(1024),
	@LowSpec FLOAT,
	@HighSpec FLOAT,
	@LowAlarm FLOAT,
	@HighAlarm FLOAT,
	@StartTime TIME(0),
	@EndTime TIME(0), 
	@AlarmStatus BIT,
	@InUse BIT
AS
BEGIN
	SET NOCOUNT ON;

	INSERT INTO [dbo].[EquipmentItems] ([EDISID], [InputID], [LocationID], [EquipmentTypeID], [Description], ValueSpecification, ValueTolerance, [InUse], AlarmThreshold, [ValueLowSpecification], [ValueHighSpecification], [LowAlarmThreshold], [HighAlarmThreshold], [AlarmStartTime], [AlarmEndTime], [AlarmStatus])
	VALUES (@EDISID, @InputID, @LocationID, @EquipmentTypeID, @Description, 1, 1, @InUse, 1, @LowSpec, @HighSpec, @LowAlarm, @HighAlarm, @StartTime, @EndTime, @AlarmStatus)
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSiteEquipmentItem] TO PUBLIC
    AS [dbo];

