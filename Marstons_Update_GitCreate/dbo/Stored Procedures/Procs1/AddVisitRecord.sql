CREATE PROCEDURE [dbo].[AddVisitRecord]
(
	@CAMID 				INT,
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
	@VerificationID 		INT,
	@TamperingID 			INT,
	@TamperingEvidenceID 		INT,
	@ReportFrom 			DATETIME,
	@ReportTo 			DATETIME,
	@ReportDetails 			TEXT,
	@TotalStock 			TEXT,
	@AdditionalDetails 		TEXT,
	@FurtherDiscussion 		TEXT,
	@AdmissionID 			INT,
	@AdmissionMadeByID 		INT,
	@AdmissionMadeByPerson 		VARCHAR(50),
	@AdmissionReasonID		INT,
	@AdmissionForID 		INT,
	@UTLLOU 			BIT,
	@SuggestedDamagesValue 		SMALLMONEY,
	@DamagesObtained 		BIT,
	@DamagesObtainedValue 		SMALLMONEY,
	@DamagesExplaination 		TEXT,
	@VisitOutcomeID 		INT,
	@FurtherActionID 		INT,
	@FurtherAction 			VARCHAR(1024),
        	@DamagesStatus		INT = NULL,
	@ClosedByCAM			BIT = NULL,
	@NewID			INT OUTPUT,
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

SET NOCOUNT ON

DECLARE @Days INT
DECLARE @ResendEmailOn DATETIME

INSERT INTO dbo.VisitRecords
(CAMID, FormSaved,CustomerID,EDISID,VisitDate,VisitTime,JointVisit,VisitReasonID,
AccessDetailsID,MetOnSiteID,OtherMeetingLocation,PersonMet,CompletedChecksID,
VerificationID,TamperingID,TamperingEvidenceID,ReportFrom,ReportTo,ReportDetails,
TotalStock,AdditionalDetails,FurtherDiscussion,AdmissionID,AdmissionMadeByID,AdmissionMadeByPerson,
AdmissionReasonID,AdmissionForID,UTLLOU,SuggestedDamagesValue,DamagesObtained,
DamagesObtainedValue,DamagesExplaination,VisitOutcomeID,FurtherActionID,FurtherAction,
PhysicallyAgressive, VerballyAgressive, CalChecksCompletedID, LastDelivery, NextDelivery, StockAgreedByID, SpecificOutcomeID,
DraughtDamagesTotalValue, DraughtDamagesTotalAgreedValue, Deleted, PhysicalEvidenceOfBuyingOut, ComplianceAudit)
VALUES
(@CAMID,@FormSaved,@CustomerID,@EDISID,@VisitDate,@VisitTime,@JointVisit,@VisitReasonID,
@AccessDetailsID,@MetOnSiteID,@OtherMeetingLocation,@PersonMet,@CompletedChecksID,@VerificationID,
@TamperingID,@TamperingEvidenceID,@ReportFrom,@ReportTo,@ReportDetails,@TotalStock,@AdditionalDetails,
@FurtherDiscussion,@AdmissionID,@AdmissionMadeByID,@AdmissionMadeByPerson,@AdmissionReasonID,@AdmissionForID,
@UTLLOU,@SuggestedDamagesValue,@DamagesObtained,@DamagesObtainedValue,@DamagesExplaination,@VisitOutcomeID,
@FurtherActionID,@FurtherAction, @PhysicallyAgressive, @VerballyAgressive, @CalChecksCompletedID, @LastDelivery, @NextDelivery, @StockAgreedByID, @SpecificOutcomeID,
@DraughtDamagesTotal, @DraughtDamagesAgreedTotal, 0, @PhysicalEvidenceOfBuyingOut, @ComplianceAudit)

SET @NewID = @@IDENTITY

--Resend e-mail date worked out here. Only relevant for old visit records where CustomerID is set. New visit records date worked out in VRSRecordVerfiy procedure.
IF @CustomerID > 0 AND @FurtherActionID IN (2, 3)
BEGIN
	SELECT @Days = CAST(Value AS INTEGER)
	FROM SiteProperties
	JOIN Properties ON Properties.[ID] = SiteProperties.PropertyID
	WHERE Properties.[Name] = 'Visit Record Email Days Reminder'
	AND EDISID = @EDISID

	IF @Days IS NULL
	BEGIN
		SELECT @Days = CAST(PropertyValue AS INTEGER)
		FROM Configuration
		WHERE PropertyName = 'Visit Record Email Days Reminder'
	
	END

	IF @Days IS NOT NULL
	BEGIN
		SET @ResendEmailOn = CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, DATEADD(day, @Days, GETDATE())))) 
	
		UPDATE VisitRecords
		SET ResendEmailOn = @ResendEmailOn
		WHERE [ID] = @NewID
	END
	
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddVisitRecord] TO PUBLIC
    AS [dbo];

