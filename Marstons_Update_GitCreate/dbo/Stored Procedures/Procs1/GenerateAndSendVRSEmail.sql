CREATE PROCEDURE [dbo].[GenerateAndSendVRSEmail]
(
	@VisitRecordID			INT,
	@SendCustomerEscalation	BIT = 1, --Send to BDM/RM (and VisitEscalationEmail in customer config)  if note is escaleted or VRSEmailAlwaysSend = 1 in customer config. Otherwise don't send anything. Will onloy work if note is verified.
	@SendCAMCopy			BIT = 0, --Send to CAM that created the note
	@SendToInternalUserID	INT = 0, --Send to any internal user
	@SendInternalCopies		BIT = 0, --Send to 'VisitInternalEmail' in customer config
	@AdditionalRecipients	VARCHAR(500) = ''  --Send to additional address(es). Will onloy work if note is verified.
)
AS

SET NOCOUNT ON

--TESTING: TO REMOVE WHEN LIVE
--SET @SendCustomerEscalation = 0
--SET @SendCAMCopy = 1
--SET @SendInternalCopies = 0
--SET @SendToInternalUserID = 0
--SEt @AdditionalRecipients = ''
--/TESTING: TO REMOVE WHEN LIVE
DECLARE @AlwaysSendEmail BIT
DECLARE @EscalateToUserType INT

--Check to see if the note needs to be escalated and to which user type: BDM or RM.
SET @EscalateToUserType = dbo.fnGetEscalationRecipientType(@VisitRecordID)

DECLARE @Head VARCHAR(1000)
DECLARE @Intro VARCHAR(500)
DECLARE @Body VARCHAR(8000)
DECLARE @FinalBody VARCHAR(8000)
DECLARE @Subject VARCHAR(250)
DECLARE @CustomerEmail VARCHAR(100)
DECLARE @CAMEmail VARCHAR(100)
DECLARE @AdditionalEmail VARCHAR(500)
DECLARE @IsReminderEmail BIT
DECLARE @EDISID INT
DECLARE @SiteID VARCHAR(25)
DECLARE @SiteName VARCHAR(50)
DECLARE @SiteTown VARCHAR(50)
DECLARE @CAMName VARCHAR(50)
DECLARE @VisitDate VARCHAR(10)
DECLARE @VisitTime VARCHAR(8)
DECLARE @JoinVisit VARCHAR(50)
DECLARE @AccessDetails VARCHAR(50)
DECLARE @MetOnSite VARCHAR(50)
DECLARE @MetOnSiteOther VARCHAR(50)
DECLARE @PersonMet VARCHAR(50)
DECLARE @VerballyAgressive VARCHAR(3)
DECLARE @PhysicallyAgressive VARCHAR(3)
DECLARE @PhysicalEvidenceOfBuyingOut VARCHAR(3)
DECLARE @ComplianceAudit VARCHAR(3)

DECLARE @CompletedChecks VARCHAR(50)
DECLARE @Verification VARCHAR(50)
DECLARE @VolumeDetails VARCHAR(500)
DECLARE @StockDetails VARCHAR(500)
DECLARE @CalChecksCompletedID INT
DECLARE @CalChecksCompleted VARCHAR(50)
DECLARE @Tampering VARCHAR(50)
DECLARE @TamperingEvidence VARCHAR(50)
DECLARE @ReasonForVisit VARCHAR(50)
DECLARE @ReportFrom VARCHAR(10)
DECLARE @ReportTo VARCHAR(10)
DECLARE @ReportDetails VARCHAR(500)
DECLARE @TotalStock VARCHAR(500)
DECLARE @LastDelivery VARCHAR(10)
DECLARE @NextDelivery VARCHAR(10)
DECLARE @AdditionalDetails VARCHAR(500)
DECLARE @FurtherDiscussion VARCHAR(500)
DECLARE @AdmissionMade VARCHAR(50)
DECLARE @AdmissionMadeByPerson  VARCHAR(50)
DECLARE @AdmissionMadeBy  VARCHAR(50)
DECLARE @ReasonGiven VARCHAR(50)
DECLARE @AdmissionFor VARCHAR(50)
DECLARE @UTLLOUSigned VARCHAR(20)
DECLARE @SuggestedDamagesValue FLOAT
DECLARE @DamagesObtainedValue FLOAT
DECLARE @DamagesObtained VARCHAR(3)
DECLARE @DamagesExplaination VARCHAR(500)
DECLARE @VisitOutcome VARCHAR(50)
DECLARE @SpecificOutcome VARCHAR(50)
DECLARE @OutcomeText VARCHAR(500)
DECLARE @Days INT
DECLARE @FurtherActionDesc VARCHAR(50)
DECLARE @FurtherActionID INT
DECLARE @FurtherAction VARCHAR(500)

DECLARE @VerifiedByVRS BIT
DECLARE @ClosedByCAM BIT
DECLARE @Completed BIT
DECLARE @CustomerAction VARCHAR(50)
DECLARE @CustomerDamages FLOAT
DECLARE @VisitComments VARCHAR(500)
DECLARE @PartialComments VARCHAR(500)

DECLARE @TotalDamagesConfirmed FLOAT
DECLARE @TotalDamagesAgreed FLOAT

