CREATE PROCEDURE [dbo].[zRS_CallCreditReport]

(  

      @From DATETIME    = NULL,

      @To   DATETIME    = NULL

)

AS

 

SET NOCOUNT ON

SELECT

Owners.Name AS Owner,

dbo.GetCallReference(Calls.ID) AS Callref

,Contracts.Description AS ContractCustomer

,Sites.Name

,Sites.TenantName

,Sites.SiteID

,Sites.Address1

,Sites.Address3

,Sites.Address4

,Sites.PostCode

,Engineers.Name As EngineersName

,CASE WHEN Calls.UseBillingItems = 1 THEN dbo.udfConcatCallReasonsSingleLine(Calls.[ID]) ELSE dbo.udfConcatCallFaults(Calls.[ID]) END AS CallOutReason

,CallCategories.Description

,[VisitEndedOn]

,DATEDIFF(MINUTE, Calls.VisitStartedOn, Calls.VisitEndedOn) AS ActualMinutesOnSite 

,[AbortReasonID]

,CCN.TotalVolume AS PintsUsedOnCall

,CCN.CreditDate AS CreditDate

,CCN.LicenseeName AS LicenseeName

,CCN.CreditDate AS DateSigned

 

FROM Calls

LEFT JOIN CallCreditNotes AS CCN ON CCN.CallID=Calls.ID

Left JOIN Sites ON Sites.EDISID = Calls.EDISID

LEFT JOIN Owners ON Owners.ID = Sites.OwnerID

LEFT JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.ContractorEngineers AS Engineers ON Engineers.ID = Calls.EngineerID

LEFT JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.CallCategories AS CallCategories ON CallCategories.ID = Calls.CallCategoryID

LEFT JOIN Contracts ON Contracts.ID = Calls.ContractID

 

WHERE AbortReasonID =0 AND CAST([VisitEndedOn] AS DATE) BETWEEN @From AND @To
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_CallCreditReport] TO PUBLIC
    AS [dbo];

