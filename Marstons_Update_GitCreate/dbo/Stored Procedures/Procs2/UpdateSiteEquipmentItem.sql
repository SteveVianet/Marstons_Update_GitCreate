CREATE PROCEDURE dbo.UpdateSiteEquipmentItem 
	
	@ItemID INT,
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
	@AlarmStatus BIT
	

AS
BEGIN

	SET NOCOUNT ON;

    -- Insert statements for procedure here
	UPDATE dbo.EquipmentItems
	SET InputID = @InputID,
		LocationID = @LocationID,
		EquipmentTypeID = @EquipmentTypeID,
		[Description] = @Description,
		ValueLowSpecification = @LowSpec,
		ValueHighSpecification = @HighSpec,
		LowAlarmThreshold = @LowAlarm,
		HighAlarmThreshold = @HighAlarm,
		AlarmStartTime = @StartTime,
		AlarmEndTime = @EndTime,
		AlarmStatus = @AlarmStatus
	WHERE ID = @ItemID
		
END