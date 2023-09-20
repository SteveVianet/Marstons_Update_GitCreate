CREATE PROCEDURE [dbo].[UpdateCallIsChargeable]
(
	@CallID			INT,
	@IsChargeable	BIT
)

AS

UPDATE dbo.Calls
SET IsChargeable = @IsChargeable
WHERE [ID] = @CallID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallIsChargeable] TO PUBLIC
    AS [dbo];

