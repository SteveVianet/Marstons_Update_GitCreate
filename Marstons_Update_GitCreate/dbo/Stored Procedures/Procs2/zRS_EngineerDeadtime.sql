CREATE PROCEDURE [dbo].[zRS_EngineerDeadtime]

(
@From       DATETIME    = NULL,
@To         DATETIME    = NULL,
@EngineerID INT         = NULL,
@LeadEngineerID INT           = NULL
)

AS
SELECT 
      Company.PropertyValue                                                              AS Company
    ,DatabaseID.PropertyValue                                                           AS DatabaseID
    ,Calls.EngineerID                                                                   AS EngineerID
 ,EngineerComment.WorkDetailComment AS Enginnercomment
    ,Engineers.LeadEngineerID  AS LeadEngineerID  
    ,Engineers.Name AS EngineerName                                                 
      ,CallBillingItems.CallID
      ,dbo.Sites.Name
      ,dbo.Sites.PostCode
      ,dbo.GetCallReference(Calls.ID)                                                                                   AS CallRef
      ,VisitedOn 
      ,BillingItems.ItemType
      ,BillingItemID  
      ,BillingItems.Description                                                                                         AS Item           
      ,Quantity


FROM Calls

JOIN  Configuration AS Company                  ON Company.PropertyName       = 'Company Name'
JOIN  Configuration AS DatabaseID               ON DatabaseID.PropertyName    = 'Service Owner ID'

JOIN CallBillingItems ON CallBillingItems.CallID = Calls.ID
JOIN [SQL1\SQL1].ServiceLogger.dbo.BillingItems AS BillingItems ON BillingItems.ID = CallBillingItems.BillingItemID      
JOIN dbo.Sites ON dbo.Sites.EDISID = Calls.EDISID

JOIN  [EDISSQL1\SQL1].ServiceLogger.dbo.ContractorEngineers AS Engineers ON Engineers.ID = Calls.EngineerID

LEFT JOIN
      (  SELECT   CallWorkDetailComments.CallID
                        , CallWorkDetailComments.WorkDetailComment
 
                        FROM CallWorkDetailComments
                          JOIN
                          (
                                    SELECT CallID, MAX(ID) AS LastID
                                    FROM CallWorkDetailComments
                                    WHERE IsInvoice = 0
                                    GROUP BY CallID
                          ) AS LastWorkDetailComment ON LastWorkDetailComment.CallID = CallWorkDetailComments.CallID AND LastWorkDetailComment.LastID = CallWorkDetailComments.ID
 
      )  AS EngineerComment ON EngineerComment.CallID = Calls.ID


WHERE      

dbo.Calls.ClosedOn IS NOT NULL 

AND Calls.VisitedOn BETWEEN @From AND @To

AND (Calls.EngineerID = @EngineerID OR @EngineerID IS NULL)
AND (Engineers.LeadEngineerID = @LeadEngineerID OR @LeadEngineerID IS NULL)
AND BillingItems.ItemType = 4

ORDER BY CallID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_EngineerDeadtime] TO PUBLIC
    AS [dbo];

