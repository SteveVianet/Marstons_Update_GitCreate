CREATE PROCEDURE [dbo].[InsertVisitRecord]
(
	@CAMID 					INT,
	@FormSaved				DATETIME,
	@CustomerID				INT = NULL,
	@EDISID					INT,
	@VisitDate				DATETIME,
	@VisitTime				DATETIME,
	@JointVisit				NVARCHAR(255),
	@VisitReasonID			INT,
	@AccessDetailsID		INT,
	@MetOnSiteID			INT,
	@OtherMeetingLocation	VARCHAR(255) = NULL,
	@PersonMet				VARCHAR(50),
	@CompletedChecksID		INT = NULL,
	@VerificationID			INT = NULL,
	@TamperingID			INT = NULL,
	@TamperingEvidenceID	INT = NULL,
	@ReportFrom				DATETIME = NULL,
	@ReportTo				DATETIME = NULL,
	@ReportDetails			TEXT = NULL,
	@TotalStock				TEXT = NULL,
	@AdditionalDetails		TEXT = NULL,
	@FurtherDiscussion		TEXT = NULL,
	@AdmissionID			INT,
	@AdmissionMadeByID		INT,
	@AdmissionMadeByPerson	VARCHAR(50) = NULL,
	@AdmissionReasonID		INT,
	@AdmissionForID			INT,
	@UTLLOU					BIT = NULL,
	@SuggestedDamagesValue	MONEY = NULL,
	@DamagesObtained		BIT = NULL,
	@DamagesObtainedValue	MONEY = NULL,
	@DamagesExplaination	TEXT = NULL,
	@VisitOutcomeID			INT,
	@FurtherActionID		INT,
	@FurtherAction			VARCHAR(1024),
	@BDMID					INT = NULL,
	@BDMCommentDate			DATETIME = NULL,
	@BDMComment				TEXT = NULL,
	@Actioned				BIT,
	@Injunction				BIT,
	@BDMUTLLOU				BIT,
	@BDMDamagesIssued		BIT,
	@BDMDamagesIssuedValue	MONEY,
	@SpecificOutcomeID		INT = NULL,
	@ClosedByCAM			BIT = NULL,
	@DamagesStatus			INT = NULL,
	@VerballyAgressive		BIT = NULL,
	@PhysicallyAgressive	BIT = NULL,
	@CalChecksCompletedID	INT = NULL,
	@LastDelivery			DATETIME = NULL,
	@NextDelivery			DATETIME = NULL,
	@StockAgreedByID		INT = NULL,
	@DateSubmitted			DATETIME = NULL,
	@VerifiedByVRS			BIT = NULL,
	@VerifiedDate			DATETIME = NULL,
	@CompletedByCustomer	BIT = NULL,
	@CompletedDate			DATETIME = NULL,
	@BDMActionTaken			INT = NULL,
	@BDMPartialReason		TEXT = NULL,
	@DraughtDamagesTotalValue			MONEY = NULL,
	@DraughtDamagesTotalAgreedValue		MONEY = NULL,
	@ResendEmailOn			DATETIME = NULL,
	@Deleted				BIT = 1,
	@NewID					INT OUT	
)

AS

INSERT INTO VisitRecords
	(CAMID, FormSaved, CustomerID, EDISID, VisitDate, VisitTime, JointVisit, VisitReasonID, AccessDetailsID, MetOnSiteID, OtherMeetingLocation, PersonMet, CompletedChecksID, VerificationID, TamperingID, TamperingEvidenceID, ReportFrom, ReportTo, ReportDetails, TotalStock, AdditionalDetails, FurtherDiscussion, AdmissionID, AdmissionMadeByID, AdmissionMadeByPerson, AdmissionReasonID, AdmissionForID, UTLLOU, SuggestedDamagesValue, DamagesObtained, DamagesObtainedValue, DamagesExplaination, VisitOutcomeID, FurtherActionID, FurtherAction, BDMID, BDMCommentDate, BDMComment, Actioned, Injunction, BDMUTLLOU, BDMDamagesIssued, BDMDamagesIssuedValue, SpecificOutcomeID, ClosedByCAM, DamagesStatus, VerballyAgressive, PhysicallyAgressive, CalChecksCompletedID, LastDelivery, NextDelivery, StockAgreedByID, DateSubmitted, VerifiedByVRS, VerifiedDate, CompletedByCustomer, CompletedDate, BDMActionTaken, BDMPartialReason, DraughtDamagesTotalValue, DraughtDamagesTotalAgreedValue, ResendEmailOn, Deleted)
VALUES
	(@CAMID, @FormSaved, @CustomerID, @EDISID, @VisitDate, @VisitTime, @JointVisit, @VisitReasonID, @AccessDetailsID, @MetOnSiteID, @OtherMeetingLocation, @PersonMet, @CompletedChecksID, @VerificationID, @TamperingID, @TamperingEvidenceID, @ReportFrom, @ReportTo, @ReportDetails, @TotalStock, @AdditionalDetails, @FurtherDiscussion, @AdmissionID, @AdmissionMadeByID, @AdmissionMadeByPerson, @AdmissionReasonID, @AdmissionForID, @UTLLOU, @SuggestedDamagesValue, @DamagesObtained, @DamagesObtainedValue, @DamagesExplaination, @VisitOutcomeID, @FurtherActionID, @FurtherAction, @BDMID, @BDMCommentDate, @BDMComment, @Actioned, @Injunction, @BDMUTLLOU, @BDMDamagesIssued, @BDMDamagesIssuedValue, @SpecificOutcomeID, @ClosedByCAM, @DamagesStatus, @VerballyAgressive, @PhysicallyAgressive, @CalChecksCompletedID, @LastDelivery, @NextDelivery, @StockAgreedByID, @DateSubmitted, @VerifiedByVRS, @VerifiedDate, @CompletedByCustomer, @CompletedDate, @BDMActionTaken, @BDMPartialReason, @DraughtDamagesTotalValue, @DraughtDamagesTotalAgreedValue, @ResendEmailOn, @Deleted)

SELECT @NewID = @@IDENTITY

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[InsertVisitRecord] TO PUBLIC
    AS [dbo];

