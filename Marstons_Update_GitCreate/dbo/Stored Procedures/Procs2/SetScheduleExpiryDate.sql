---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE SetScheduleExpiryDate
(
	@ScheduleID	INT,
	@ExpiryDate	SMALLDATETIME
)

AS

UPDATE dbo.Schedules
SET ExpiryDate = @ExpiryDate
WHERE [ID] = @ScheduleID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SetScheduleExpiryDate] TO [TeamLeader]
    AS [dbo];

