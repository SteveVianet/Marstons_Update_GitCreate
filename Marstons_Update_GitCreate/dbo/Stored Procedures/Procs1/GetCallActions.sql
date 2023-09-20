---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetCallActions
(
	@CallID	INT = NULL
)

AS

SELECT	[ID],
	CallID,
	ActionID,
	ActionUser,
	ActionTime,
	ActionText
FROM CallActions
WHERE (CallID = @CallID) OR (@CallID IS NULL)



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallActions] TO PUBLIC
    AS [dbo];

