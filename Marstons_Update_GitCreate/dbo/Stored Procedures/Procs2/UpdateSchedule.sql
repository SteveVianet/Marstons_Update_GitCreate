
CREATE PROCEDURE [dbo].[UpdateSchedule]
(
	@ScheduleID		INT,
	@Description	VARCHAR(255),
	@Public		BIT
)

AS

DECLARE @Owner	VARCHAR(255)

IF @Public = 1
	SET @Owner = ''
ELSE
	SET @Owner = SYSTEM_USER

UPDATE dbo.Schedules
SET [Description] = @Description,
[Public] = @Public,
[Owner] = SYSTEM_USER
WHERE [ID] = @ScheduleID



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSchedule] TO PUBLIC
    AS [dbo];

