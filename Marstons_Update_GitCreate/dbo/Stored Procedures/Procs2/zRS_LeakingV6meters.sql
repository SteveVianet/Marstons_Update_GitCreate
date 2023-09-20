CREATE PROCEDURE [dbo].[zRS_LeakingV6meters]

(
@From DATETIME = NULL
)
AS
SELECT     Configuration.PropertyValue AS Company, dbo.GetCallReference(Calls.ID) AS Callref, dbo.Calls.RaisedOn, dbo.Calls.RaisedBy, 
                      CASE WHEN dbo.Calls.PriorityID = 1 THEN 'Standard' ELSE 'High' END AS Priority, 
                      CASE WHEN dbo.CallBillingItems.BillingItemID = 117 THEN 'Leaking V6' END AS LeakerID, 
                      dbo.udfConcatCallReasons(Calls.ID) AS CallReasonType, 
                      dbo.Sites.SiteID, dbo.Sites.Name, dbo.Sites.PostCode, dbo.udfConcatCallWorkDetailComments(Calls.[ID], Calls.RaisedOn) AS Callcomments,
                      ContractEngineers.Name AS Engineer
FROM         dbo.Calls INNER JOIN
                      dbo.CallReasons ON CallReasons.CallID = Calls.ID INNER JOIN
                      [EDISSQL1\SQL1].ServiceLogger.dbo.CallReasonTypes AS GlobalCallReasonTypes ON 
                      dbo.CallReasons.ReasonTypeID = GlobalCallReasonTypes.ID INNER JOIN
                      dbo.Sites ON dbo.Calls.EDISID = dbo.Sites.EDISID INNER JOIN
                      dbo.CallBillingItems ON dbo.CallReasons.CallID = dbo.CallBillingItems.CallID INNER JOIN
                      [EDISSQL1\SQL1].ServiceLogger.dbo.BillingItems AS GlobalBillingitems ON dbo.CallBillingItems.BillingItemID = GlobalBillingitems.ID LEFT OUTER JOIN
                      dbo.Contracts ON dbo.Calls.ContractID = dbo.Contracts.ID INNER JOIN
                      [EDISSQL1\SQL1].ServiceLogger.dbo.ContractorEngineers AS ContractEngineers ON ContractEngineers.[ID] = Calls.EngineerID
                      JOIN Configuration ON PropertyName = 'Company Name'
WHERE     (dbo.Calls.ClosedOn >@From OR @From IS NULL) AND (dbo.CallBillingItems.BillingItemID IN (117)) 
GROUP BY         Configuration.PropertyValue,dbo.GetCallReference(Calls.ID), dbo.Calls.RaisedOn, dbo.Calls.RaisedBy, 
                      CASE WHEN dbo.Calls.PriorityID = 1 THEN 'Standard' ELSE 'High' END, 
                      CASE WHEN dbo.CallBillingItems.BillingItemID = 117 THEN 'Leaking V6' END, 
                      dbo.udfConcatCallReasons(Calls.ID), 
                      dbo.Sites.SiteID, dbo.Sites.Name, dbo.Sites.PostCode, dbo.udfConcatCallWorkDetailComments(Calls.[ID], Calls.RaisedOn),
                      ContractEngineers.Name


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_LeakingV6meters] TO PUBLIC
    AS [dbo];

