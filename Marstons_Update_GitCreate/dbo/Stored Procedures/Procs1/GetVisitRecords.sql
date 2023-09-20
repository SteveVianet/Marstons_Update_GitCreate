CREATE PROCEDURE [dbo].[GetVisitRecords]
(
	@EDISID	INT = NULL,
	@Actioned	BIT = NULL,
	@Submitted	BIT = NULL,
	@Verified	BIT = NULL,
	@Completed	BIT = NULL
)
AS

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
WHERE (EDISID = @EDISID OR @EDISID IS NULL) 
AND (Actioned = @Actioned OR @Actioned IS NULL)
--AND (@Submitted IS NOT NULL OR (CustomerID > 0 OR VerifiedByVRS = 1))
AND (ClosedByCAM = @Submitted OR @Submitted IS NULL)
AND (VerifiedByVRS= @Verified OR @Verified IS NULL OR (VerifiedByVRS IS NULL AND @Verified = 0))
AND (CompletedByCustomer= @Completed OR @Completed IS NULL OR (CompletedByCustomer IS NULL AND @Completed = 0))
AND Deleted = 0
ORDER BY VisitDate DESC, VisitTime DESC
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecords] TO PUBLIC
    AS [dbo];

