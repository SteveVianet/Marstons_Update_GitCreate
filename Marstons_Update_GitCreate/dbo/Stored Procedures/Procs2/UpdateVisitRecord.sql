CREATE PROCEDURE [dbo].[UpdateVisitRecord]
(
	@VISITID			INT,
	@CAMID 			INT,
	@FormSaved 			DateTime,
	@CustomerID			INT,
	@EDISID 			INT,
	@VisitDate 			DATETIME,
	@VisitTime 			DATETIME,
	@JointVisit			VARCHAR(255),
	@VisitReasonID			INT,
	@AccessDetailsID 		INT,
	@MetOnSiteID			INT,
	@OtherMeetingLocation 		VARCHAR(255),
	@PersonMet 			VARCHAR(50),
	@CompletedChecksID		INT,
	@VerificationID 			INT,
	@TamperingID 			INT,
	@TamperingEvidenceID 	INT,
	@ReportFrom 			DATETIME,
	@ReportTo 			DATETIME,
	@ReportDetails 			TEXT,
	@TotalStock 			TEXT,
	@AdditionalDetails 		TEXT,
	@FurtherDiscussion 		TEXT,
	@AdmissionID 			INT,
	@AdmissionMadeByID 		INT,
	@AdmissionMadeByPerson 	VARCHAR(50),
	@AdmissionReasonID		INT,
	@AdmissionForID 		INT,
	@UTLLOU 			BIT,
	@SuggestedDamagesValue 	FLOAT,
	@DamagesObtained 		BIT,
	@DamagesObtainedValue 	FLOAT,
	@DamagesExplaination 		TEXT,
	@VisitOutcomeID 		INT,
	@FurtherActionID 		INT,
	@FurtherAction 			VARCHAR(1024),
	@DamagesStatus		INT = 0,
	@ClosedByCAM			BIT = 0,
	@PhysicallyAgressive		BIT = NULL, 
	@VerballyAgressive		BIT = NULL, 
	@CalChecksCompletedID	INT = NULL, 
	@LastDelivery			DATETIME = NULL, 
	@NextDelivery			DATETIME = NULL, 
	@StockAgreedByID		INT = NULL, 
	@SpecificOutcomeID		INT = NULL,
	@DraughtDamagesTotal		SMALLMONEY = NULL,
	@DraughtDamagesAgreedTotal		SMALLMONEY = NULL,
	@PhysicalEvidenceOfBuyingOut	BIT = 0,
	@ComplianceAudit	BIT = 0
)

AS

IF @CustomerID = 0
BEGIN
	-------------------------
	-- We must keep any associated Evidence Documents up-to-date with any VisitDate changes.
	-------------------------
	--Get the current VisitDate
	DECLARE @OldVisitDate DATETIME
	SELECT @OldVisitDate = VisitDate FROM dbo.VisitRecords WHERE [ID] = @VISITID

	--Get the relevant DocumentArchive DatabaseID (*not* the same as the EDIS DatabaseID or SQL Database ID... or any other IDs...)
	DECLARE @DocumentDatabaseID INT
	DECLARE @DatabaseName VARCHAR(255)
	SELECT @DatabaseName = DB_NAME()
	EXEC [EDISSQL1\SQL1].DocumentArchive.dbo.GetDatabase @DatabaseName, @DocumentDatabaseID OUT
	SELECT @DocumentDatabaseID

	--Update any evidence with the new Visit Date
	EXEC [EDISSQL1\SQL1].DocumentArchive.dbo.[UpdateEvidenceFileDate] @DocumentDatabaseID, @OldVisitDate, @VisitDate
	-------------------------
END

UPDATE dbo.VisitRecords
SET CAMID = @CAMID,
FormSaved = @FormSaved,
CustomerID = @CustomerID,
EDISID = @EDISID,
VisitDate = @VisitDate,
VisitTime = @VisitTime,
JointVisit = @JointVisit,
VisitReasonID = @VisitReasonID,
AccessDetailsID = @AccessDetailsID,
MetOnSiteID = @MetOnSiteID,
OtherMeetingLocation = @OtherMeetingLocation,
PersonMet = @PersonMet,
CompletedChecksID = @CompletedChecksID,
VerificationID = @VerificationID,
TamperingID = @TamperingID,
TamperingEvidenceID = @TamperingEvidenceID,
ReportFrom = @ReportFrom,
ReportTo = @ReportTo,
ReportDetails = @ReportDetails,
TotalStock = @TotalStock,
AdditionalDetails = @AdditionalDetails,
FurtherDiscussion = @FurtherDiscussion,
AdmissionID = @AdmissionID,
AdmissionMadeByID = @AdmissionMadeByID,
AdmissionMadeByPerson = @AdmissionMadeByPerson,
AdmissionReasonID = @AdmissionReasonID,
AdmissionForID = @AdmissionForID,
UTLLOU = @UTLLOU,
SuggestedDamagesValue = @SuggestedDamagesValue,
DamagesObtained = @DamagesObtained,
DamagesObtainedValue = @DamagesObtainedValue,
DamagesExplaination = @DamagesExplaination,
VisitOutcomeID = @VisitOutcomeID,
FurtherActionID = @FurtherActionID,
FurtherAction = @FurtherAction,
PhysicallyAgressive = @PhysicallyAgressive, 
VerballyAgressive = @VerballyAgressive, 
CalChecksCompletedID = @CalChecksCompletedID, 
LastDelivery = @LastDelivery, 
NextDelivery = @NextDelivery, 
StockAgreedByID = @StockAgreedByID, 
SpecificOutcomeID = @SpecificOutcomeID,
PhysicalEvidenceOfBuyingOut = @PhysicalEvidenceOfBuyingOut,
ComplianceAudit = @ComplianceAudit

WHERE [ID] = @VISITID
AND Deleted = 0
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateVisitRecord] TO PUBLIC
    AS [dbo];

