CREATE PROCEDURE [dbo].[GetVisitRecord]
(
	@VisitID	INT,
	@UserID	INT = NULL
)
AS



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
		0 AS DamagesStatus,
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
WHERE (ID = @VisitID) 
AND (CAMID = @UserID OR @UserID IS NULL)
AND Deleted = 0