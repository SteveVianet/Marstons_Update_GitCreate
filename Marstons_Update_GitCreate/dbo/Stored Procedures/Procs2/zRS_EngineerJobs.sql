CREATE PROCEDURE [dbo].[zRS_EngineerJobs]
(
@From       DATETIME    = NULL,
@To         DATETIME    = NULL,
@EngineerID INT         = NULL,
@LeadEngineerID   INT   = NULL
)

AS

SELECT 
LeadEngineerID
,EngineerID
, VisitedOn
, VisitStartedOn
, VisitEndedOn
, Calls.CallTypeID
, Calls.ID
, ISNULL(SUM(LabourMinutes),0) AS TotalLabourMinutes

FROM Calls

LEFT JOIN CallBillingItems ON CallBillingItems.CallID = Calls.ID
JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.ContractorEngineers AS Engineers ON Calls.EngineerID = Engineers.ID 

WHERE CAST(VisitedOn AS DATE) BETWEEN @From AND @To
AND ClosedOn IS NOT NULL
AND AbortReasonID <> 3
AND VisitStartedOn IS NOT NULL
AND VisitEndedOn IS NOT NULL
AND (EngineerID = @EngineerID OR @EngineerID IS NULL) 
AND (LeadEngineerID = @LeadEngineerID OR @LeadEngineerID IS NULL) 


GROUP BY 
LeadEngineerID
,EngineerID
, VisitedOn
, VisitStartedOn
, VisitEndedOn
, Calls.CallTypeID
, Calls.ID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_EngineerJobs] TO PUBLIC
    AS [dbo];

