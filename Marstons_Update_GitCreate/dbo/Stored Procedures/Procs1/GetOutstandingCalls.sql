CREATE PROCEDURE [dbo].[GetOutstandingCalls]
(
	@CallTypeID		INT = NULL
)
AS

SELECT	SUM(CASE WHEN CallStatusHistory.StatusID IN (1, 2, 3, 6) THEN 1 ELSE 0 END) AS CallsOutstanding,
		SUM(CASE WHEN CallStatusHistory.StatusID IN (1, 2, 3) THEN 1 ELSE 0 END) AS CallsOutstandingAuthorised,
		SUM(CASE WHEN CallStatusHistory.StatusID = 1 AND dbo.fnGetWeekdayCount(COALESCE(Calls.POConfirmed, Calls.RaisedOn), GETDATE()) > Calls.OverrideSLA THEN 1 ELSE 0 END) AS CallsOpenOutsideSLA,
		SUM(CASE WHEN CallStatusHistory.StatusID = 2 THEN 1 ELSE 0 END) AS CallsOnHold,
		SUM(CASE WHEN CallStatusHistory.StatusID = 2 AND PlanningIssueID = 2 THEN 1 ELSE 0 END) AS IncorrectSiteDetails,
		SUM(CASE WHEN CallStatusHistory.StatusID = 2 AND PlanningIssueID = 3 THEN 1 ELSE 0 END) AS UnableToContactLessee,
		SUM(CASE WHEN CallStatusHistory.StatusID = 2 AND PlanningIssueID = 4 THEN 1 ELSE 0 END) AS AppointmentNotSuitable,
		SUM(CASE WHEN CallStatusHistory.StatusID = 2 AND PlanningIssueID = 5 THEN 1 ELSE 0 END) AS TenantRefusedAccess,
		SUM(CASE WHEN CallStatusHistory.StatusID = 2 AND PlanningIssueID = 6 THEN 1 ELSE 0 END) AS UndergoingRefurb,
		SUM(CASE WHEN CallStatusHistory.StatusID = 2 AND PlanningIssueID = 7 THEN 1 ELSE 0 END) AS BRMRequest,
		SUM(CASE WHEN CallStatusHistory.StatusID = 2 AND PlanningIssueID = 8 THEN 1 ELSE 0 END) AS ElectricalWorkRequired,
		SUM(CASE WHEN CallStatusHistory.StatusID = 2 AND PlanningIssueID = 9 THEN 1 ELSE 0 END) AS BTIssue,
		SUM(CASE WHEN CallStatusHistory.StatusID = 2 AND PlanningIssueID = 10 THEN 1 ELSE 0 END) AS MultipleFailureReasons
FROM CallStatusHistory
JOIN
(
SELECT CallID, MAX(ChangedOn) AS LatestChangeDate
FROM CallStatusHistory
GROUP BY CallID
) AS LatestCallChanges ON LatestCallChanges.CallID = CallStatusHistory.CallID
AND LatestCallChanges.LatestChangeDate = CallStatusHistory.ChangedOn
JOIN Calls ON Calls.[ID] = CallStatusHistory.CallID
WHERE (Calls.CallTypeID = @CallTypeID OR @CallTypeID IS NULL)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetOutstandingCalls] TO PUBLIC
    AS [dbo];

