CREATE PROCEDURE [dbo].[zRS_ElectricalWorks]

(     @From DATETIME=NULL,
      @To DATETIME= NULL
)

AS

SET NOCOUNT ON

SELECT     dbo.Configuration.PropertyValue AS Company, dbo.GetCallReference(dbo.Calls.ID) AS Callref, dbo.Calls.RaisedOn, dbo.Calls.RaisedBy, 
                      CASE WHEN dbo.Calls.PriorityID = 1 THEN 'Standard' ELSE 'High' END AS Priority, 
                      CASE WHEN Calls.UseBillingItems = 1 THEN dbo.udfConcatCallReasons(Calls.ID) ELSE '' END AS CallReasonType, 
                      CASE WHEN Calls.UseBillingItems = 1 THEN dbo.udfConcatCallBillingItems(Calls.ID) ELSE '' END AS CallBillingItems, dbo.Sites.SiteID, 
                      dbo.Sites.Name, dbo.Sites.PostCode, dbo.Calls.PlanningIssueID, dbo.Calls.ClosedOn, dbo.Calls.SalesReference, dbo.Calls.AuthCode, 
                      GlobalCallType.Description AS GlobalCallType, CASE WHEN dbo.Sites.Quality = 1 THEN 'iDraught' ELSE 'Standard' END AS Systemtype, 
                      dbo.ModemTypes.Description AS Commstype, dbo.Contracts.Description AS Contractname, dbo.Owners.Name AS Ownername
FROM         dbo.Calls LEFT OUTER JOIN
                      dbo.CallReasons ON dbo.CallReasons.CallID = dbo.Calls.ID LEFT OUTER JOIN
                      [EDISSQL1\SQL1].ServiceLogger.dbo.CallReasonTypes AS GlobalCallReasonTypes ON 
                      dbo.CallReasons.ReasonTypeID = GlobalCallReasonTypes.ID LEFT OUTER JOIN
                      dbo.Sites ON dbo.Calls.EDISID = dbo.Sites.EDISID LEFT OUTER JOIN
                      [EDISSQL1\SQL1].ServiceLogger.dbo.CallCategories AS GlobalCallType ON dbo.Calls.CallCategoryID = GlobalCallType.ID INNER JOIN
                      dbo.Configuration ON dbo.Configuration.PropertyName = 'Company Name' INNER JOIN
                      dbo.ModemTypes ON dbo.Sites.ModemTypeID = dbo.ModemTypes.ID INNER JOIN
                      dbo.Contracts ON dbo.Calls.ContractID = dbo.Contracts.ID INNER JOIN
                      dbo.CallBillingItems ON dbo.Calls.ID = dbo.CallBillingItems.CallID INNER JOIN
                      dbo.Owners ON dbo.Sites.OwnerID = dbo.Owners.ID LEFT OUTER JOIN
                      [EDISSQL1\SQL1].ServiceLogger.dbo.BillingItems AS GlobalBillingItem ON dbo.CallBillingItems.BillingItemID = GlobalBillingItem.ID


WHERE   (dbo.Calls.AbortReasonID = 0) AND (dbo.Calls.ClosedOn BETWEEN @From AND @To ) AND (dbo.Calls.UseBillingItems = 1) AND 
                     ( (dbo.CallBillingItems.BillingItemID IN (24, 25, 26, 27)) or GlobalCallReasonTypes.CategoryID =5)   
                      
--This brings back any jobs where work items were selected that had electrical works or were raised for electrial work required

GROUP BY Configuration.PropertyValue, GlobalCallType.Description, dbo.GetCallReference(Calls.ID), dbo.Calls.RaisedOn, dbo.Calls.RaisedBy, 
                      dbo.Calls.PriorityID, dbo.udfConcatCallReasons(Calls.ID), dbo.Sites.SiteID, dbo.Sites.Name, dbo.Sites.PostCode, Calls.UseBillingItems, 
                      dbo.Calls.PlanningIssueID, dbo.Calls.ClosedOn, dbo.Calls.SalesReference, dbo.Calls.AuthCode, dbo.Sites.Quality, 
                      dbo.ModemTypes.Description, dbo.Contracts.Description, dbo.udfConcatCallBillingItems(Calls.ID),dbo.Owners.Name

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_ElectricalWorks] TO PUBLIC
    AS [dbo];

