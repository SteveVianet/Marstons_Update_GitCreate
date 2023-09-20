CREATE PROCEDURE [dbo].[zRS_FinanceInvoiceChecker] 
(
      @From DATETIME = NULL,
      @To         DATETIME = NULL
)
AS

SET NOCOUNT ON

DECLARE @DatabaseID INT

SELECT @DatabaseID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

SELECT     CallCategories.Description AS CallType, CASE WHEN Calls.UseBillingItems = 1 THEN dbo.udfConcatCallReasonsSingleLine(Calls.[ID]) 
                      ELSE dbo.udfConcatCallFaults(Calls.[ID]) END AS CallOutReason, dbo.GetCallReference(Calls.ID) AS CallID, Sites.SiteID, 
                      CASE WHEN Calls.QualitySite = 1 THEN 'iDraught' ELSE 'BMS' END AS SystemType, Contracts.Description AS Contract, Sites.Name, Sites.PostCode, 
                      CASE WHEN Calls.UseBillingItems = 1 THEN REPLACE(dbo.udfConcatCallBillingItems(Calls.[ID]), '<br>', '') 
                      ELSE dbo.GetWorkItemDescriptionFunction(Calls.[ID]) END AS WorkCompleted, 
                      CASE WHEN dbo.Calls.AbortReasonID > 0 THEN 'Aborted' ELSE '' END AS Aborted, 
                      CASE WHEN dbo.Calls.IncompleteReasonID > 0 THEN 'Incomplete' ELSE '' END AS Incomplete, Calls.VisitStartedOn, Calls.VisitEndedOn, 
                      CallLabourMinutes.EstMinutesOnSite, DATEDIFF(MINUTE, Calls.VisitStartedOn, Calls.VisitEndedOn) AS ActualMinutesOnSite, 
                      dbo.Contracts.Description, dbo.Calls.IsChargeable, dbo.Calls.InvoicedOn, dbo.Calls.InvoicedBy, dbo.Calls.RaisedOn, 
                      dbo.Owners.Name AS Owners
FROM         [EDISSQL1\SQL1].ServiceLogger.dbo.EngineerJobs AS EngineerJobs INNER JOIN
                      dbo.Calls ON Calls.ID = EngineerJobs.CallID AND EngineerJobs.DatabaseID = @DatabaseID INNER JOIN
                      dbo.Sites ON Sites.EDISID = Calls.EDISID INNER JOIN
                      dbo.Contracts ON Contracts.ID = Calls.ContractID INNER JOIN
                      [EDISSQL1\SQL1].ServiceLogger.dbo.ContractorEngineers AS Engineers ON Engineers.ID = EngineerJobs.EngineerID LEFT OUTER JOIN
                      [EDISSQL1\SQL1].ServiceLogger.dbo.Logins AS Logins ON Logins.ID = Engineers.LoginID INNER JOIN
                      [EDISSQL1\SQL1].ServiceLogger.dbo.CallCategories AS CallCategories ON CallCategories.ID = Calls.CallCategoryID INNER JOIN
                      dbo.Owners ON dbo.Sites.OwnerID = dbo.Owners.ID LEFT OUTER JOIN
                          (SELECT     CallID, SUM(LabourMinutes) AS EstMinutesOnSite
                            FROM          dbo.CallBillingItems
                            GROUP BY CallID) AS CallLabourMinutes ON CallLabourMinutes.CallID = Calls.ID
WHERE (dbo.Calls.InvoicedBy IS NOT NULL) AND (dbo.Calls.InvoicedOn >= @From) AND (dbo.Calls.InvoicedOn <= @To) OR
                      (dbo.Calls.InvoicedOn>= @From) AND (@To IS NULL) OR
                      (dbo.Calls.InvoicedOn<= @To) AND (@From IS NULL) OR
                      (@To IS NULL) AND (@From IS NULL)
ORDER BY dbo.Calls.VisitEndedOn

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_FinanceInvoiceChecker] TO PUBLIC
    AS [dbo];

