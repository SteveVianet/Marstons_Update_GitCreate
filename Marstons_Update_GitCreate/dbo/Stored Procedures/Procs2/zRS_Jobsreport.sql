CREATE PROCEDURE [dbo].[zRS_Jobsreport]

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

SELECT     dbo.Configuration.PropertyValue AS Company, dbo.GetCallReference(dbo.Calls.ID) AS Callref, dbo.Calls.RaisedOn, dbo.Calls.RaisedBy, 
                      CASE WHEN dbo.Calls.PriorityID = 1 THEN 'Standard' ELSE 'High' END AS Priority, 
                      CASE WHEN Calls.UseBillingItems = 1 THEN dbo.udfConcatCallReasons(Calls.ID) ELSE '' END AS CallReasonType, dbo.Sites.SiteID, dbo.Sites.Name, 
                      dbo.Sites.PostCode, dbo.Calls.PlanningIssueID, dbo.Calls.AbortReasonID, dbo.Calls.ClosedOn, dbo.Calls.SalesReference, dbo.Calls.AuthCode, 
                      GlobalCallType.Description AS GlobalCallType, CASE WHEN dbo.Sites.Quality = 1 THEN 'iDraught' ELSE 'Standard' END AS Systemtype, 
                      dbo.ModemTypes.Description AS Commstype, dbo.Contracts.Description AS Contractname, dbo.Calls.RequestID, GlobalCallRequests.Description
FROM         dbo.Calls LEFT OUTER JOIN
                      dbo.CallReasons ON dbo.CallReasons.CallID = dbo.Calls.ID LEFT OUTER JOIN
                      [EDISSQL1\SQL1].ServiceLogger.dbo.CallReasonTypes AS GlobalCallReasonTypes ON 
                      dbo.CallReasons.ReasonTypeID = GlobalCallReasonTypes.ID LEFT OUTER JOIN
                      
                      [EDISSQL1\SQL1].ServiceLogger.dbo.CallRequests AS GlobalCallRequests ON 
                      dbo.Calls.RequestID = GlobalCallRequests.ID LEFT OUTER JOIN
                      dbo.Sites ON dbo.Calls.EDISID = dbo.Sites.EDISID LEFT OUTER JOIN
                      [EDISSQL1\SQL1].ServiceLogger.dbo.CallCategories AS GlobalCallType ON dbo.Calls.CallCategoryID = GlobalCallType.ID INNER JOIN
                      dbo.Configuration ON dbo.Configuration.PropertyName = 'Company Name' INNER JOIN
                      dbo.ModemTypes ON dbo.Sites.ModemTypeID = dbo.ModemTypes.ID INNER JOIN
                      dbo.Contracts ON dbo.Calls.ContractID = dbo.Contracts.ID
WHERE ClosedOn BETWEEN @From AND DATEADD(SECOND, -1, DATEADD(DAY, 1, @To))
AND Calls.AbortReasonID <> 3

--We may at somepoint choose to exlude some calls based on the types
AND ((Calls.CallCategoryID = 1 AND @IncludeStandardcalls = 1)
OR (Calls.CallCategoryID = 5 AND @IncludeElectrical = 1)
OR (Calls.CallCategoryID = 4 AND @IncludeInstall = 1)
OR (Calls.CallCategoryID = 3 AND @IncludeInternal = 1)
OR (Calls.CallCategoryID = 2 AND @IncludeMaintenance = 1)
OR (Calls.CallCategoryID = 6 AND @IncludeReInstall = 1)
OR (Calls.CallCategoryID = 9 AND @IncludeUpgrade = 1)
OR (Calls.CallCategoryID = 10 AND @IncludeUplift = 1)
OR (Calls.CallCategoryID = 7 AND @IncludeThirdParty = 1))
GROUP BY Configuration.PropertyValue, GlobalCallType.Description, dbo.GetCallReference(Calls.ID), dbo.Calls.RaisedOn, dbo.Calls.RaisedBy, 
                      dbo.Calls.PriorityID, dbo.udfConcatCallReasons(Calls.ID), dbo.Sites.SiteID, dbo.Sites.Name, dbo.Sites.PostCode, Calls.UseBillingItems, 
                      dbo.Calls.PlanningIssueID, dbo.Calls.AbortReasonID, dbo.Calls.ClosedOn, dbo.Calls.SalesReference, dbo.Calls.AuthCode, dbo.Sites.Quality, 
                      dbo.ModemTypes.Description, dbo.Contracts.Description, dbo.Calls.RequestID, GlobalCallRequests.Description

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_Jobsreport] TO PUBLIC
    AS [dbo];

