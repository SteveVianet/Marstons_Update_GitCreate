CREATE PROCEDURE [dbo].[zRS_InvoicedServiceCallsReport]

(
@From                 DATETIME = NULL,
@To                   DATETIME = NULL,
@IncludeStandardcalls BIT = 0,
@IncludeElectrical    BIT = 0,
@IncludeInstall       BIT = 0,
@IncludeInternal      BIT = 0,
@IncludeMaintenance   BIT = 0,
@IncludeReInstall     BIT = 0,
@IncludeUpgrade       BIT = 0,
@IncludeUplift        BIT = 0,
@IncludeThirdParty    BIT = 0
)
AS



SELECT   Configuration.PropertyValue                                          AS    Company
            ,Owners.Name                                                                  AS      Owner
           ,RODName
    ,BDMName
     ,Calls.ID
            ,dbo.GetCallReference(dbo.Calls.ID)                               AS    CallRef
            ,dbo.udfConcatCallReasons(Calls.ID) AS CallReasonType                                             
            ,SiteID                                                                             AS    SiteID      
            ,Sites.Name                                                                         AS    SiteName
            ,Sites.Address1                                                                     AS    Address
            ,PostCode                                                                     AS      PostCode
            ,VisitedOn                                                                    AS      VisitDate
            ,CASE WHEN AbortDate IS Null
                  THEN 'Complete'
                  ELSE 'Aborted'    
                  END                                                                           AS    Status
            ,dbo.udfConcatCallBillingItemsWithRetailPrice(Calls.ID, 1)                                            AS    BillingItems
            ,dbo.udfConcatCallObservations(Calls.ID)                                            AS    Observations
     ,CAST(CallWorkDetailComments.WorkDetailComment AS VARCHAR(8000))                    AS    InvoiceComment ,Calls.AuthCode                                                                     AS    POAuthCode
            ,Calls.SalesReference                                                               AS    SalesRef
            ,CASE WHEN Calls.InvoicedOn IS NULL
                  THEN 'No'
                  ELSE 'Yes'
                  END                                                                           AS    Checked
            ,IsChargeable
            --,ISNULL(CallFMCount.CountOfItems, 0) AS CountOfFlowmeters
            -- ,ISNULL(CallPanelCount.CountOfItems, 0) AS CountOfPanels
                  ,ISNULL(CallFMCount.TotalMetersCharged, 0) AS TotalMetersCharged
                  ,ISNULL(CallPanelCount.TotalPanelsCharged, 0) AS TotalPanelsCharged
                  ,ISNULL(CallModemCount.TotalModemscharged, 0) AS TotalModemscharged
 
            ,Calls.StandardLabourCharge
            ,Calls.AdditionalLabourCharge
            ,ISNULL(Parts.Cost, 0)                                                  AS      PartsCharge
            ,ISNULL(Parts.Cost, 0) 
                  + Calls.StandardLabourCharge
                  + Calls.AdditionalLabourCharge                                    AS    Net
            ,(ISNULL(Parts.Cost, 0) 
                  + Calls.StandardLabourCharge
                  + Calls.AdditionalLabourCharge)* (CallBillingItems.VAT/100)                   AS    VAT         
            ,ISNULL(Parts.Cost, 0) 
                  + Calls.StandardLabourCharge
                  + Calls.AdditionalLabourCharge                              
            +((ISNULL(Parts.Cost, 0) 
                  + Calls.StandardLabourCharge
                  + Calls.AdditionalLabourCharge)* (CallBillingItems.VAT/100))                  AS    Gross
            ,CASE Sites.Quality WHEN 1
                  THEN 'iDraught'
                  ELSE 'BMS'
                  END                                                                           AS  SystemType    
            ,Contracts.Description                                                  AS      [Contract]
            ,GlobalCallType.Description                                             AS      CallCategory
            ,GlobalCallRequest.Description                                          As      RequestedBy
            ,CASE WHEN Calls.AbortReasonID > 0 Then AbortReasons.Description ELSE '' END  AS            AbortReason
            ,CAST(EngineerComment.WorkDetailComment AS VARCHAR(8000))                                 AS          EngineerComment
            ,GlobalCallChargeReason.Description AS ChargeReason
 ,dbo.GetCallReference(dbo.Calls.ReRaiseFromCallID)                               AS    ReraisedCallRef
 
FROM        Calls 




