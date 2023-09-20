CREATE PROCEDURE [dbo].[UpdateCallChargeReasonID]
(
	@CallID				INT,
	@ChargeReasonID		INT
)

AS

UPDATE dbo.Calls
SET ChargeReasonID = @ChargeReasonID
WHERE [ID] = @CallID

EXEC dbo.RefreshHandheldCall @CallID, 1, 1, 1

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallChargeReasonID] TO PUBLIC
    AS [dbo];

