CREATE PROCEDURE [dbo].[GetWebSiteVisitRecords]
(
	@EDISID	INT = NULL,
	@Actioned	BIT = NULL,
	@Submitted	BIT = NULL,
	@Verified	BIT = NULL,
	@Completed	BIT = NULL
)
AS

SET NOCOUNT ON

CREATE TABLE #VRSCalChecksCompleted ([ID] INT NOT NULL, [Description] VARCHAR(100) NOT NULL)
CREATE TABLE #VRSAccessDetails ([ID] INT NOT NULL, [Description] VARCHAR(100) NOT NULL)
CREATE TABLE #VRSMetOnSite ([ID] INT NOT NULL, [Description] VARCHAR(100) NOT NULL)
CREATE TABLE #VRSCompletedChecks ([ID] INT NOT NULL, [Description] VARCHAR(100) NOT NULL)
CREATE TABLE #VRSVerification ([ID] INT NOT NULL, [Description] VARCHAR(100) NOT NULL)
CREATE TABLE #VRSTampering ([ID] INT NOT NULL, [Description] VARCHAR(100) NOT NULL)
CREATE TABLE #VRSTamperingEvidence ([ID] INT NOT NULL, [Description] VARCHAR(100) NOT NULL)
CREATE TABLE #VRSAdmission ([ID] INT NOT NULL, [Description] VARCHAR(100) NOT NULL)
CREATE TABLE #VRSAdmissionReason ([ID] INT NOT NULL, [Description] VARCHAR(100) NOT NULL)
CREATE TABLE #VRSAdmissionFor ([ID] INT NOT NULL, [Description] VARCHAR(100) NOT NULL)
CREATE TABLE #VRSFurtherAction ([ID] INT NOT NULL, [Description] VARCHAR(100) NOT NULL)
CREATE TABLE #VRSReasonForVisit([ID] INT NOT NULL, [Description] VARCHAR(100) NOT NULL)
CREATE TABLE #VRSVisitOutcome([ID] INT NOT NULL, [Description] VARCHAR(100) NOT NULL)
CREATE TABLE #VRSActionTaken([ID] INT NOT NULL, [Description] VARCHAR(100) NOT NULL)

DECLARE @DamagesStatus AS INT
SET @DamagesStatus = 0

INSERT INTO #VRSCalChecksCompleted
([ID], [Description])
EXEC [SQL1\SQL1].ServiceLogger.dbo.GetVRSCalChecksCompleted

INSERT INTO #VRSAccessDetails
([ID], [Description])
EXEC [SQL1\SQL1].ServiceLogger.dbo.GetVRSAccessDetails

INSERT INTO #VRSMetOnSite
([ID], [Description])
EXEC [SQL1\SQL1].ServiceLogger.dbo.GetVRSMetOnSite

INSERT INTO #VRSCompletedChecks
([ID], [Description])
EXEC [SQL1\SQL1].ServiceLogger.dbo.GetVRSCompletedChecks

INSERT INTO #VRSVerification
([ID], [Description])
EXEC [SQL1\SQL1].ServiceLogger.dbo.GetVRSVerification

INSERT INTO #VRSTampering
([ID], [Description])
EXEC [SQL1\SQL1].ServiceLogger.dbo.GetVRSTampering

INSERT INTO #VRSTamperingEvidence
([ID], [Description])
EXEC [SQL1\SQL1].ServiceLogger.dbo.GetVRSTamperingEvidence

INSERT INTO #VRSAdmission
([ID], [Description])
EXEC [SQL1\SQL1].ServiceLogger.dbo.GetVRSAdmission

INSERT INTO #VRSAdmissionReason
([ID], [Description])
EXEC [SQL1\SQL1].ServiceLogger.dbo.GetVRSAdmissionReason

INSERT INTO #VRSAdmissionFor
([ID], [Description])
EXEC [SQL1\SQL1].ServiceLogger.dbo.GetVRSAdmissionFor

INSERT INTO #VRSFurtherAction
([ID], [Description])
EXEC [SQL1\SQL1].ServiceLogger.dbo.GetVRSFurtherAction

INSERT INTO #VRSReasonForVisit
([ID], [Description])
EXEC [SQL1\SQL1].ServiceLogger.dbo.GetVRSReasonForVisit

INSERT INTO #VRSVisitOutcome
([ID], [Description])
EXEC [SQL1\SQL1].ServiceLogger.dbo.GetVRSVisitOutcome

INSERT INTO #VRSActionTaken
([ID], [Description])
EXEC [SQL1\SQL1].ServiceLogger.dbo.GetVRSActionsTaken