DECLARE @DraughtSuggested FLOAT
DECLARE @DraughtAgreed FLOAT
DECLARE @DraughtReportVolume FLOAT
DECLARE @DraughtConfirmedVolume FLOAT
DECLARE @DraughtStock FLOAT

DECLARE @PackageSuggested FLOAT
DECLARE @PackageAgreed FLOAT
DECLARE @PackageCases FLOAT
DECLARE @PackageBottles FLOAT

DECLARE @TamperSuggested FLOAT
DECLARE @TamperAgreed FLOAT
DECLARE @AdminSuggested FLOAT
DECLARE @AdminAgreed FLOAT
DECLARE @OtherSuggested FLOAT
DECLARE @OtherAgreed FLOAT
DECLARE @OtherTotals FLOAT
DECLARE @CAMDamagesCharged FLOAT = 0
DECLARE @CAMUTLCharged FLOAT = 0

--Calculate the various totals to be displayed
SELECT @TotalDamagesConfirmed = SUM(Damages), @TotalDamagesAgreed = SUM(CASE WHEN Agreed = 1 THEN Damages ELSE 0 END)
FROM VisitDamages
WHERE VisitRecordID = @VisitRecordID
GROUP BY VisitRecordID

SELECT @DraughtSuggested = SUM(Damages), @DraughtAgreed = SUM(CASE WHEN Agreed = 1 THEN Damages ELSE 0 END), @DraughtReportVolume = SUM(ReportedDraughtVolume), @DraughtConfirmedVolume = SUM(DraughtVolume), @DraughtStock = SUM(DraughtStock)
FROM VisitDamages
WHERE VisitRecordID = @VisitRecordID AND DamagesType = 1
GROUP BY VisitRecordID

SELECT @PackageSuggested = SUM(Damages), @PackageAgreed = SUM(CASE WHEN Agreed = 1 THEN Damages ELSE 0 END), @PackageCases = SUM(Cases), @PackageBottles = SUM(Bottles)
FROM VisitDamages
WHERE VisitRecordID = @VisitRecordID AND DamagesType = 2
GROUP BY VisitRecordID

SELECT @OtherTotals = SUM(Damages)
FROM VisitDamages
WHERE VisitRecordID = @VisitRecordID AND DamagesType > 2
GROUP BY VisitRecordID

SELECT @TamperSuggested = SUM(Damages), @TamperAgreed = SUM(CASE WHEN Agreed = 1 THEN Damages ELSE 0 END)
FROM VisitDamages
WHERE VisitRecordID = @VisitRecordID AND DamagesType = 3
GROUP BY VisitRecordID

SELECT @AdminSuggested = SUM(Damages), @AdminAgreed = SUM(CASE WHEN Agreed = 1 THEN Damages ELSE 0 END)
FROM VisitDamages
WHERE VisitRecordID = @VisitRecordID AND DamagesType = 4
GROUP BY VisitRecordID

SELECT @OtherSuggested = SUM(Damages), @OtherAgreed = SUM(CASE WHEN Agreed = 1 THEN Damages ELSE 0 END)
FROM VisitDamages
WHERE VisitRecordID = @VisitRecordID AND DamagesType = 5
GROUP BY VisitRecordID

-- If estimated damages or UTL charged by CAM, then automatically send e-mail to BDM
SELECT	@CAMDamagesCharged = ISNULL(VisitDamages.Damages, 0),
		@CAMUTLCharged = ISNULL(VisitRecords.DamagesObtainedValue, 0)
FROM VisitRecords
LEFT JOIN (	SELECT VisitRecordID, SUM(Damages) AS Damages
			FROM VisitDamages
			WHERE VisitRecordID = @VisitRecordID
			GROUP BY VisitRecordID) AS VisitDamages ON VisitDamages.VisitRecordID = VisitRecords.[ID]
WHERE VisitRecords.ID = @VisitRecordID

IF @CAMDamagesCharged > 0 OR @CAMUTLCharged > 0
BEGIN
	SET @AlwaysSendEmail = 1
	
END

--Populate the draught damages table
DECLARE @DraughtDetails varchar(8000)
DECLARE @PackageDetails varchar(8000)
DECLARE @OtherDetails varchar(8000)
DECLARE @SummaryDetails varchar(8000)
SET @DraughtDetails = ''
SET @PackageDetails = ''
SET @OtherDetails = ''
SELECT @DraughtDetails = @DraughtDetails 
	+ CHAR(13) + '<tr>'
	+ '<td>' + ISNULL(Product, '')  + '</td>'
	--+ '<td>' + CONVERT(VARCHAR(7), ISNULL(ReportedDraughtVolume, '0'))  + '</td>'
	+ '<td>' + CASE CalCheck WHEN 2 THEN 'Yes' WHEN 3 THEN 'No' ELSE 'Unknown' END  + '</td>'
	+ '<td>' + CONVERT(VARCHAR(7), ISNULL(DraughtVolume, '0'))  + '</td>'
	--+'<td></td>'
	+ '<td>' + CONVERT(VARCHAR(7), ISNULL(Damages, '0'))  + '</td>'
	+ '<td>' + ISNULL(Comment, '')  + '</td>'
	+ '<td>' + CONVERT(VARCHAR(7), ISNULL(DraughtStock, '0')) + '</td>'
	+ '<td>' + CASE Agreed WHEN 1 THEN 'Yes' WHEN 0 THEN 'No' ELSE 'No' END  + '</td>'
	+ '</tr>'
