CREATE PROCEDURE [dbo].[zRS_EngineerPerformanceJobs]

(
@From       DATETIME    = NULL,
@To         DATETIME    = NULL,
@EngineerID INT         = NULL,
@LeadEngineerID INT		= NULL,
@PlannerID	INT			= NULL
)

AS

SELECT     
                    Company.PropertyValue                                                                 AS Company
                  ,DatabaseID.PropertyValue                                                               AS DatabaseID
                  ,Calls.EngineerID                                                                       AS EngineerID
                  ,Engineers.LeadEngineerID                                                               AS LeadEngineerID
                  ,Logins.ID																			  AS PlannerID	   
                  ,Sites.SiteID
                  ,Sites.Name
                  ,Sites.PostCode  
                  ,CASE WHEN Calls.QualitySite = 1 
                        THEN 'iDraught' 
                        ELSE 'BMS' END AS SystemType
                  ,CallTypes.Description                                                                                              AS CallType           
                  ,CallCategories.Description                                                             AS CallCategory
                  ,Calls.ID
                  ,dbo.GetCallReference(Calls.ID)                                                         AS CallRef
                  
                  
                  ,CASE WHEN Calls.UseBillingItems = 1 
                        THEN dbo.udfConcatCallReasonsSingleLine(Calls.[ID]) 
                        ELSE dbo.udfConcatCallFaults(Calls.[ID])END                                       AS CallOutReason
                        
                  ,CASE WHEN Calls.UseBillingItems = 1 
                        THEN REPLACE(dbo.udfConcatCallBillingItems(Calls.[ID]), '<br>', '') 
                        ELSE dbo.GetWorkItemDescriptionFunction(Calls.[ID]) END                           AS WorkCompleted
                                   
                  ,CASE WHEN Calls.UseBillingItems = 1 
                        THEN dbo.udfConcatCallBillingItemsWithLabourMinutes(Calls.ID) 
                        ELSE NULL END                                                                     AS CallBillingItems

                  , Calls.WorkDetailComment      
                        
                  ,CASE WHEN dbo.Calls.AbortReasonID >0 
                        THEN 'Aborted' 
                        ELSE '' END                                                                       AS Aborted
                  ,AbortReasons.Description                                                               AS AbortReason  
                                              
                  ,CASE WHEN dbo.Calls.IncompleteReasonID >0 
                        THEN 'Incomplete' 
                        ELSE '' END                                                                       AS Incomplete
                  ,IncompleteReasons.Description                                                          AS IncompleteReason
                        
                  ,Calls.VisitStartedOn
                  ,Calls.VisitEndedOn
                  ,CallLabourMinutes.TotalLabour	                                                      AS EstMinutesOnSite
                  ,CallDeadtime.Deadtime																  AS Deadtime
                  ,dbo.udfConcatCallBillingItemsDeadTime(Calls.ID)										  AS DeadtimeReasons	
                  ,DATEDIFF(MINUTE, Calls.VisitStartedOn, Calls.VisitEndedOn)                             AS ActualMinutesOnSite
                  
                  , EngineerComment.WorkDetailComment                                                     AS EngineerNotes
                  
                  , CalibratorTimes.WaitTime
                  , CalibratorTimes.TotalTimeonCall

                      
FROM        Calls

JOIN  Configuration AS Company                  ON Company.PropertyName       = 'Company Name'
JOIN  Configuration AS DatabaseID               ON DatabaseID.PropertyName    = 'Service Owner ID'

JOIN  dbo.Sites         ON Sites.EDISID = Calls.EDISID 

JOIN  [EDISSQL1\SQL1].ServiceLogger.dbo.CallCategories AS CallCategories ON CallCategories.ID = Calls.CallCategoryID 
JOIN  [EDISSQL1\SQL1].ServiceLogger.dbo.AbortReasons AS AbortReasons ON AbortReasons.ID = Calls.AbortReasonID
JOIN  [EDISSQL1\SQL1].ServiceLogger.dbo.CallIncompleteReasons AS IncompleteReasons ON IncompleteReasons.ID = Calls.IncompleteReasonID

JOIN  [EDISSQL1\SQL1].ServiceLogger.dbo.CallTypes AS CallTypes ON CallTypes.ID = Calls.CallTypeID

JOIN  [EDISSQL1\SQL1].ServiceLogger.dbo.ContractorEngineers AS Engineers ON Engineers.ID = Calls.EngineerID

JOIN	[EDISSQL1\SQL1].ServiceLogger.dbo.Logins AS Logins ON Logins.ID = Engineers.LoginID

LEFT JOIN (

      SELECT CalibratorJobs.DatabaseID
            , CalibratorJobs.CallID
            , WaitTime                                                              AS WaitTime
            , SUM(DATEDIFF(SECOND, TimeTaken, TimeCompleted))     AS TotalTimeonCall
            
            FROM        (

                        SELECT TEMP.DatabaseID
                              , TEMP.CallID
                              , SUM(DATEDIFF(SECOND, TimeLogged, TimeTaken)) AS WaitTime
                        
                        FROM [EDISSQL1\SQL1].ServiceLogger.dbo.CalibratorJobs AS TEMP

                        WHERE TEMP.ReleasedBy IS NULL
                        AND TEMP.TimeLogged >= '2012-01-01'
                        
                        GROUP BY TEMP.DatabaseID, TEMP.CallID
      
                  ) AS WaitTime
      
      
      JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.CalibratorJobs AS CalibratorJobs ON (WaitTime.DatabaseID = CalibratorJobs.DatabaseID
                                    AND WaitTime.CallID = CalibratorJobs.CallID)
                                    
      GROUP BY CalibratorJobs.DatabaseID , CalibratorJobs.CallID ,WaitTime 
      
      )
            AS CalibratorTimes ON CalibratorTimes.CallID = Calls.ID AND CalibratorTimes.DatabaseID = CAST(DatabaseID.PropertyValue AS INTEGER)


LEFT OUTER JOIN   
      (SELECT 
           CallID
           ,SUM(LabourMinutes) AS TotalLabour
       
      FROM CallBillingItems
           
      GROUP BY CallID         

) AS CallLabourMinutes ON CallLabourMinutes.CallID = Calls.ID


LEFT OUTER JOIN   
      (SELECT 
                        CallID
                        ,SUM(CallBillingItems.Quantity) AS Deadtime
                
                    FROM CallBillingItems
                        JOIN Calls ON Calls.ID = CallBillingItems.CallID
                        JOIN [SQL1\SQL1].ServiceLogger.dbo.BillingItems AS MasterBilling ON MasterBilling.ID = CallBillingItems.BillingItemID
            
            WHERE MasterBilling.ItemType = 4 
                        
            GROUP BY CallID         

) AS CallDeadtime ON CallDeadtime.CallID = Calls.ID



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
AND (Logins.ID = @PlannerID OR @PlannerID IS NULL)   
                                         
ORDER BY VisitEndedOn
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_EngineerPerformanceJobs] TO PUBLIC
    AS [dbo];

