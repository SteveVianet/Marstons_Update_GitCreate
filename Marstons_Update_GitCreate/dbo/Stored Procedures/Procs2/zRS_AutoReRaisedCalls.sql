CREATE PROCEDURE [dbo].[zRS_AutoReRaisedCalls]
(
      @From       DATETIME = NULL
)
AS

SELECT     Configuration.PropertyValue AS Company, IncompleteReasons.Description AS Revistreason, dbo.GetCallReference(Calls.ID) AS Callref, 
                      dbo.Calls.RaisedOn, dbo.GetCallReference(Calls.ReRaiseFromCallID) AS ReRaiseFromCallID, CASE WHEN dbo.Calls.PriorityID = 1 THEN 'Standard' ELSE 'High' END AS Priority, 
                      IntialCall.ClosedOn, dbo.Sites.SiteID, dbo.Sites.Name, dbo.Sites.Address1, dbo.Sites.PostCode, IntialCall.IncompleteDate, 
                      dbo.udfConcatCallReasons(Calls.ID) AS Description, PlanningIssue.Description AS Plannerissue, ContractEngineers.Name AS Engineer, 
                      Abortedreason.Description AS AbortReason
FROM         dbo.Calls AS IntialCall RIGHT OUTER JOIN
                      dbo.Calls INNER JOIN
                      dbo.Configuration ON dbo.Configuration.PropertyName = 'Company Name' INNER JOIN
                      dbo.Sites ON dbo.Calls.EDISID = dbo.Sites.EDISID ON IntialCall.ID = dbo.Calls.ReRaiseFromCallID INNER JOIN
                      [EDISSQL1\SQL1].ServiceLogger.dbo.CallIncompleteReasons AS IncompleteReasons ON 
                      IntialCall.IncompleteReasonID = IncompleteReasons.ID INNER JOIN
                      [EDISSQL1\SQL1].ServiceLogger.dbo.CallPlanningIssues AS PlanningIssue ON dbo.Calls.PlanningIssueID = PlanningIssue.ID LEFT OUTER JOIN
                      dbo.CallReasons ON dbo.Calls.ID = CallReasons.CallID LEFT OUTER JOIN
                      [EDISSQL1\SQL1].ServiceLogger.dbo.CallReasonTypes AS GlobalCallReasonTypes ON 
                      dbo.CallReasons.ReasonTypeID = GlobalCallReasonTypes.ID INNER JOIN
                      [EDISSQL1\SQL1].ServiceLogger.dbo.ContractorEngineers AS ContractEngineers ON ContractEngineers.ID = Calls.EngineerID INNER JOIN
                      [EDISSQL1\SQL1].ServiceLogger.dbo.AbortReasons AS Abortedreason ON IntialCall.AbortReasonID = Abortedreason.ID
WHERE     (dbo.Calls.ReRaiseFromCallID IS NOT NULL) AND (IntialCall.IncompleteDate >= @From) OR
                      (dbo.Calls.ReRaiseFromCallID IS NOT NULL) AND (@From IS NULL)
GROUP BY dbo.Calls.ID, Configuration.PropertyValue, IncompleteReasons.Description, dbo.Calls.RaisedOn, dbo.GetCallReference(Calls.ReRaiseFromCallID), 
                      CASE WHEN dbo.Calls.PriorityID = 1 THEN 'Standard' ELSE 'High' END, IntialCall.ClosedOn, dbo.Sites.SiteID, dbo.Sites.Name, dbo.Sites.Address1, 
                      dbo.Sites.PostCode, IntialCall.IncompleteDate, dbo.udfConcatCallReasons(Calls.ID), PlanningIssue.Description, ContractEngineers.Name, 
                      Abortedreason.Description

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_AutoReRaisedCalls] TO PUBLIC
    AS [dbo];