FROM VisitDamages
WHERE VisitRecordID = @VisitRecordID
AND DamagesType = 1


--Populate the package damages table
SELECT @PackageDetails = @PackageDetails 
	+ CHAR(13) + '<tr>'
	+ '<td>' + ISNULL(Product, '')  + '</td>'
	+ '<td>' + CONVERT(VARCHAR(3), ISNULL(Cases, '0'))  + '</td>'
	+ '<td>' + CONVERT(VARCHAR(3), ISNULL(Bottles, '0'))  + '</td>'
	+ '<td>' + CONVERT(VARCHAR(7), ISNULL(Damages, '0'))  + '</td>'
	+ '<td>' + ISNULL(Comment, '')  + '</td>'
	+ '<td>' + CASE Agreed WHEN 1 THEN 'Yes' WHEN 0 THEN 'No' ELSE 'No' END  + '</td>'
	+ '</tr>'
FROM VisitDamages
WHERE VisitRecordID = @VisitRecordID
AND DamagesType = 2


--Populate the other damages table
SELECT @OtherDetails = @OtherDetails 
	+ CHAR(13) + '<tr>'
	+ '<td>' + CASE DamagesType WHEN 3 THEN 'Tampering Charge' WHEN 4 THEN 'Admin Charge' ELSE 'Other Charge' END  + '</td>'
	+ '<td>' + CONVERT(VARCHAR(7), ISNULL(Damages, '0'))  + '</td>'
	+ '<td>' + CASE Agreed WHEN 1 THEN 'Yes' WHEN 0 THEN 'No' ELSE 'No' END  + '</td>'
	+ '</tr>'
FROM VisitDamages
WHERE VisitRecordID = @VisitRecordID
AND DamagesType > 2



--LOOKUP TABLES
DECLARE @AccessDetailsItems AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @AccessDetailsItems EXEC [EDISSQL1\SQL1].[ServiceLogger].[dbo].[GetVRSAccessDetails]

DECLARE @MetOnSiteItems AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @MetOnSiteItems EXEC [EDISSQL1\SQL1].[ServiceLogger].[dbo].GetVRSMetOnSite

DECLARE @CompletedChecksItems AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @CompletedChecksItems EXEC [EDISSQL1\SQL1].[ServiceLogger].[dbo].GetVRSCompletedChecks

DECLARE @VerificationItems AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @VerificationItems EXEC [EDISSQL1\SQL1].[ServiceLogger].[dbo].GetVRSVerification

DECLARE @CalCheckItems AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @CalCheckItems EXEC [EDISSQL1\SQL1].[ServiceLogger].[dbo].GetVRSCalChecksCompleted

DECLARE @TamperingItems AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @TamperingItems EXEC [EDISSQL1\SQL1].[ServiceLogger].[dbo].GetVRSTampering

DECLARE @TamperingEvidenceItems AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @TamperingEvidenceItems EXEC [EDISSQL1\SQL1].[ServiceLogger].[dbo].GetVRSTamperingEvidence

DECLARE @ReasonItems AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @ReasonItems EXEC [EDISSQL1\SQL1].[ServiceLogger].[dbo].GetVRSReasonForVisit

DECLARE @AdmissionItems AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @AdmissionItems EXEC [EDISSQL1\SQL1].[ServiceLogger].[dbo].GetVRSAdmission

DECLARE @AdmissionByItems AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @AdmissionByItems EXEC [EDISSQL1\SQL1].[ServiceLogger].[dbo].GetVRSMetOnSite

DECLARE @AdmissionReasonItems AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @AdmissionReasonItems EXEC [EDISSQL1\SQL1].[ServiceLogger].[dbo].GetVRSAdmissionReason

DECLARE @AdmissionForItems AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @AdmissionForItems EXEC [EDISSQL1\SQL1].[ServiceLogger].[dbo].GetVRSAdmissionFor

DECLARE @FurtherActionItems AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @FurtherActionItems EXEC [EDISSQL1\SQL1].[ServiceLogger].[dbo].GetVRSFurtherAction

DECLARE @VisitOutcomeItems AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @VisitOutcomeItems EXEC [EDISSQL1\SQL1].[ServiceLogger].[dbo].GetVRSVisitOutcome

DECLARE @SpecificOutcomeItems AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @SpecificOutcomeItems EXEC [EDISSQL1\SQL1].[ServiceLogger].[dbo].GetVRSSpecificOutcome

DECLARE @CustomerActionItems AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @CustomerActionItems EXEC [EDISSQL1\SQL1].[ServiceLogger].[dbo].GetVRSActionsTaken


