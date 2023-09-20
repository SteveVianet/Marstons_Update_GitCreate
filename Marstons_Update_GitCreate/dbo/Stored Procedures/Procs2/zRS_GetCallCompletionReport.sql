CREATE PROCEDURE [dbo].[zRS_GetCallCompletionReport]
(
@From       DATETIME    = NULL,
@To         DATETIME    = NULL,
@EngineerID INT         = NULL,
@LeadEngineerID   INT   = NULL
)

AS

SELECT      Configuration.PropertyValue                                                   AS Company
--          ,InitialCall.ID         
            ,dbo.GetCallReference(InitialCall.ID)                                         AS FirstCallRef                        
            ,CASE WHEN InitialCall.PriorityID = 1 THEN 'Standard'
            ELSE 'High' END                                                               AS Priority
            ,CallsSLA.CallWithinSLA							
            ,dbo.udfConcatCallReasons(InitialCall.ID)                                     AS CallReasons
            ,FirstEngineers.LeadEngineerID
            ,FirstEngineers.Name                                                          AS FirstEngineer
            ,InitialCall.RaisedOn
            ,InitialCall.ClosedOn
            ,CASE FirstIncompleteReasons.ReduceSLAForRevisit WHEN 1
            THEN 'YES' ELSE 'NO' END                                                      AS EnginnerFault
            ,CASE WHEN FirstIncompleteReasons.ID > 0 
            THEN 1 ELSE 0 END															  AS Incomplete
            ,FirstIncompleteReasons.Description                                           AS FirstIncompleteReason
            ,CASE WHEN FirstIncompleteReasons.Description = 'None' THEN NULL
            ELSE InitialCall.IncompleteDate END                                           AS IncompleteDate
            ,CASE WHEN AbortedReason.ID > 0
            THEN 1 ELSE 0 END															  AS Aborted
            ,AbortedReason.Description                                                    AS FirstAbortedReason
            ,PlanningIssue.Description                                                    AS FirstPlanningIssue

            ,Calls.RaisedOn
            ,dbo.GetCallReference(Calls.ID)                                               AS SecondCallRef
            ,dbo.udfConcatCallReasons(Calls.ID)                                           AS SecondCallReasons

FROM    dbo.Calls

RIGHT JOIN  Calls AS InitialCall ON InitialCall.ID = Calls.ReRaiseFromCallID

JOIN		CallsSLA ON CallsSLA.ID = InitialCall.ID

RIGHT JOIN  [EDISSQL1\SQL1].ServiceLogger.dbo.ContractorEngineers AS FirstEngineers ON FirstEngineers.ID = InitialCall.EngineerID 
--JOIN      [EDISSQL1\SQL1].ServiceLogger.dbo.ContractorEngineers AS RevisitEngineers ON RevisitEngineers.ID = Calls.EngineerID 

RIGHT JOIN  [EDISSQL1\SQL1].ServiceLogger.dbo.CallIncompleteReasons AS FirstIncompleteReasons ON FirstIncompleteReasons.ID = InitialCall.IncompleteReasonID
--JOIN      [EDISSQL1\SQL1].ServiceLogger.dbo.CallIncompleteReasons AS SecondIncompleteReasons ON SecondIncompleteReasons.ID = Calls.IncompleteReasonID

RIGHT JOIN  [EDISSQL1\SQL1].ServiceLogger.dbo.AbortReasons AS AbortedReason ON AbortedReason.ID = InitialCall.AbortReasonID

RIGHT JOIN  [EDISSQL1\SQL1].ServiceLogger.dbo.CallPlanningIssues AS PlanningIssue ON PlanningIssue.ID  = InitialCall.PlanningIssueID 

JOIN  Configuration ON Configuration.PropertyName = 'Company Name' 

WHERE

InitialCall.ClosedOn BETWEEN @From AND DATEADD(SECOND, -1, DATEADD(DAY, 1, @To))

AND (FirstEngineers.ID = @EngineerID OR @EngineerID IS NULL)
AND (FirstEngineers.LeadEngineerID = @LeadEngineerID OR @LeadEngineerID IS NULL)
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_GetCallCompletionReport] TO PUBLIC
    AS [dbo];

