CREATE PROCEDURE [dbo].[zRS_EngineerJobSummary]

(

@From       DATETIME    = NULL,

@To         DATETIME    = NULL

)

AS



SELECT

              LeadEngineerID

              ,Engineers.LoginID

              ,EngineerID

              ,VisitedOn

              ,VisitStartedOn

              ,VisitEndedOn

			  ,ClosedOn

			  ,CallsSLA.PlanningIssueID

              ,CallsSLA.CallTypeID

              ,CallsSLA.ID

              ,CallsSLA.CallWithinSLA

              ,CASE WHEN (CallsSLA.PriorityID =2) THEN 1 ELSE 0 END AS PriorityCalls

        ,CASE WHEN (CallsSLA.PriorityID =2 AND CallsSLA.CallWithinSLA=1) THEN 1 ELSE 0 END AS PriorityInSLA

              ,CASE WHEN (CallsSLA.IncompleteReasonID = 0 AND CallsSLA.AbortReasonID = 0)

              THEN 1 ELSE 0 END                                                                 AS       #RightFirstTime

              ,IncompleteReason.ReduceSLAForRevisit                   AS    IncompleteAvoidable

              ,CallsSLA.AbortReasonID                                                    AS       AbortedReasonID

              ,CallsSLA.IsChargeable

              ,CASE WHEN CallsSLA.InvoicedOn IS NOT NULL

              THEN 1 ELSE 0 END                                                                 AS       #IsInvoiced

              ,BillingTime

              ,ObservationTime

              ,InternalTime

              ,DeadTime                                                                                AS     TotalDeadtime

              ,DeadTime.WaitingForLandlord

              ,DeadTime.WaitingAuthorisation

              ,DeadTime.WaitingTechnicalHelp

 

FROM CallsSLA

 

LEFT JOIN CallBillingItems ON CallBillingItems.CallID = CallsSLA.ID

JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.ContractorEngineers AS Engineers ON CallsSLA.EngineerID = Engineers.ID

 

JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.CallIncompleteReasons AS IncompleteReason ON IncompleteReason.ID = CallsSLA.IncompleteReasonID

 

 

LEFT JOIN (

                           SELECT CallID

              ,SUM(CASE WHEN BillingItems.ItemType = 1

              THEN CallBillingItems.LabourMinutes END) AS BillingTime

              ,SUM(CASE WHEN BillingItems.ItemType = 2

              THEN CallBillingItems.LabourMinutes END) AS ObservationTime

              ,SUM(CASE WHEN BillingItems.ItemType = 3

              THEN CallBillingItems.LabourMinutes END) AS InternalTime

              ,SUM(CASE WHEN BillingItems.ItemType = 4

              THEN CallBillingItems.LabourMinutes END) AS DeadTime

 

FROM CallBillingItems

 

JOIN [SQL1\SQL1].ServiceLogger.dbo.BillingItems AS BillingItems ON BillingItems.ID = CallBillingItems.BillingItemID

 

GROUP BY CallID

             

              )      AS CallTime ON CallTime.CallID = CallsSLA.ID          

 

 

LEFT JOIN (

                           SELECT Calls.ID      AS CallID    

                                         ,SUM(CASE WHEN CallBillingItems.BillingItemID = 104

                                         THEN Quantity  ELSE 0 END  )                                               AS WaitingForLandlord

 

                                         ,SUM(CASE WHEN CallBillingItems.BillingItemID = 105

                                         THEN Quantity  ELSE 0 END  )                                               AS WaitingAuthorisation

                                        

                                         ,SUM(CASE WHEN CallBillingItems.BillingItemID = 106

                                         THEN Quantity  ELSE 0 END  )                                               AS WaitingTechnicalHelp   

                                                                                               

                           FROM Calls

 

                           JOIN   CallBillingItems ON CallBillingItems.CallID = Calls.ID

                           JOIN   [SQL1\SQL1].ServiceLogger.dbo.BillingItems AS BillingItems ON BillingItems.ID = CallBillingItems.BillingItemID

 

 

                           WHERE ClosedOn BETWEEN @From AND @To

 

                           GROUP BY Calls.ID

             

              )      AS DeadTime ON DeadTime.CallID = CallsSLA.ID          

 

 

 

 

WHERE CAST(ClosedOn AS DATE) BETWEEN @From AND @To

       AND EngineerID <> 105

       AND AbortReasonID <> 3

 

GROUP BY

              LeadEngineerID

              ,LoginID

              ,EngineerID

              ,VisitedOn

              ,VisitStartedOn

              ,VisitEndedOn

			  ,ClosedOn

              ,CallsSLA.CallTypeID

              ,CallsSLA.ID

              ,CallsSLA.CallWithinSLA

              ,CallsSLA.PriorityID

              ,BillingTime

              ,ObservationTime

              ,InternalTime

              ,DeadTime

              ,WaitingForLandlord

              ,WaitingAuthorisation

              ,WaitingTechnicalHelp

              ,CallsSLA.IncompleteReasonID

              ,CallsSLA.IsChargeable

              ,CallsSLA.InvoicedOn

              ,IncompleteReason.ReduceSLAForRevisit

              ,CallsSLA.AbortReasonID
			  ,CallsSLA.PlanningIssueID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_EngineerJobSummary] TO PUBLIC
    AS [dbo];

