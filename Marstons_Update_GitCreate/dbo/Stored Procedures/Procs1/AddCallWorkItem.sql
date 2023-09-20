---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE AddCallWorkItem
(
	@CallID		INT,
	@WorkItemID	INT
)

AS

INSERT INTO CallWorkItems
(CallID, WorkItemID)
VALUES
(@CallID, @WorkItemID)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddCallWorkItem] TO PUBLIC
    AS [dbo];

