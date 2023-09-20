CREATE PROCEDURE [dbo].[UpdateCallDaysOnHold]
(
	@CallID			INT,
	@DaysOnHold		INT
)

AS

UPDATE dbo.Calls
SET DaysOnHold = @DaysOnHold
WHERE [ID] = @CallID

EXEC dbo.RefreshHandheldCall @CallID, 1, 1, 1

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallDaysOnHold] TO PUBLIC
    AS [dbo];

