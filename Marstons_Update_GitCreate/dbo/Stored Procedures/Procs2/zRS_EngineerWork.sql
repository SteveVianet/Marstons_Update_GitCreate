CREATE PROCEDURE [dbo].[zRS_EngineerWork]
(
      @From DATETIME,
      @To         DATETIME
)
AS

SET NOCOUNT ON

DECLARE @DatabaseID INT

SELECT @DatabaseID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

SELECT     Engineers.Name AS Engineer, dbo.udfNiceName(Logins.Login) AS Planner, DATEADD(MINUTE, DATEPART(MINUTE, EngineerJobs.StartTime), 
                      DATEADD(HOUR, DATEPART(HOUR, EngineerJobs.StartTime), EngineerJobs.JobDate)) AS BookedOn, CallCategories.Description AS CallType, 
                      CASE WHEN Calls.UseBillingItems = 1 THEN dbo.udfConcatCallReasonsSingleLine(Calls.[ID]) ELSE dbo.udfConcatCallFaults(Calls.[ID]) 
                      END AS CallOutReason, dbo.GetCallReference(Calls.ID) AS CallID, Sites.SiteID, 
                      CASE WHEN Calls.QualitySite = 1 THEN 'iDraught' ELSE 'BMS' END AS SystemType, Contracts.Description AS Contract, Sites.Name, Sites.PostCode, 
                      CASE WHEN Calls.UseBillingItems = 1 THEN REPLACE(dbo.udfConcatCallBillingItems(Calls.[ID]), '<br>', '') ELSE dbo.GetWorkItemDescriptionFunction(Calls.[ID]) END AS WorkCompleted,
                      CASE WHEN dbo.Calls.AbortReasonID >0 THEN 'Aborted' ELSE '' END as Aborted,
                      CASE WHEN dbo.Calls.IncompleteReasonID >0 THEN 'Incomplete' ELSE '' END as Incomplete,
                      Calls.VisitStartedOn, Calls.VisitEndedOn, 
                      CallLabourMinutes.EstMinutesOnSite, DATEDIFF(MINUTE, Calls.VisitStartedOn, Calls.VisitEndedOn) AS ActualMinutesOnSite,  
                      InstallNewPanelQuantity,InstallRefurbPanelQuantity,NewMetersQuantity,RefurbMetersQuantity,Socketinstalled,Transfersocket,ProvidedCleanSecure,CabledBarCellar,BarsCabled,Clearedglasses,AmbientSensors,RecircMeters,LaggedLines
                      
FROM         [EDISSQL1\SQL1].ServiceLogger.dbo.EngineerJobs AS EngineerJobs INNER JOIN
                      dbo.Calls ON Calls.ID = EngineerJobs.CallID AND EngineerJobs.DatabaseID = @DatabaseID INNER JOIN
                      dbo.Sites ON Sites.EDISID = Calls.EDISID INNER JOIN
                      dbo.Contracts ON Contracts.ID = Calls.ContractID INNER JOIN
                      [EDISSQL1\SQL1].ServiceLogger.dbo.ContractorEngineers AS Engineers ON Engineers.ID = EngineerJobs.EngineerID LEFT OUTER JOIN
                      [EDISSQL1\SQL1].ServiceLogger.dbo.Logins AS Logins ON Logins.ID = Engineers.LoginID INNER JOIN
                      [EDISSQL1\SQL1].ServiceLogger.dbo.CallCategories AS CallCategories ON CallCategories.ID = Calls.CallCategoryID LEFT OUTER JOIN
                          (SELECT     CallID, SUM(LabourMinutes) AS EstMinutesOnSite
                            FROM          dbo.CallBillingItems
                            GROUP BY CallID) AS CallLabourMinutes ON CallLabourMinutes.CallID = Calls.ID
                            LEFT JOIN
(
      SELECT      CallID, 
                        SUM(CASE WHEN CallBillingItems.BillingItemID = 32 THEN Quantity ELSE 0 END) AS InstallNewPanelQuantity,
                        SUM(CASE WHEN CallBillingItems.BillingItemID = 31 THEN Quantity ELSE 0 END) AS InstallRefurbPanelQuantity,
                        SUM(CASE WHEN CallBillingItems.BillingItemID IN (37, 38, 39, 40) THEN Quantity ELSE 0 END) AS NewMetersQuantity,
                        SUM(CASE WHEN CallBillingItems.BillingItemID IN (35,36) THEN Quantity ELSE 0 END) AS RefurbMetersQuantity,
                        SUM(CASE WHEN CallBillingItems.BillingItemID IN (24) THEN Quantity ELSE 0 END) AS Socketinstalled,
                        SUM(CASE WHEN CallBillingItems.BillingItemID IN (25) THEN Quantity ELSE 0 END) AS Transfersocket,
                        SUM(CASE WHEN CallBillingItems.BillingItemID IN (26,27) THEN Quantity ELSE 0 END) AS ProvidedCleanSecure,
                        SUM(CASE WHEN CallBillingItems.BillingItemID IN (47) THEN Quantity ELSE 0 END) AS CabledBarCellar,
                        SUM(CASE WHEN CallBillingItems.BillingItemID IN (48) THEN Quantity ELSE 0 END) AS BarsCabled,
                        SUM(CASE WHEN CallBillingItems.BillingItemID IN (49) THEN Quantity ELSE 0 END) AS Clearedglasses,
                        SUM(CASE WHEN CallBillingItems.BillingItemID IN (63) THEN Quantity ELSE 0 END) AS AmbientSensors,
                        SUM(CASE WHEN CallBillingItems.BillingItemID IN (65) THEN Quantity ELSE 0 END) AS RecircMeters,
                        SUM(LabourMinutes) AS EstimatedLabourMinutes,
                        SUM(CASE WHEN CallBillingItems.BillingItemID IN (94) THEN Quantity ELSE 0 END) AS LaggedLines
      FROM CallBillingItems
      GROUP BY CallID
) AS CallQuantities ON CallQuantities.CallID = Calls.[ID]

WHERE      (dbo.Calls.ClosedOn IS NOT NULL) AND (dbo.Calls.AbortReasonID <>3) AND DATEDIFF(MINUTE, Calls.VisitStartedOn, Calls.VisitEndedOn)  >0 AND (EngineerJobs.JobDate >= @From) AND (EngineerJobs.JobDate <= @To) OR
                      (EngineerJobs.JobDate >= @From) AND (@To IS NULL) OR
                      (EngineerJobs.JobDate <= @To) AND (@From IS NULL) OR
                      (@To IS NULL) AND (@From IS NULL)
ORDER BY Engineer,VisitEndedOn

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_EngineerWork] TO PUBLIC
    AS [dbo];

