CREATE PROCEDURE [dbo].[GetCallReasons]
(
	@CallID		INT
)

AS

SELECT	CallReasons.[ID],
		CallReasons.ReasonTypeID,
		AdditionalInfo
FROM dbo.CallReasons
WHERE CallID = @CallID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallReasons] TO PUBLIC
    AS [dbo];