LEFT JOIN   Sites                               ON    Calls.EDISID                        = Sites.EDISID 
JOIN        Owners                                    ON    Sites.OwnerID                       = Owners.ID 

JOIN        Configuration                       ON Configuration.PropertyName = 'Company Name' 
JOIN        Contracts                           ON Calls.ContractID                       = Contracts.ID
LEFT JOIN        CallBillingItems              ON Calls.ID                               = CallBillingItems.CallID 
LEFT JOIN   CallWorkDetailComments        ON Calls.ID                               = CallWorkDetailComments.CallID AND CallWorkDetailComments.IsInvoice = 1
LEFT JOIN InvoiceItems ON Calls.ID = InvoiceItems.CallID

INNER JOIN
(
 SELECT  Sites.EDISID
 ,Regions.Description AS Regn
 ,Areas.Description AS Area
 ,RODUsers.UserName AS RODName
 ,BDMUsers.UserName AS BDMName

 FROM 
 (
 SELECT UserSites.EDISID
  ,MAX(CASE WHEN Users.UserType = 1 THEN UserID ELSE 0 END) AS RODID
 ,MAX(CASE WHEN Users.UserType = 2 THEN UserID ELSE 0 END) AS BDMID

 FROM UserSites
 
 JOIN Users ON Users.ID = UserSites.UserID
 WHERE Users.UserType IN (1,2)
 
 GROUP BY UserSites.EDISID
 
  ) AS UsersTEMP

 JOIN Users AS RODUsers ON RODUsers.ID = UsersTEMP.RODID
 JOIN Users AS BDMUsers ON BDMUsers.ID = UsersTEMP.BDMID
 RIGHT JOIN Sites ON Sites.EDISID = UsersTEMP.EDISID
 Join Regions ON Sites.Region = Regions.ID
 JOIN Areas ON Sites.AreaID = Areas.ID


 ) AS MYUsers ON MYUsers.EDISID = Calls.EDISID



LEFT JOIN 
(
        SELECT CallID, SUM(Quantity) AS CountOfItems, SUM(FullRetailPrice) AS TotalMetersCharged
      FROM CallBillingItems
      JOIN Calls ON Calls.ID = CallBillingItems.CallID
      WHERE BillingItemID IN (35,36,37,38,39,40,41,42,71)
      GROUP BY CallID, Calls.StandardLabourCharge, Calls.AdditionalLabourCharge
) AS CallFMCount ON CallFMCount.CallID = Calls.ID


LEFT JOIN
(
      SELECT CallID, SUM(Quantity) AS CountOfItems, SUM(FullRetailPrice) AS TotalPanelsCharged
      FROM CallBillingItems
      JOIN Calls ON Calls.ID = CallBillingItems.CallID
      WHERE BillingItemID IN (31,32,58,59)
      GROUP BY CallID, Calls.StandardLabourCharge, Calls.AdditionalLabourCharge
) AS CallPanelCount ON CallPanelCount.CallID = Calls.ID

LEFT JOIN
(
      SELECT CallID, SUM(Quantity) AS CountOfItems, SUM(FullRetailPrice) AS TotalModemscharged
      FROM CallBillingItems
      JOIN Calls ON Calls.ID = CallBillingItems.CallID
      WHERE BillingItemID IN (55,56,57,60,61)
      GROUP BY CallID, Calls.StandardLabourCharge, Calls.AdditionalLabourCharge
) AS CallModemCount ON CallModemCount.CallID = Calls.ID




LEFT JOIN   (SELECT CallID
                        ,SUM(FullRetailPrice)   AS Cost
 
                        FROM CallBillingItems
                        WHERE FullRetailPrice > 0
                        GROUP BY CallID) AS Parts   ON Calls.ID = Parts.CallID

LEFT JOIN   (SELECT CallID
                        ,SUM(Cost)   AS Cost
 
                        FROM InvoiceItems
                        WHERE Cost > 0
                        GROUP BY CallID) AS OldParts   ON Calls.ID = OldParts.CallID

 
LEFT JOIN        [EDISSQL1\SQL1].ServiceLogger.dbo.CallCategories AS GlobalCallType ON dbo.Calls.CallCategoryID = GlobalCallType.ID 
LEFT JOIN        [EDISSQL1\SQL1].ServiceLogger.dbo.CallRequests   AS GlobalCallRequest ON dbo.Calls.RequestID = GlobalCallRequest.ID 
JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.AbortReasons AS AbortReasons ON AbortReasons.ID = Calls.AbortReasonID      

