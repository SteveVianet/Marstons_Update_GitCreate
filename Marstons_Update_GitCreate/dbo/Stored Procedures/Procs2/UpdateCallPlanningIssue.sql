CREATE PROCEDURE [dbo].[UpdateCallPlanningIssue]
(
	@CallID				INT,
	@PlanningIssueID	INT
)

AS

UPDATE dbo.Calls
SET PlanningIssueID = @PlanningIssueID
WHERE [ID] = @CallID

EXEC dbo.RefreshHandheldCall @CallID, 1, 1, 1

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallPlanningIssue] TO PUBLIC
    AS [dbo];

