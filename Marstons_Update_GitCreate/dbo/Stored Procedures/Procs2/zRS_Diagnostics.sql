CREATE PROCEDURE [dbo].[zRS_Diagnostics]

(     @STARTDATE DATETIME=NULL,
      @ENDDATE DATETIME= NULL
)

AS

SET NOCOUNT ON




SELECT     Configuration.PropertyValue AS Company, dbo.GetCallReference(Calls.ID) AS Callref, dbo.Calls.RaisedOn, dbo.Calls.ID,dbo.Calls.RaisedBy, 
                      CASE WHEN dbo.Calls.PriorityID = 1 THEN 'Standard' ELSE 'High' END AS Priority, 
                      CASE WHEN Calls.UseBillingItems = 1 THEN dbo.udfConcatCallReasons(Calls.ID) ELSE '' END AS CallReasonType, dbo.Sites.SiteID, dbo.Sites.Name, 
                      dbo.Sites.PostCode, dbo.Calls.PlanningIssueID, dbo.Calls.AbortReasonID, dbo.Calls.ClosedOn, GlobalCallReasonTypes.Description, 
                      GlobalCallType.Description AS GlobalCallType, dbo.Sites.Version, CASE WHEN dbo.Sites.Quality = 1 THEN 'Idraught' ELSE 'BMS' END AS Systemtype, 
                      GlobalDiagnostic.Description AS DiagnosticReason, dbo.CallReasons.ID AS CallReasonID,CAST(Configuration_1.PropertyValue AS INT) as DBASEID
                      
                      
FROM         dbo.Calls INNER JOIN
                      dbo.CallReasons ON CallReasons.CallID = Calls.ID INNER JOIN
                      [EDISSQL1\SQL1].ServiceLogger.dbo.CallReasonTypes AS GlobalCallReasonTypes ON 
                      dbo.CallReasons.ReasonTypeID = GlobalCallReasonTypes.ID INNER JOIN
                      dbo.Sites ON dbo.Calls.EDISID = dbo.Sites.EDISID INNER JOIN
                      [EDISSQL1\SQL1].ServiceLogger.dbo.CallCategories AS GlobalCallType ON Calls.CallCategoryID = GlobalCallType.ID INNER JOIN
                      dbo.Configuration ON dbo.Configuration.PropertyName = 'Company Name' INNER JOIN
                      
                      
                      dbo.Configuration AS Configuration_1  ON Configuration_1.PropertyName = 'Service Owner ID'
                      INNER JOIN
                      
                      [EDISSQL1\SQL1].ServiceLogger.dbo.CallDiagnostics AS GlobalDiagnostic ON GlobalCallReasonTypes.DiagnosticID = GlobalDiagnostic.ID
WHERE     (Calls.AbortReasonID = 0) AND (dbo.Calls.ClosedOn IS NOT NULL) AND (dbo.Calls.ClosedOn BETWEEN @STARTDATE AND @ENDDATE)
GROUP BY Configuration.PropertyValue, dbo.GetCallReference(Calls.ID), dbo.Calls.RaisedOn, dbo.Calls.RaisedBy, dbo.Calls.PriorityID, 
                      dbo.udfConcatCallReasons(Calls.ID), dbo.Sites.SiteID, dbo.Sites.Name, dbo.Sites.PostCode, Calls.UseBillingItems, dbo.Calls.PlanningIssueID, 
                      dbo.Calls.AbortReasonID, dbo.Calls.ClosedOn, GlobalCallReasonTypes.Description, GlobalCallType.Description, dbo.Sites.Version, dbo.Sites.Quality, 
                     GlobalDiagnostic.Description, dbo.CallReasons.ID,CAST(Configuration_1.PropertyValue AS INT), dbo.Calls.ID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_Diagnostics] TO PUBLIC
    AS [dbo];