LEFT JOIN  [EDISSQL1\SQL1].[ServiceLogger].[dbo].[CallChargeReasons] AS GlobalCallChargeReason ON dbo.Calls.ChargeReasonID = GlobalCallChargeReason.ID 

 
LEFT JOIN
(
      SELECT CallWorkDetailComments.CallID, CallWorkDetailComments.WorkDetailComment
      FROM CallWorkDetailComments
      JOIN
      (
            SELECT CallID, MAX(ID) AS LastID
            FROM CallWorkDetailComments
            WHERE IsInvoice = 0
            GROUP BY CallID
      ) AS LastWorkDetailComment ON LastWorkDetailComment.CallID = CallWorkDetailComments.CallID AND LastWorkDetailComment.LastID = CallWorkDetailComments.ID
 
)  AS EngineerComment ON EngineerComment.CallID = Calls.ID    


 
WHERE Calls.AbortReasonID <> 3 AND

ClosedOn BETWEEN @From AND DATEADD(SECOND, -1, DATEADD(DAY, 1, @To))

 
      AND   (ISNULL(Parts.Cost, 0) +
                 ISNULL(OldParts.Cost, 0) +
                        + Calls.StandardLabourCharge
                        + Calls.AdditionalLabourCharge) > 0
                        AND InvoicedOn IS NOT NULL
                        AND IsChargeable = 1

AND ((Calls.CallCategoryID = 1 AND @IncludeStandardcalls = 1)
OR (Calls.CallCategoryID = 5 AND @IncludeElectrical = 1)
OR (Calls.CallCategoryID = 4 AND @IncludeInstall = 1)
OR (Calls.CallCategoryID = 3 AND @IncludeInternal = 1)
OR (Calls.CallCategoryID = 2 AND @IncludeMaintenance = 1)
OR (Calls.CallCategoryID = 6 AND @IncludeReInstall = 1)
OR (Calls.CallCategoryID = 9 AND @IncludeUpgrade = 1)
OR (Calls.CallCategoryID = 10 AND @IncludeUplift = 1)
OR (Calls.CallCategoryID = 7 AND @IncludeThirdParty = 1))


GROUP BY Configuration.PropertyValue
            ,Owners.Name     
 ,RODName
     ,BDMName 
            ,Calls.ID                                       
            ,dbo.GetCallReference(dbo.Calls.ID)                               
            ,SiteID                                                                 
            ,Sites.Name                                                                   
            ,Sites.Address1                                                                     
            ,PostCode                                                               
            ,VisitedOn                                                                    
            ,dbo.udfConcatCallBillingItemsWithRetailPrice(Calls.ID, 1)
            ,dbo.udfConcatCallObservations(Calls.ID)        
            ,dbo.udfLatestCallWorkDetailComment(Calls.ID)               
            ,Calls.StandardLabourCharge
            ,Calls.AdditionalLabourCharge
            ,Parts.Cost
            ,Contracts.Description
            ,Sites.Quality
            ,Calls.InvoicedOn
            ,Calls.AuthCode
            ,RaisedOn
            --,ISNULL(CallFMCount.CountOfItems, 0)
            --,ISNULL(CallPanelCount.CountOfItems, 0)
            ,ISNULL(CallFMCount.TotalMetersCharged, 0)
            ,ISNULL(CallPanelCount.TotalPanelsCharged, 0)
            ,ISNULL(CallModemCount.TotalModemscharged, 0)
            ,ClosedOn
            ,InvoicedOn
            ,Calls.UseBillingItems
            ,AbortDate
           ,CallBillingItems.VAT
            ,IsChargeable
            ,GlobalCallType.Description
            ,GlobalCallRequest.Description
            ,GlobalCallChargeReason.Description
 ,Calls.ReRaiseFromCallID
 ,Calls.SalesReference                                                   
            ,CAST(CallWorkDetailComments.WorkDetailComment AS VARCHAR(8000))        
            ,CASE WHEN Calls.AbortReasonID > 0 Then AbortReasons.Description ELSE '' END
            ,CAST(EngineerComment.WorkDetailComment AS VARCHAR(8000))
 
ORDER BY VisitedOn, SiteID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_InvoicedServiceCallsReport] TO PUBLIC
    AS [dbo];

