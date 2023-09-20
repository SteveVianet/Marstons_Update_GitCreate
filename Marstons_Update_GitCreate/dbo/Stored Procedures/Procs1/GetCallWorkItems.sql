---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetCallWorkItems
(
	@CallID	INT
)

AS

SELECT	WorkItemID
FROM CallWorkItems
WHERE CallID = @CallID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallWorkItems] TO PUBLIC
    AS [dbo];

