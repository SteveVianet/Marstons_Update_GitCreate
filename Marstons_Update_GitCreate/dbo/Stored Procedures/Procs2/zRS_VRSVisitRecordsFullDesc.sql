CREATE PROCEDURE [dbo].[zRS_VRSVisitRecordsFullDesc]

AS

SET NOCOUNT ON

SELECT 
         RMUsers.UserName                                  AS RM
        ,BDMUsers.UserName                                 AS BDM   
 ,SiteID 
 ,Sites.Name
 ,Sites.Address3
 ,VisitRecords.ID
 ,CAMID
 ,Users.UserName
 ,FormSaved
 ,CustomerID
 ,Configuration.PropertyValue  AS Customer
 ,VisitRecords.EDISID
 ,PubcoCalendars.Period
 ,VisitDate
 ,CAST(VisitTime AS TIME) AS VisitTime
 ,JointVisit
 ,VisitReasonID
 ,VRSReasonForVisit.Description AS VisitReason
 ,AccessDetailsID
 ,VRSAccessDetails.Description AS Access
 ,MetOnSiteID
 ,VRSMetOnSite.Description AS MetOnSite
 ,OtherMeetingLocation
 ,PersonMet
 ,VerballyAgressive
 ,PhysicallyAgressive
 ,CompletedChecksID
 ,VRSCompletedChecks.Description AS Checks
 ,VerificationID
 ,VRSVerification.Description AS Verification
 ,TamperingID
 ,VRSTampering.Description AS Tampering
 ,ReportFrom
 ,ReportTo
 ,ReportDetails
 ,LastDelivery
 ,NextDelivery
 ,TotalStock
 ,StockAgreedByID
 ,VRSStockAgreed.Description AS StockAgreed
 ,AdditionalDetails
 ,FurtherDiscussion
 ,AdmissionID
 ,VRSAdmission.Description AS Admission
 ,AdmissionMadeByID
 ,VRSAdmissionMadeBy.Description AS MadeBy
 ,AdmissionReasonID
 ,VRSAdmissionReason.Description AS AdmissionReason
 ,AdmissionForID
 ,VRSAdmissionFor.Description AS AdmissionFor
 ,UTLLOU
 ,SuggestedDamagesValue AS OLDSuggested
 ,SuggestedDamages.TotalSuggestedVolume AS NEWSuggested
 ,DamagesObtained
 ,DamagesObtainedValue
 ,DamagesExplaination
 ,VisitOutcomeID
 ,VRSVisitOutcome.Description AS VisitOutcome
 ,SpecificOutcomeID
 ,VRSSpecificOutcome.Description AS SpecificOutcome
 ,FurtherActionID
 ,VRSFurtherAction.Description AS FurtherAction
 ,FurtherAction AS FurtherActionComments
 ,VisitRecords.BDMID
 ,BDMCommentDate
 ,VisitRecords.BDMComment
 ,Actioned
 ,Injunction
 ,BDMUTLLOU
 ,BDMDamagesIssued
 ,BDMDamagesIssuedValue
 ,DateSubmitted
 ,VerifiedByVRS
 ,VerifiedDate
 ,VisitRecords.Deleted

 
FROM VisitRecords

JOIN Configuration ON Configuration.PropertyName = 'Company Name'
JOIN Users ON Users.ID = VisitRecords.CAMID
JOIN Sites ON Sites.EDISID = VisitRecords.EDISID

LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSAccessDetails AS VRSAccessDetails ON VRSAccessDetails.ID = VisitRecords.AccessDetailsID
LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSActionTaken AS VRSActionTaken ON VRSActionTaken.ID = VisitRecords.BDMActionTaken
LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSAdmission AS VRSAdmission ON VRSAdmission.ID = VisitRecords.AdmissionID
LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSAdmissionFor AS VRSAdmissionFor ON VRSAdmissionFor.ID = VisitRecords.AdmissionForID
LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSAdmissionReason AS VRSAdmissionReason ON VRSAdmissionReason.ID = VisitRecords.AdmissionReasonID
LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSCompletedChecks AS VRSCompletedChecks ON VRSCompletedChecks.ID = VisitRecords.CompletedChecksID
LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSFurtherAction AS VRSFurtherAction ON VRSFurtherAction.ID = VisitRecords.FurtherActionID
LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSMetOnSite AS VRSMetOnSite ON VRSMetOnSite.ID = VisitRecords.MetOnSiteID
LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSReasonForVisit AS VRSReasonForVisit ON VRSReasonForVisit.ID = VisitRecords.VisitReasonID
LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSSpecificOutcome AS VRSSpecificOutcome ON VRSSpecificOutcome.ID = VisitRecords.SpecificOutcomeID
LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSTampering AS VRSTampering ON VRSTampering.ID = VisitRecords.TamperingID
LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSTamperingEvidence AS VRSTamperingEvidence ON VRSTamperingEvidence.ID = VisitRecords.TamperingEvidenceID
LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSVerification AS VRSVerification ON VRSVerification.ID = VisitRecords.VerificationID
LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSVisitOutcome AS VRSVisitOutcome ON VRSVisitOutcome.ID = VisitRecords.VisitOutcomeID

LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSMetOnSite AS VRSStockAgreed ON VRSStockAgreed.ID = VisitRecords.StockAgreedByID
LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSMetOnSite AS VRSAdmissionMadeBy ON VRSAdmissionMadeBy.ID = VisitRecords.AdmissionMadeByID



LEFT JOIN (
 SELECT  VisitRecordID, 
 SUM(Damages) AS TotalSuggestedVolume
 FROM VisitDamages
 GROUP BY VisitRecordID
    ) AS SuggestedDamages ON SuggestedDamages.VisitRecordID = VisitRecords.ID


LEFT JOIN
 (
 SELECT      UserSites.EDISID
     ,MAX(CASE WHEN Users.UserType = 1   THEN UserID ELSE 0 END) AS RMID
 ,MAX(CASE WHEN Users.UserType = 2   THEN UserID ELSE 0 END) AS BDMID
 
 FROM UserSites
 
 JOIN Users ON Users.ID = UserSites.UserID
 WHERE Users.UserType IN (1,2)
 
 GROUP BY UserSites.EDISID
 
 )   AS UsersTEMP ON UsersTEMP.EDISID = Sites.EDISID

LEFT JOIN  Users AS RMUsers  ON RMUsers.ID     = UsersTEMP.RMID
LEFT JOIN  Users AS BDMUsers ON BDMUsers.ID    = UsersTEMP.BDMID

JOIN PubcoCalendars ON CAST(VisitRecords.VisitDate AS DATE) BETWEEN  PubcoCalendars.FromWC AND DATEADD(DAY,6,PubcoCalendars.ToWC)

WHERE

YEAR(VisitRecords.VisitDate) >= YEAR(GetDate())-2

ORDER BY VisitDate, VisitTime
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_VRSVisitRecordsFullDesc] TO PUBLIC
    AS [dbo];

