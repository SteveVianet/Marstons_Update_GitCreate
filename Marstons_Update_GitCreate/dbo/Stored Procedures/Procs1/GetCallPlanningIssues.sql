CREATE PROCEDURE [dbo].[GetCallPlanningIssues]

AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.GetCallPlanningIssues

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallPlanningIssues] TO PUBLIC
    AS [dbo];

