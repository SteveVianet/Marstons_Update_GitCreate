CREATE PROCEDURE GetCallFaults
(
	@CallID		INT
)

AS

SELECT	CallFaults.[ID],
		CallFaults.FaultTypeID,
		AdditionalInfo,
		SLA
FROM dbo.CallFaults
WHERE CallID = @CallID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallFaults] TO PUBLIC
    AS [dbo];

