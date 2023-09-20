CREATE FUNCTION [dbo].[fnGetEscalationRecipientType]
(
	@VisitID 	INTEGER
)

RETURNS INT

AS

BEGIN
	DECLARE @UserType 	INTEGER
	SET @UserType = 0
	
	DECLARE @MetOnSiteEscalation 	INTEGER
	DECLARE @AccessDetailsEscalation 	INTEGER
	DECLARE @CompletedChecksEscalation 	INTEGER
	DECLARE @VerificationEscalation 	INTEGER
	DECLARE @CalChecksEscalation 	INTEGER
	DECLARE @TamperingEscalation 	INTEGER
	DECLARE @TamperingEvidenceEscalation 	INTEGER
	DECLARE @VisitReasonEscalation 	INTEGER
	DECLARE @AdmissionEscalation 	INTEGER
	DECLARE @AdmissionByEscalation 	INTEGER
	DECLARE @AdmissionReasonEscalation 	INTEGER
	DECLARE @AdmissionForEscalation 	INTEGER
	DECLARE @FurtherActionEscalation 	INTEGER
	DECLARE @VisitOutcomeEscalation 	INTEGER
	DECLARE @SpecificOutcomeEscalation 	INTEGER
	
	SELECT 
		@MetOnSiteEscalation = ISNULL(VRSMetOnSite.EscalateToUserType, 0),
		@AccessDetailsEscalation = ISNULL(VRSAccessDetail.EscalateToUserType, 0),
		@CompletedChecksEscalation = ISNULL(VRSCompletedChecks.EscalateToUserType, 0),
		@VerificationEscalation = ISNULL(VRSVerification.EscalateToUserType, 0),
		@CalChecksEscalation = ISNULL(VRSCalChecksCompleted.EscalateToUserType, 0),
		@TamperingEscalation = ISNULL(VRSTampering.EscalateToUserType, 0),
		@TamperingEvidenceEscalation = ISNULL(VRSTamperingEvidence.EscalateToUserType, 0),
		@VisitReasonEscalation = ISNULL(VRSReasonForVisit.EscalateToUserType, 0),
		@AdmissionEscalation = ISNULL(VRSAdmission.EscalateToUserType, 0),
		@AdmissionByEscalation = ISNULL(VRSAdmissionBy.EscalateToUserType, 0),
		@AdmissionReasonEscalation = ISNULL(VRSAdmissionReason.EscalateToUserType, 0),
		@AdmissionForEscalation = ISNULL(VRSAdmissionFor.EscalateToUserType, 0),
		@FurtherActionEscalation = ISNULL(VRSFurtherAction.EscalateToUserType, 0),
		@VisitOutcomeEscalation = ISNULL(VRSVisitOutcome.EscalateToUserType, 0),
		@SpecificOutcomeEscalation = ISNULL(VRSSpecificOutcome.EscalateToUserType, 0)
	FROM VisitRecords
	JOIN VRSJobTitle AS VRSMetOnSite ON VRSMetOnSite.JobTitleID = VisitRecords.MetOnSiteID
	JOIN VRSAccessDetail ON VRSAccessDetail.AccessDetailID = VisitRecords.AccessDetailsID
	JOIN VRSCompletedChecks ON VRSCompletedChecks.CompletedChecksID = VisitRecords.CompletedChecksID
	JOIN VRSVerification ON VRSVerification.VerificationID = VisitRecords.VerificationID
	JOIN VRSCalChecksCompleted ON VRSCalChecksCompleted.CalChecksCompletedID = VisitRecords.CalChecksCompletedID
	JOIN VRSTampering ON VRSTampering.TamperingID = VisitRecords.TamperingID
	JOIN VRSTamperingEvidence ON VRSTamperingEvidence.TamperingEvidenceID = VisitRecords.TamperingEvidenceID
	JOIN VRSReasonForVisit ON VRSReasonForVisit.ReasonID = VisitRecords.VisitReasonID
	JOIN VRSAdmission ON VRSAdmission.AdmissionID = VisitRecords.AdmissionID
	JOIN VRSJobTitle AS VRSAdmissionBy ON VRSAdmissionBy.JobTitleID = VisitRecords.AdmissionMadeByID
	JOIN VRSAdmissionReason ON VRSAdmissionReason.AdmissionReasonID = VisitRecords.AdmissionReasonID
	JOIN VRSAdmissionFor ON VRSAdmissionFor.AdmissionForID = VisitRecords.AdmissionForID
	JOIN VRSFurtherAction ON VRSFurtherAction.FurtherActionID = VisitRecords.FurtherActionID
	JOIN VRSVisitOutcome ON VRSVisitOutcome.VisitOutcomeID = VisitRecords.VisitOutcomeID
	JOIN VRSSpecificOutcome ON VRSSpecificOutcome.SpecificOutcomeID = VisitRecords.SpecificOutcomeID
	WHERE VisitRecords.ID = @VisitID

	
	--UserTypes to check for
	--1: RM
	--2: BDM
	
	IF @MetOnSiteEscalation > 0 AND @UserType <> 1
	BEGIN
		 SET @UserType = @MetOnSiteEscalation
	END
	
	IF @AccessDetailsEscalation > 0 AND @UserType <> 1
	BEGIN
		 SET @UserType = @AccessDetailsEscalation
	END
	
	IF @CompletedChecksEscalation > 0 AND @UserType <> 1
	BEGIN
		 SET @UserType = @CompletedChecksEscalation
	END
	
	IF @VerificationEscalation > 0 AND @UserType <> 1
	BEGIN
		 SET @UserType = @VerificationEscalation
	END
	
	IF @CalChecksEscalation > 0 AND @UserType <> 1
	BEGIN
		 SET @UserType = @CalChecksEscalation
	END
	
	IF @TamperingEscalation > 0 AND @UserType <> 1
	BEGIN
		 SET @UserType = @TamperingEscalation
	END
	
	IF @TamperingEvidenceEscalation > 0 AND @UserType <> 1
	BEGIN
		 SET @UserType = @TamperingEvidenceEscalation
	END
	
	IF @VisitReasonEscalation > 0 AND @UserType <> 1
	BEGIN
		 SET @UserType = @VisitReasonEscalation
	END
	
	IF @AdmissionEscalation > 0 AND @UserType <> 1
	BEGIN
		 SET @UserType = @AdmissionEscalation
	END
	
	IF @AdmissionByEscalation > 0 AND @UserType <> 1
	BEGIN
		 SET @UserType = @AdmissionByEscalation
	END
	
	IF @AdmissionReasonEscalation > 0 AND @UserType <> 1
	BEGIN
		 SET @UserType = @AdmissionReasonEscalation
	END
	
	IF @AdmissionForEscalation > 0 AND @UserType <> 1
	BEGIN
		 SET @UserType = @AdmissionForEscalation
	END
	
	IF @FurtherActionEscalation > 0 AND @UserType <> 1
	BEGIN
		 SET @UserType = @FurtherActionEscalation
	END
	
	IF @VisitOutcomeEscalation > 0 AND @UserType <> 1
	BEGIN
		 SET @UserType = @VisitOutcomeEscalation
	END
	
	IF @SpecificOutcomeEscalation > 0 AND @UserType <> 1
	BEGIN
		 SET @UserType = @SpecificOutcomeEscalation
	END
	
	
	
	
	
	RETURN @UserType

END





GO
GRANT EXECUTE
    ON OBJECT::[dbo].[fnGetEscalationRecipientType] TO PUBLIC
    AS [dbo];

