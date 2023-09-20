
CREATE PROCEDURE [dbo].[UpdateServiceIssuesDateTo]
(
	@CallID		INT
)
AS

SET NOCOUNT ON

UPDATE dbo.ServiceIssuesQuality
SET DateTo = GETDATE()
WHERE CallID = @CallID

UPDATE dbo.ServiceIssuesYield
SET DateTo = GETDATE()
WHERE CallID = @CallID

UPDATE dbo.ServiceIssuesEquipment
SET DateTo = GETDATE()
WHERE CallID = @CallID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateServiceIssuesDateTo] TO PUBLIC
    AS [dbo];

