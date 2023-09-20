---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE DeleteSchedule
(
	@ScheduleName	VARCHAR(255)
)

AS

--Delete all schedule sites
DELETE dbo.ScheduleSites
FROM dbo.ScheduleSites
INNER JOIN dbo.Schedules ON Schedules.[ID] = ScheduleSites.ScheduleID
WHERE Schedules.[Description] = @ScheduleName

--Delete schedule
DELETE FROM Schedules
WHERE Schedules.[Description] = @ScheduleName


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteSchedule] TO PUBLIC
    AS [dbo];