--Retrieve visitrecord information and populate variables
SELECT @EDISID = Sites.EDISID, 	
	@SiteID = Sites.SiteID,
	@SiteName = Sites.[Name],
	@SiteTown = CASE WHEN LEN(Sites.Address4) = 0 THEN Sites.Address3 ELSE Sites.Address4 END,
	@VisitDate = CONVERT(VARCHAR(10),VisitRecords.VisitDate, 103),
	@VisitTime = CONVERT(VARCHAR(8),VisitRecords.VisitTime,108),
	@CAMName = Users.UserName,
	@JoinVisit = JointVisit,
	@AccessDetails = Access.[Description],
	@MetOnSite = MetOnSite.[Description],
	@MetOnSiteOther = OtherMeetingLocation,
	@PersonMet = PersonMet,
	@VerballyAgressive = CASE VerballyAgressive WHEN 1 THEN 'Yes' WHEN 0 THEN 'No' ELSE 'No' END,
	@PhysicallyAgressive = CASE PhysicallyAgressive WHEN 1 THEN 'Yes' WHEN 0 THEN 'No' ELSE 'No' END,
	@PhysicalEvidenceOfBuyingOut = CASE PhysicalEvidenceOfBuyingOut WHEN 1 THEN 'Yes' WHEN 0 THEN 'No' ELSE 'No' END,
	@ComplianceAudit = CASE ComplianceAudit WHEN 1 THEN 'Yes' WHEN 0 THEN 'No' ELSE '' END,
	@CompletedChecks = CompletedChecks.[Description],
	@Verification = Verification.[Description],
	@CalChecksCompletedID = CalChecksCompletedID,
	@CalChecksCompleted = CalChecks.[Description],
	@Tampering = Tampering.[Description],
	@TamperingEvidence = TamperingEvidence.[Description],
	@ReasonForVisit = Reasons.[Description],
	@ReportFrom = CONVERT(VARCHAR(10), VisitRecords.ReportFrom, 103),
	@ReportTo = CONVERT(VARCHAR(10), VisitRecords.ReportTo, 103),
	@ReportDetails = VisitRecords.ReportDetails,
	@TotalStock = VisitRecords.TotalStock,
	@LastDelivery = CASE WHEN YEAR(VisitRecords.LastDelivery) = 1899 THEN '' ELSE CONVERT(VARCHAR(10), VisitRecords.LastDelivery, 103) END,
	@NextDelivery = CASE WHEN YEAR(VisitRecords.NextDelivery) = 1899 THEN '' ELSE  CONVERT(VARCHAR(10), VisitRecords.NextDelivery, 103) END,
	@AdditionalDetails = VisitRecords.AdditionalDetails,
	@FurtherDiscussion = VisitRecords.FurtherDiscussion,
	@AdmissionMade = Admission.[Description],
	@AdmissionMadeByPerson = AdmissionMadeByPerson,
	@AdmissionMadeBy = AdmissionBy.[Description],
	@ReasonGiven = AdmissionReason.[Description],
	@AdmissionFor = AdmissionFor.[Description],
	@UTLLOUSigned = CASE WHEN UTLLOU = 1 THEN 'Signed' ELSE 'Not signed' END,
	@SuggestedDamagesValue = VisitRecords.SuggestedDamagesValue,
	@DamagesObtainedValue = VisitRecords.DamagesObtainedValue,
	@DamagesObtained = CASE DamagesObtained WHEN 1 THEN 'Yes' WHEN 0 THEN 'No' ELSE 'No' END,
	@DamagesExplaination = VisitRecords.DamagesExplaination,
	@FurtherActionID = VisitRecords.FurtherActionID,
	@FurtherActionDesc = FurtherAction.[Description],
	@FurtherAction = VisitRecords.FurtherAction,
	@VisitOutcome = VisitOutcome.[Description],
	@SpecificOutcome = SpecificOutcome.[Description],
	@Completed = ISNULL(CompletedByCustomer, 0),
	@CustomerAction = ISNULL(CustomerAction.[Description], ''),
	@CustomerDamages = CAST(BDMDamagesIssuedValue AS FLOAT),
	@VisitComments = ISNULL(VisitRecords.BDMComment, ''),
	@PartialComments = ISNULL(BDMPartialReason, ''),
	@VerifiedByVRS = ISNULL(VerifiedByVRS, 0),
	@ClosedByCAM = ISNULL(ClosedByCAM, 0)
FROM VisitRecords
JOIN Sites ON Sites.EDISID = VisitRecords.EDISID
JOIN Users ON Users.[ID] = VisitRecords.CAMID
JOIN @AccessDetailsItems AS Access ON Access.ID = VisitRecords.AccessDetailsID
JOIN @MetOnSiteItems AS MetOnSite ON MetOnSite.ID = VisitRecords.MetOnSiteID
JOIN @CompletedChecksItems AS CompletedChecks ON CompletedChecks.ID = VisitRecords.CompletedChecksID
JOIN @VerificationItems AS Verification ON Verification.ID = VisitRecords.VerificationID
JOIN @CalCheckItems AS CalChecks ON CalChecks.ID = VisitRecords.CalChecksCompletedID
JOIN @TamperingItems AS Tampering ON Tampering.ID = VisitRecords.TamperingID
JOIN @TamperingEvidenceItems AS TamperingEvidence ON TamperingEvidence.ID = VisitRecords.TamperingEvidenceID
JOIN @ReasonItems AS Reasons ON Reasons.[ID] = VisitRecords.VisitReasonID
JOIN @AdmissionItems AS Admission ON Admission.ID = VisitRecords.AdmissionID
JOIN @AdmissionByItems AS AdmissionBy ON AdmissionBy.ID = VisitRecords.AdmissionMadeByID
JOIN @AdmissionReasonItems AS AdmissionReason ON AdmissionReason.ID = VisitRecords.AdmissionReasonID
JOIN @AdmissionForItems AS AdmissionFor ON AdmissionFor.ID = VisitRecords.AdmissionForID
JOIN @FurtherActionItems AS FurtherAction ON FurtherAction.ID = VisitRecords.FurtherActionID
JOIN @VisitOutcomeItems AS VisitOutcome ON VisitOutcome.ID = VisitRecords.VisitOutcomeID
JOIN @SpecificOutcomeItems AS SpecificOutcome ON SpecificOutcome.ID = VisitRecords.SpecificOutcomeID
LEFT JOIN @CustomerActionItems AS CustomerAction ON CustomerAction.ID = VisitRecords.BDMActionTaken
WHERE VisitRecords.[ID] = @VisitRecordID


