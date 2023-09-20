CREATE PROCEDURE [dbo].[UpdateCallFlagToFinance]
(
	@CallID			INT,
	@FlagToFinance	BIT
)

AS

UPDATE dbo.Calls
SET FlagToFinance = @FlagToFinance
WHERE [ID] = @CallID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallFlagToFinance] TO PUBLIC
    AS [dbo];

