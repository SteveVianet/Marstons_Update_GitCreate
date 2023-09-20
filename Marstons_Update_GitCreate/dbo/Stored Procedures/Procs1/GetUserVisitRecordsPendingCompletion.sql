CREATE PROCEDURE [dbo].[GetUserVisitRecordsPendingCompletion]

	@UserID AS INT

AS

SET NOCOUNT ON

DECLARE @AllSites INT

SELECT @AllSites = AllSitesVisible FROM UserTypes
JOIN Users ON UserType = UserTypes.ID
WHERE Users.ID = @UserID


DECLARE @DamagesStatus AS INT
SET @DamagesStatus = 0

SELECT	[ID],
		CAMID,
		FormSaved,
		CustomerID,
		EDISID,
		VisitDate,
		VisitTime,
		JointVisit,
		VisitReasonID,
		AccessDetailsID,
		MetOnSiteID,
		OtherMeetingLocation,
		PersonMet,
		CompletedChecksID,
		VerificationID,
		TamperingID,
		TamperingEvidenceID,
		ReportFrom,
		ReportTo,
		ReportDetails,
		TotalStock,
		AdditionalDetails,
		FurtherDiscussion,
		AdmissionID,
		AdmissionMadeByID,
		AdmissionMadeByPerson,
		AdmissionReasonID,
		AdmissionForID,
		UTLLOU,
		SuggestedDamagesValue,
		DamagesObtained,
		DamagesObtainedValue,
		DamagesExplaination,
		VisitOutcomeID,
		FurtherActionID,
		FurtherAction,
		BDMID,
		BDMCommentDate,
		BDMComment ,
		Actioned,
		Injunction,
		BDMUTLLOU,
		BDMDamagesIssued,
		BDMDamagesIssuedValue,
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
		PhysicalEvidenceOfBuyingOut,
		ComplianceAudit
FROM dbo.VisitRecords 
WHERE ((CustomerID > 0 AND (FurtherActionID = 2 OR FurtherActionID = 3) AND (Actioned = 0))
	OR (CustomerID = 0 AND VerifiedByVRS = 1 AND (CompletedByCustomer = 0 OR CompletedByCustomer IS NULL)))
AND (@AllSites = 1 OR EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID))
AND Deleted = 0

ORDER BY VisitDate, VisitTime

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetUserVisitRecordsPendingCompletion] TO PUBLIC
    AS [dbo];