SELECT	VisitRecords.[ID],
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
		ISNULL(BDMComment, '') AS BDMComment,
		Actioned,
		Injunction,
		BDMUTLLOU,
		BDMDamagesIssued,
		BDMDamagesIssuedValue,
		@DamagesStatus AS DamagesStatus,
		ClosedByCAM,
		ISNULL(PhysicallyAgressive, 0) AS PhysicallyAgressive, 
		ISNULL(VerballyAgressive, 0) AS VerballyAgressive, 
		CalChecksCompletedID, 
		LastDelivery, 
		NextDelivery, 
		StockAgreedByID, 
		SpecificOutcomeID,
		DateSubmitted,
		ISNULL(VerifiedByVRS, 0) AS VerifiedByVRS,
		VerifiedDate,
		ISNULL(CompletedByCustomer, 0) AS CompletedByCustomer,
		ISNULL(CompletedDate, 0) AS CompletedDate,
		BDMActionTaken,
		BDMPartialReason,
		DraughtDamagesTotalValue,
		DraughtDamagesTotalAgreedValue,
		ISNULL(VRSCalChecksCompleted.[Description], '') AS CalChecksCompletedText,
		ISNULL(VRSAccessDetails.[Description], '') AS AccessDetailsText,
		ISNULL(VRSMetOnSite.[Description], '') AS MetOnSiteText,
		ISNULL(VRSCompletedChecks.[Description], '') AS CompletedChecksText,
		ISNULL(VRSVerification.[Description], '') AS VerificationText,
		ISNULL(VRSTampering.[Description], '') AS TamperingText,
		ISNULL(VRSTamperingEvidence.[Description], '') AS TamperingEvidenceText,
		ISNULL(VRSAdmission.[Description], '') AS AdmissionText,
		ISNULL(VRSAdmissionMadeBy.[Description], '') AS AdmissionMadeByText,
		ISNULL(VRSAdmissionReason.[Description], '') AS AdmissionReasonText,
		ISNULL(VRSAdmissionFor.[Description], '') AS AdmissionForText,
		ISNULL(VRSFurtherAction.[Description], '') AS FurtherActionText,
		ISNULL(VRSReasonForVisit.[Description], '') AS ReasonForVisitText,
		ISNULL(VRSVisitOutcome.[Description], '') AS VisitOutcomeText,
		ISNULL(VRSActionTaken.[Description], '') AS ActionTakenText,
		ISNULL(PhysicalEvidenceOfBuyingOut, 0) AS PhysicalEvidenceOfBuyingOut,
		ISNULL(ComplianceAudit, 0) AS ComplianceAudit,
		ISNULL(Users.UserName, '') AS CAMName,
		ISNULL(Users.EMail, '') AS CAMEmailAddress,
		ISNULL(Users.PhoneNumber, '') AS CAMPhoneNumber
FROM dbo.VisitRecords
LEFT JOIN #VRSCalChecksCompleted AS VRSCalChecksCompleted ON VRSCalChecksCompleted.[ID] = VisitRecords.CalChecksCompletedID
LEFT JOIN #VRSAccessDetails AS VRSAccessDetails ON VRSAccessDetails.[ID] = VisitRecords.AccessDetailsID
LEFT JOIN #VRSMetOnSite AS VRSMetOnSite ON VRSMetOnSite.[ID] = VisitRecords.MetOnSiteID
LEFT JOIN #VRSCompletedChecks AS VRSCompletedChecks ON VRSCompletedChecks.[ID] = VisitRecords.CompletedChecksID
LEFT JOIN #VRSVerification AS VRSVerification ON VRSVerification.[ID] = VisitRecords.VerificationID
LEFT JOIN #VRSTampering AS VRSTampering ON VRSTampering.[ID] = VisitRecords.TamperingID
LEFT JOIN #VRSTamperingEvidence AS VRSTamperingEvidence ON VRSTamperingEvidence.[ID] = VisitRecords.TamperingEvidenceID
LEFT JOIN #VRSAdmission AS VRSAdmission ON VRSAdmission.[ID] = VisitRecords.AdmissionID
LEFT JOIN #VRSMetOnSite AS VRSAdmissionMadeBy ON VRSAdmissionMadeBy.[ID] = VisitRecords.AdmissionMadeByID
LEFT JOIN #VRSAdmissionReason AS VRSAdmissionReason ON VRSAdmissionReason.[ID] = VisitRecords.AdmissionReasonID
LEFT JOIN #VRSAdmissionFor AS VRSAdmissionFor ON VRSAdmissionFor.[ID] = VisitRecords.AdmissionForID
LEFT JOIN #VRSFurtherAction AS VRSFurtherAction ON VRSFurtherAction.[ID] = VisitRecords.FurtherActionID
LEFT JOIN #VRSReasonForVisit AS VRSReasonForVisit ON VRSReasonForVisit.[ID] = VisitRecords.VisitReasonID
LEFT JOIN #VRSVisitOutcome AS VRSVisitOutcome ON VRSVisitOutcome.[ID] = VisitRecords.VisitOutcomeID
LEFT JOIN #VRSActionTaken AS VRSActionTaken ON VRSActionTaken.[ID] = VisitRecords.BDMActionTaken
LEFT JOIN (SELECT ID, UserName, EMail, PhoneNumber FROM Users WHERE UserType = 9) AS Users ON VisitRecords.CAMID = Users.ID
WHERE (EDISID = @EDISID OR @EDISID IS NULL) 
AND (Actioned = @Actioned OR @Actioned IS NULL)
--AND (@Submitted IS NOT NULL OR (CustomerID > 0 OR VerifiedByVRS = 1))
AND (ClosedByCAM = @Submitted OR @Submitted IS NULL)
AND (VerifiedByVRS= @Verified OR @Verified IS NULL OR (VerifiedByVRS IS NULL AND @Verified = 0))
AND (CompletedByCustomer= @Completed OR @Completed IS NULL OR (CompletedByCustomer IS NULL AND @Completed = 0))
AND VisitRecords.Deleted = 0
ORDER BY VisitDate DESC, VisitTime DESC

DROP TABLE #VRSCalChecksCompleted
DROP TABLE #VRSAccessDetails
DROP TABLE #VRSMetOnSite
DROP TABLE #VRSCompletedChecks
DROP TABLE #VRSVerification
DROP TABLE #VRSTampering
DROP TABLE #VRSTamperingEvidence
DROP TABLE #VRSAdmission
DROP TABLE #VRSAdmissionReason
DROP TABLE #VRSAdmissionFor
DROP TABLE #VRSFurtherAction
DROP TABLE #VRSReasonForVisit
DROP TABLE #VRSVisitOutcome
DROP TABLE #VRSActionTaken
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteVisitRecords] TO PUBLIC
    AS [dbo];

