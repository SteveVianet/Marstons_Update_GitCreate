---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE DeleteCallWorkItem
(
	@CallID		INT,
	@WorkItemID	INT
)

AS

DELETE FROM CallWorkItems
WHERE CallID = @CallID
AND WorkItemID = @WorkItemID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteCallWorkItem] TO PUBLIC
    AS [dbo];

