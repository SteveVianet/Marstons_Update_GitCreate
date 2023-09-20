CREATE PROCEDURE [dbo].[zRS_MinorWorks]
(
      @Fromdate as DATETIME =NULL
)
AS

SELECT     dbo.GetCallReference(Calls.ID) AS Callref, MAX (dbo.Calls.RaisedOn) as Raisedon, dbo.Calls.RaisedBy, dbo.udfConcatCallReasons(Calls.ID) AS CallReasonType, 
                      dbo.Sites.SiteID, dbo.Sites.Name, dbo.Sites.PostCode,
                      dbo.CallWorkDetailComments.WorkDetailCommentBy, dbo.Calls.EDISID, CAST(Configuration.PropertyValue AS INTEGER) AS DatabaseID, Calls.ClosedOn
FROM         dbo.Calls INNER JOIN
                      dbo.CallReasons ON CallReasons.CallID = Calls.ID INNER JOIN
                      [EDISSQL1\SQL1].ServiceLogger.dbo.CallReasonTypes AS GlobalCallReasonTypes ON 
                      dbo.CallReasons.ReasonTypeID = GlobalCallReasonTypes.ID INNER JOIN
                      dbo.Sites ON dbo.Calls.EDISID = dbo.Sites.EDISID INNER JOIN
                      dbo.CallBillingItems ON dbo.CallReasons.CallID = dbo.CallBillingItems.CallID INNER JOIN
                      [EDISSQL1\SQL1].ServiceLogger.dbo.BillingItems AS GlobalBillingitems ON dbo.CallBillingItems.BillingItemID = GlobalBillingitems.ID INNER JOIN
                      dbo.CallWorkDetailComments ON dbo.Calls.ID = dbo.CallWorkDetailComments.CallID LEFT OUTER JOIN
                      dbo.Contracts ON dbo.Calls.ContractID = dbo.Contracts.ID
JOIN Configuration ON PropertyName = 'Service Owner ID'
WHERE     (dbo.Calls.ClosedOn IS NOT NULL) AND (dbo.CallBillingItems.BillingItemID = 82) AND (dbo.Calls.ClosedOn > @Fromdate OR @Fromdate IS NULL)
Group by dbo.Calls.EDISID,dbo.GetCallReference(Calls.ID), dbo.Calls.RaisedOn, dbo.Calls.RaisedBy, dbo.udfConcatCallReasons(Calls.ID), 
                      dbo.Sites.SiteID, dbo.Sites.Name, dbo.Sites.PostCode, 
                      dbo.CallWorkDetailComments.WorkDetailCommentBy, CAST(Configuration.PropertyValue AS INTEGER), Calls.ClosedOn

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_MinorWorks] TO PUBLIC
    AS [dbo];

