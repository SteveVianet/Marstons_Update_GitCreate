CREATE PROCEDURE [dbo].[zRS_GetCallsPORequired]


(
      @From DATETIME = NULL,
      @To         DATETIME = NULL
)
AS

SET NOCOUNT ON

SET DATEFIRST 1   

SELECT     dbo.GetCallReference(Calls.ID)as Callref , dbo.Calls.EDISID, dbo.Calls.RaisedOn, dbo.Calls.RaisedBy, 
                      CASE WHEN dbo.Calls.PriorityID = 1 THEN 'Standard' ELSE 'High' END AS Priority, 
                      CASE WHEN dbo.Calls.POStatusID = 2 THEN 'Required' ELSE 'Requested' END AS POStatus, dbo.Calls.POConfirmed, dbo.Calls.SignedBy, 
                      dbo.Calls.AuthCode, dbo.Calls.POStatusID, dbo.Calls.SalesReference, dbo.Contracts.Description, dbo.udfConcatCallReasons(Calls.ID) 
                      AS CallReasonType, dbo.Sites.SiteID, dbo.Sites.Name, dbo.Sites.PostCode
FROM         dbo.Calls INNER JOIN
                      dbo.CallReasons ON CallReasons.CallID = Calls.ID INNER JOIN
                      [EDISSQL1\SQL1].ServiceLogger.dbo.CallReasonTypes AS GlobalCallReasonTypes ON 
                      dbo.CallReasons.ReasonTypeID = GlobalCallReasonTypes.ID INNER JOIN
                      dbo.Sites ON dbo.Calls.EDISID = dbo.Sites.EDISID LEFT OUTER JOIN
                      dbo.Contracts ON dbo.Calls.ContractID = dbo.Contracts.ID
WHERE     (dbo.Calls.POConfirmed IS NULL) AND (dbo.Calls.ClosedOn IS NULL) AND (dbo.Calls.AbortReasonID = 0) AND (dbo.Calls.POStatusID = 2 OR
                      dbo.Calls.POStatusID = 3) and  ((dbo.Calls.RaisedOn BETWEEN @From AND @To) OR (@From IS NULL AND @To IS NULL))
GROUP BY    dbo.GetCallReference(Calls.ID), dbo.Calls.EDISID, dbo.Calls.RaisedOn, dbo.Calls.RaisedBy, 
                      CASE WHEN dbo.Calls.PriorityID = 1 THEN 'Standard' ELSE 'High' END, 
                      CASE WHEN dbo.Calls.POStatusID = 2 THEN 'Required' ELSE 'Requested' END, dbo.Calls.POConfirmed, dbo.Calls.SignedBy, 
                      dbo.Calls.AuthCode, dbo.Calls.POStatusID, dbo.Calls.SalesReference, dbo.Contracts.Description, dbo.udfConcatCallReasons(Calls.ID), dbo.Sites.SiteID, dbo.Sites.Name, dbo.Sites.PostCode

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_GetCallsPORequired] TO PUBLIC
    AS [dbo];

