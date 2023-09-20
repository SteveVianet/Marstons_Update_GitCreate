CREATE PROCEDURE [dbo].[GetUsersVisitRecords]
(
	@UserID		INT = NULL,
	@ActionedVisits	BIT = NULL
)

AS

SET NOCOUNT ON

DECLARE @DamagesStatus AS INT
SET @DamagesStatus = 0

DECLARE @UserType AS INT
SET @UserType = (SELECT UserType FROM Users WHERE ID = @UserID)


SELECT	[ID],
		VisitRecords.CAMID,
		VisitRecords.FormSaved,
		VisitRecords.CustomerID,
		VisitRecords.EDISID,
		VisitRecords.VisitDate,
		VisitRecords.VisitTime,
		VisitRecords.JointVisit,
		VisitRecords.VisitReasonID,
		VisitRecords.AccessDetailsID,
		VisitRecords.MetOnSiteID,
		VisitRecords.OtherMeetingLocation,
		VisitRecords.PersonMet,
		VisitRecords.CompletedChecksID,
		VisitRecords.VerificationID,
		VisitRecords.TamperingID,
		VisitRecords.TamperingEvidenceID,
		VisitRecords.ReportFrom,
		VisitRecords.ReportTo,
		VisitRecords.ReportDetails,
		VisitRecords.TotalStock,
		VisitRecords.AdditionalDetails,
		VisitRecords.FurtherDiscussion,
		VisitRecords.AdmissionID,
		VisitRecords.AdmissionMadeByID,
		VisitRecords.AdmissionMadeByPerson,
		VisitRecords.AdmissionReasonID,
		VisitRecords.AdmissionForID,
		VisitRecords.UTLLOU,
		VisitRecords.SuggestedDamagesValue,
		VisitRecords.DamagesObtained,
		VisitRecords.DamagesObtainedValue,
		VisitRecords.DamagesExplaination,
		VisitRecords.VisitOutcomeID,
		VisitRecords.FurtherActionID,
		VisitRecords.FurtherAction,
		VisitRecords.BDMID,
		VisitRecords.BDMCommentDate,
		VisitRecords.BDMComment ,
		VisitRecords.Actioned,
		VisitRecords.Injunction,
		VisitRecords.BDMUTLLOU,
		VisitRecords.BDMDamagesIssued,
		VisitRecords.BDMDamagesIssuedValue,
		@DamagesStatus AS DamagesStatus,
		ClosedByCAM,
		PhysicallyAgressive, 
		VerballyAgressive, 
		CalChecksCompletedID, 
		LastDelivery, 
		NextDelivery, 
		StockAgreedByID, 
		SpecificOutcomeID,
		DateSubmitted,
		VerifiedByVRS,
		VerifiedDate,
		CompletedByCustomer,
		CompletedDate,
		BDMActionTaken,
		BDMPartialReason,
		DraughtDamagesTotalValue,
		DraughtDamagesTotalAgreedValue,
		VisitRecords.PhysicalEvidenceOfBuyingOut,
		VisitRecords.ComplianceAudit

FROM dbo.Sites
JOIN UserSites ON UserSites.EDISID = Sites.EDISID
JOIN VisitRecords ON VisitRecords.EDISID = Sites.EDISID
WHERE (UserSites.UserID =@UserID or @UserID IS Null) 
AND (VisitRecords.Actioned = @ActionedVisits OR @ActionedVisits IS NULL)
AND (VisitRecords.CustomerID > 0 OR VerifiedByVRS = 1 OR @UserType = 9  OR @UserType = 8  OR @UserType = 7) --If the note is a new style only show if Verified or user is Internal - (VRS, Account Man, Auditors)
AND VisitRecords.Deleted = 0
ORDER BY VisitRecords.Actioned ASC, Sites.Name ASC
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetUsersVisitRecords] TO PUBLIC
    AS [dbo];