--Build body text for the email
IF NOT @EDISID IS NULL AND @ClosedByCAM = 1
BEGIN --ONLY send a note out as an email if it exists (no shit) and has been submitted by the CAM
	SET @Subject = 'VRS Visit Note for ' + @SiteID + ', ' + @SiteName + ', ' + @SiteTown
	
	SET @Head = '<html><head>'
			+'<style type="text/css">'
				+ 'html, form, body {padding: 0px; margin: 0px; font-family: Helvetica, Trebuchet MS, Trebuchet, Arial; font-size: 0.95em;} '
				+ 'h1 {font-size: 1.3em;}'
				+ 'table {border: solid 2px #FFFFFF; background-color: #CCCCCC; margin: 10px; text-align: left; width: 100%; border-collapse:collapse; border: solid 2px #FFFFFF; font-family: Helvetica, Trebuchet MS, Trebuchet, Arial; font-size: 0.8em;}'
				+ 'tr {background-color: #CCCCCC; padding: 5px;}'
				+ 'th {border: solid 1px #FFFFFF; font-weight: bold; font-size: 1.1em; padding-left: 0.2em; padding-right: 0.2em; text-align: left;}'
				+ 'td {border: solid 1px #FFFFFF; font-size: 0.90em; padding-left: 0.2em; padding-right: 0.2em;}'
			+ '</style>'
			+ '</head><body style="padding: 0px; margin: 0px; font-family: Helvetica, Trebuchet MS, Trebuchet, Arial; font-size: 0.95em;" >'
	
	SET @Body = '<h1>Visit details</h1><table id="tblVisit" cellspacing="0" cellpadding="0" rules="all"  border="1"> '
				+  '<tr>' 
					+ '<th>Site ID</th><td>' + @SiteID + '</td>'
					+ '<th>Name of person met</th><td>' + ISNULL(@PersonMet, '') + '</td>'
				+ CHAR(13) + '</tr>'
				+ '<tr>'
					+ '<th>Site Name</th><td>' + @SiteName + '</td>'
					+ '<th>Physically aggressive</td><td>' + @PhysicallyAgressive + '</td>'
				+ CHAR(13) + '</tr>'
				+ '<tr>' 
					+ '<th>Date of visit</th><td>' + ISNULL(@VisitDate, '') + '</td>'
					+ '<th>Verbally aggressive</td><td>' + @VerballyAgressive + '</td>' 
				+ CHAR(13) + '</tr>'
				+ '<tr>' 
					+ '<th>Visit time</th><td>' + ISNULL(@VisitTime, '') + '</td>'
					+ '<th>Checks completed</th><td>' + ISNULL(@CompletedChecks, '') + '</td>'
				+ CHAR(13) + '</tr>'
				+ '<tr>' 
					+ '<th>If joint visit with who</th><td>' + ISNULL(@JoinVisit, '')  + '</td>'
					+ '<th>Line Verification</th><td>' + ISNULL(@Verification, '') + '</td>'
				+ CHAR(13) + '</tr>'
				+ '<tr>' 
					+ '<th>Reason for visit</th><td>' + ISNULL(@ReasonForVisit, '') + '</td>'
					+ '<th>Calibration checks</th><td>' + ISNULL(@CalChecksCompleted, '')  + '</td>'
				+ CHAR(13) + '</tr>'
				+ '<tr>' 
					+ '<th>Access details</th><td>' + ISNULL(@AccessDetails, '') + '</td>'
					+ '<th>Tampering</th><td>' + ISNULL(@Tampering, '') + '</td>' 
				+ CHAR(13) + '</tr>'
				+ '<tr>' 
					+ '<th>Met on site</th><td>' + ISNULL(@MetOnSite, '') + '</td>'
					+ '<th>Tampering evidence</th><td>' + ISNULL(@TamperingEvidence, '') + '</td>'
				+ CHAR(13) + '</tr>'
				+ '<tr>' 
					+ '<th>If met on site other - details</th><td>' + ISNULL(@MetOnSiteOther, '') + '</td>'
					+ '<th>Physical evidence of buying out</th><td>' + @PhysicalEvidenceOfBuyingOut + '</td>'
				+ CHAR(13) + '</tr>'
				+ '<tr>' 
					+ '<th>Compliance Audit Completed</th><td colspan="3">' + ISNULL(@ComplianceAudit, '') + '</td>'
				+ CHAR(13) + '</tr>'
				+ '<tr>' 
					+ '<th>Additional details</th><td colspan="3">' + ISNULL(@AdditionalDetails, '') + '</td>'
				+ CHAR(13) + '</tr>'
				+ '<tr>' 
					+ '<th>Further discussion</th><td colspan="3">' + ISNULL(@FurtherDiscussion, '') + '</td>'
				+ '</tr>' 
			+ '</table><BR><BR>'
	
	
	IF @DraughtDetails <> ''
	BEGIN
		SET @Body = @Body + '<h1>Draught details: ' + @ReportFrom + ' - ' + @ReportTo + '</h1><table id="tblDraught" cellspacing="0" cellpadding="0" rules="all"  border="1"> '
	 
				+ '<tr>' 
					+ '<th>Product</th>'
					--+ '<th>Report Volume (gallons)</th>'
					+ '<th>Cal Check Successful</th>'
					+ '<th>Volume Suggested (gallons)</th>'
					+ '<th>Suggested Value (£)</th>'
					+ '<th>Comment</th>'
					+ '<th>Stock (gallons)</th>'
					+ '<th>Agreed</th>'
				+ '</tr>'
				+ @DraughtDetails
				+ '<tr>'
					+ '<th>Totals</th>'
					--+ '<th>' + ISNULL(CAST(@DraughtReportVolume AS VARCHAR), '0') + '</th>'
					+ '<th></th>'
					+ '<th>' + ISNULL(CAST(@DraughtConfirmedVolume AS VARCHAR), '0') + '</th>'
					+ '<th>' + ISNULL(CAST(@DraughtSuggested AS VARCHAR), '0') + '</th>'
					+ '<th></th>'
					+ '<th>' + ISNULL(CAST(@DraughtStock AS VARCHAR), '0') + '</th>'
				+ '</tr>'
				+ '</table><BR><BR>'
	END
	
	IF @PackageDetails <> ''
	BEGIN
		SET @Body = @Body + '<h1>Package details: ' + @ReportFrom + ' - ' + @ReportTo + '</h1><table id="tblPackage" cellspacing="0" cellpadding="0" rules="all"  border="1"> '
	 
				+ '<tr>' 
					+ '<th>Product</th>'
					+ '<th>Cases</th>'
					+ '<th>Bottles</th>'
					+ '<th>Suggested Value (£)</th>'
					+ '<th>Comment</th>'
					+ '<th>Agreed</th>'
				+ '</tr>'
				+ @PackageDetails
				+ '<tr>'
					+ '<th>Totals</th>'
					+ '<th>' + ISNULL(CAST(@PackageCases AS VARCHAR), '0') + '</th>'
					+ '<th>' + ISNULL(CAST(@PackageBottles AS VARCHAR), '0') + '</th>'
					+ '<th>' + ISNULL(CAST(@PackageSuggested AS VARCHAR), '0') + '</th>'
					+ '<th></th>'
					+ '<th></th>'
				+ '</tr>'
				+ '</table><BR><BR>'
	END
	
	IF @OtherDetails <> ''
	BEGIN
		SET @Body = @Body + '<h1>Other details: ' + @ReportFrom + ' - ' + @ReportTo + '</h1><table id="tblPackage" cellspacing="0" cellpadding="0" rules="all"  border="1""> '
	 
				+ '<tr>' 
					+ '<th>Type of Compensation</th>'
					+ '<th>Value (£)</th>'
					+ '<th>Agreed</th>'
				+ '</tr>'
				+ @OtherDetails
				+ '<tr>'
					+ '<th>Totals</th>'
					+ '<th>' + ISNULL(CAST(@OtherTotals AS VARCHAR), '0') + '</th>'
					+ '<th></th>'
				+ '</tr>'
				+ '</table><BR><BR>'
	END
	
	
	SET @Body = @Body + '<h1>Compensation summary: ' + @ReportFrom + ' - ' + @ReportTo + '</h1><table id="tblSummary" cellspacing="0" cellpadding="0" rules="all"  border="1"> '
	 
				+ '<tr>' 
					+ '<th></th>'
					+ '<th>Suggested compensation (£)</th>'
					+ '<th>Agreed compensation (£)</th>'
				+ CHAR(13) + '</tr>'
				+ '<tr>' 
					+ '<th>Draught charges</th>'
					+ '<td>' + ISNULL(CAST(@DraughtSuggested AS VARCHAR), '0') + '</td>'
					+ '<td>' + ISNULL(CAST(@DraughtAgreed AS VARCHAR), '0') + '</td>'
				+ CHAR(13) + '</tr>'
				+ '<tr>' 
					+ '<th>Package charges</th>'
					+ '<td>' + ISNULL(CAST(@PackageSuggested AS VARCHAR), '0') + '</td>'
					+ '<td>' + ISNULL(CAST(@PackageAgreed AS VARCHAR), '0') + '</td>'
				+ CHAR(13) + '</tr>'
				+ '<tr>' 
					+ '<th>Tampering charges</th>'
					+ '<td>' + ISNULL(CAST(@TamperSuggested AS VARCHAR), '0') + '</td>'
					+ '<td>' + ISNULL(CAST(@TamperAgreed AS VARCHAR), '0') + '</td>'
				+ CHAR(13) + '</tr>'
				+ '<tr>' 
					+ '<th>Admin charges</th>'
					+ '<td>' + ISNULL(CAST(@AdminSuggested AS VARCHAR), '0') + '</td>'
					+ '<td>' + ISNULL(CAST(@AdminAgreed AS VARCHAR), '0') + '</td>'	
				+ CHAR(13) + '</tr>'
				+ '<tr>' 
					+ '<th>Other charges</th>'
					+ '<td>' + ISNULL(CAST(@OtherSuggested AS VARCHAR), '0') + '</td>'
					+ '<td>' + ISNULL(CAST(@OtherAgreed AS VARCHAR), '0') + '</td>'
				+ CHAR(13) + '</tr>'
				+ '<tr>' 
					+ '<th>Totals</th>'
					+ '<th>' + ISNULL(CAST(@TotalDamagesConfirmed AS VARCHAR), '0') + '</th>'
					+ '<th>' + ISNULL(CAST(@TotalDamagesAgreed AS VARCHAR), '0') + '</th>'
				+ CHAR(13) + '</tr>'
				+ '</table><BR><BR>'
	
	
	
	IF @SpecificOutcome <> '<ERROR - Unknown>'
	BEGIN
		SET @OutcomeText =  '<th>Specific outcome</th>'
				+ '<td colspan="3">' + ISNULL(@SpecificOutcome, '') + '</td>'
				+ CHAR(13) + '</tr>'
				+ '<tr>'
				+ '<th>Comments on further action</th>'
				+ '<td colspan="3">' + ISNULL(@FurtherAction, '') + '</td>'
	END
	ELSE
	BEGIN
		SET @OutcomeText =  '<th>Comments on further action</th>'
				+ '<td colspan="3">' + ISNULL(@FurtherAction, '') + '</td>'
	END
	
	SET @Body = @Body + '<h1>Outcome details</h1><table id="tblSummary" cellspacing="0" cellpadding="0" rules="all"  border="1"> '
	 
				+ '<tr>' 
					+ '<th>Admission made</th>'
					+ '<td>' + ISNULL(@AdmissionMade, '') + '</td>'
					+ '<th>UTL / LOU Signed</th>'
					+ '<td>' + ISNULL(@UTLLOUSigned, '') + '</td>'
				+ CHAR(13) + '</tr>'
				+ '<tr>' 
					+ '<th>Admission made by</th>'
					+ '<td>' + ISNULL(@AdmissionMadeBy, '') + '</td>'
					+ '<th>Suggested compensation (£)</th>'
					+ '<td>' + ISNULL(CAST(@TotalDamagesConfirmed AS VARCHAR), '0') + '</td>'
				+ CHAR(13) + '</tr>'
				+ '<tr>' 
					+ '<th>Admission made by name</th>'
					+ '<td>' + ISNULL(@AdmissionMadeByPerson, '') + '</td>'
					+ '<th>Compensation obtained</th>'
					+ '<td>' + ISNULL(@DamagesObtained, '') + '</td>'
				+ CHAR(13) + '</tr>'
				+ '<tr>' 
					+ '<th>Admission for</th>'
					+ '<td>' + ISNULL(@AdmissionFor, '') + '</td>'
					+ '<th>Compensation obtained (£)</th>'
					+ '<td>' + ISNULL(CAST(@DamagesObtainedValue AS VARCHAR), '0') + '</td>'
				+ CHAR(13) + '</tr>'
				+ '<tr>' 
					+ '<th>Reason given</th>'
					+ '<td>' + ISNULL(@ReasonGiven, '') + '</td>'
					+ '<th>Why compensation different than suggested</th>'
					+ '<td>' + ISNULL(@DamagesExplaination, '') + '</td>'
				+ CHAR(13) + '</tr>'
				+ '<tr>' 
					+ '<th>Overall outcome of visit</th>'
					+ '<td>' + ISNULL(@VisitOutcome, '') + '</td>'
					+ '<th>Recommended action</th>'
					+ '<td>' + ISNULL(@FurtherActionDesc, '') + '</td>'
				+ CHAR(13) + '</tr>'
				+ '<tr>' 
					+ @OutcomeText
				+ '</tr>'
				+ '</table><BR><BR>'
	
	IF @Completed = 1
	BEGIN
		SET @Body = @Body + '<h1>Customer action</h1><table id="tblSummary" cellspacing="0" cellpadding="0" rules="all"  border="1"> '
	 
				+ '<tr>' 
					+ '<th>Action taken</th>'
					+ '<td>' + ISNULL(@CustomerAction, '') + '</td>'
					+ '<th>Damages amount (£)</th>'
					+ '<td>' + ISNULL(CAST(@CustomerDamages AS VARCHAR), '0') + '</td>'
				+ CHAR(13) + '</tr>'
				+ '<tr>' 
					+ '<th>Reason for charging partial damages</th>'
					+ '<td>' + ISNULL(@PartialComments, '') + '</td>'
					+ '<th>Visit comments</th>'
					+ '<td>' + ISNULL(@VisitComments, '0') + '</td>'
				+ CHAR(13) + '</tr>'
				+ '</table><BR><BR>'
	END
	



	---Done building email. Finally we can send them. Hazza!
	
	--Send the ecalation email to BDM/RM and any additional customer address in Configuration table.
	IF @SendCustomerEscalation = 1 AND @VerifiedByVRS = 1 
	BEGIN --Only if the note has been verified
		SET @AdditionalEmail = ''
		SET @CustomerEmail = ''
		SET @Intro = '<P>Please find below the details of the VRS visit note for your records. <BR><BR>'
		
			
		IF @EscalateToUserType > 0
		BEGIN
			SET @Intro = '<P>Please find below the details of the new VRS visit note. <BR>'
		      + 'If you would like to action this note please <a href=http://www.brulines.com/site>click here</a> to visit the Brulines website. <BR><BR>'
		
			SELECT @CustomerEmail = Users.EMail
			FROM VisitRecords
			JOIN Sites ON Sites.EDISID = VisitRecords.EDISID
			JOIN UserSites ON UserSites.EDISID = Sites.EDISID
			JOIN Users ON Users.[ID] = UserSites.UserID
			WHERE VisitRecords.[ID] = @VisitRecordID
			AND Users.UserType = @EscalateToUserType
			
			SET @FinalBody = @Head + @Intro + @Body
			EXEC dbo.SendEmail 'vrs@brulines.com', 'Brulines VRS', @CustomerEmail, @Subject, @FinalBody
			
		END
		
		
		IF @AlwaysSendEmail = 1 AND @EscalateToUserType <> 2
		BEGIN --Always send notes to BDMs regardless of escalation but don't send to BDM if above code already did.
			
			SET @Intro = '<P>Please find below the details of the new VRS visit note with CAM damages. <BR><BR>'
			
			SELECT @CustomerEmail = Users.EMail
			FROM VisitRecords
			JOIN Sites ON Sites.EDISID = VisitRecords.EDISID
			JOIN UserSites ON UserSites.EDISID = Sites.EDISID
			JOIN Users ON Users.[ID] = UserSites.UserID
			WHERE VisitRecords.[ID] = @VisitRecordID
			AND Users.UserType = 2 --BDM
			
			SET @FinalBody = @Head + @Intro + @Body
			EXEC dbo.SendEmail 'vrs@brulines.com', 'Brulines VRS', @CustomerEmail, @Subject, @FinalBody
		END
		
		

		--Extend the resend date to be x days later
		IF @EscalateToUserType > 0
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
				UPDATE VisitRecords
				SET ResendEmailOn = DATEADD(day, @Days, ISNULL(ResendEmailOn, CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, DATEADD(day, @Days, GETDATE()))))))
				WHERE [ID] = @VisitRecordID	

			END
		END

		
		--Send email to additional customer address in Configuration table (e.g. vrsfilenotes@enterpriseinns.plc.uk)
		IF @AlwaysSendEmail = 1 OR @EscalateToUserType > 0
		BEGIN 
			SELECT @AdditionalEmail = PropertyValue
			FROM Configuration
			WHERE PropertyName = 'VisitEscalationEmail'
			
			IF @AdditionalEmail <> ''
			BEGIN
				SET @FinalBody = @Head + @Intro + @Body
				EXEC dbo.SendEmail 'vrs@brulines.com', 'Brulines VRS', @AdditionalEmail, @Subject, @FinalBody

			END
		
		END
		
	END --End of Escalation email shenanigans
	
	
	
	
	IF @VerifiedByVRS = 1
	BEGIN
		SET @Intro = '<P>Please find below the details of the VRS visit note for your records.<BR><BR>'
	END
	ELSE
	BEGIN
		SET @Intro = '<P>Please find below the details of the VRS visit note for your records. The note has not yet been completed by the VRS department.<BR><BR>'
	END
	
	
	--Send email to the CAM that added the note
	IF @SendCAMCopy = 1
	BEGIN
		SET @CAMEmail = ''
		
		SELECT @CAMEmail = Users.EMail
		FROM VisitRecords
		JOIN Users ON Users.[ID] = VisitRecords.CAMID
		WHERE VisitRecords.[ID] = @VisitRecordID
		
		IF @CAMEmail <> ''
		BEGIN
			SET @FinalBody = @Head + @Intro + @Body
			EXEC dbo.SendEmail 'vrs@brulines.com', 'Brulines VRS', @CAMEmail, @Subject, @FinalBody
		END
		
	END
	
	
	--Send email to additional internal address. Specified by 'VisitInternalCopyEmail' in Configuration table
	IF @SendInternalCopies = 1
	BEGIN
		SET @AdditionalEmail = ''
		
		SELECT @AdditionalEmail = PropertyValue
		FROM Configuration
		WHERE PropertyName = 'VisitInternalCopyEmail'
		
		IF @AdditionalEmail <> ''
		BEGIN
			SET @FinalBody = @Head + @Intro + @Body
			
			EXEC dbo.SendEmail 'vrs@brulines.com', 'Brulines VRS', @AdditionalEmail, @Subject, @FinalBody
		END

	END
	

	--Send email to additional internal address. Specified by the Users.ID passed in to the SP.
	IF @SendToInternalUserID > 0
	BEGIN
		SET @AdditionalEmail = ''
		SELECT @AdditionalEmail = Users.EMail
		FROM Users
		WHERE Users.ID = @SendToInternalUserID AND UserType IN (7,8,9) --Brulines users
		
		IF @AdditionalEmail <> ''
		BEGIN
			SET @FinalBody = @Head + @Intro + @Body
			EXEC dbo.SendEmail 'vrs@brulines.com', 'Brulines VRS', @AdditionalEmail, @Subject, @FinalBody
		
		END
		
	END
	
	--Finally we send to any manually added recipients
	IF @AdditionalRecipients <> '' AND @VerifiedByVRS = 1 
	BEGIN --Could be an external email so note needs to be verified
		SET @FinalBody = @Head + @Intro + @Body
		EXEC dbo.SendEmail 'vrs@brulines.com', 'Brulines VRS', @AdditionalRecipients, @Subject, @FinalBody
	END

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GenerateAndSendVRSEmail] TO PUBLIC
    AS [dbo];

