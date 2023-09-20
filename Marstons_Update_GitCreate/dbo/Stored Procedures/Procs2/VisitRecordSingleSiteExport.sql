CREATE PROCEDURE VisitRecordSingleSiteExport 
	@EDISID INT,
	@VisitID INT = NULL
AS
BEGIN
	SET NOCOUNT ON;

	CREATE TABLE #VisitReasons ([ID] INT, [Description] NVARCHAR(100))
	INSERT INTO #VisitReasons EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSReasonForVisit

	CREATE TABLE #Access ([ID] INT, [Description] NVARCHAR(100))
	INSERT INTO #Access EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSAccessDetails

	CREATE TABLE #Jobs  ([ID] INT, [Description] NVARCHAR(100))
	INSERT INTO #Jobs EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSMetOnSite

	CREATE TABLE #Checks ([ID] INT, [Description] NVARCHAR(100))
	INSERT INTO #Checks EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSCompletedChecks

	CREATE TABLE #Verification ([ID] INT, [Description] NVARCHAR(100))
	INSERT INTO #Verification EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSVerification

	CREATE TABLE #CalChecks ([ID] INT, [Description] NVARCHAR(100))
	INSERT INTO #CalChecks EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSCalChecksCompleted

	CREATE TABLE #Tampering ([ID] INT, [Description] NVARCHAR(100))
	INSERT INTO #Tampering EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSTampering 

	CREATE TABLE #TamperingEvidence ([ID] INT, [Description] NVARCHAR(100))
	INSERT INTO #TamperingEvidence EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSTamperingEvidence  

	CREATE TABLE #Admission  ([ID] INT, [Description] NVARCHAR(100))
	INSERT INTO #Admission EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSAdmission

	CREATE TABLE #AdmissionMadeBy  ([ID] INT, [Description] NVARCHAR(100))
	INSERT INTO #AdmissionMadeBy EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSMetOnSite

	CREATE TABLE #AdmissionReason ([ID] INT, [Description] NVARCHAR(100))
	INSERT INTO #AdmissionReason EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSAdmissionReason 

	CREATE TABLE #AdmissionFor ([ID] INT, [Description] NVARCHAR(100))
	INSERT INTO #AdmissionFor EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSAdmissionFor 

	CREATE TABLE #OverallOutcome ([ID] INT, [Description] NVARCHAR(100))
	INSERT INTO #OverallOutcome EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSVisitOutcome  

	CREATE TABLE #Outcomes ([ID] INT, [Description] NVARCHAR(100))
	INSERT INTO #Outcomes EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSOutcomes

	CREATE TABLE #FurtherAction ([ID] INT, [Description] NVARCHAR(100))
	INSERT INTO #FurtherAction EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSFurtherAction

	CREATE TABLE #BDMActions ([ID] INT, [Description] NVARCHAR(100))
	INSERT INTO #BDMActions EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSActionsTaken

	CREATE TABLE #BDM (ID INT,UserName VARCHAR(30))
	INSERT INTO #BDM
	SELECT	u.ID,
		u.UserName
	FROM Users As u
	WHERE u.UserType = 2
	
	CREATE TABLE #CAM (ID INT,UserName VARCHAR(30))
	INSERT INTO #CAM
	SELECT	u.ID,
		u.UserName
	FROM Users As u
	WHERE u.UserType = 9

    -- Main Select Statement

	SELECT	
		s.SiteID,
		s.Name,
		s.Address3 AS Town,
		CustomerID,
		vr.EDISID,
		vr.ID,
		FormSaved,
		VisitDate AS DateOfVisit,
		VisitTime AS TimeOfVisit,
		JointVisit,
		reasons.[Description] AS ReasonForVisit,
		access.[Description] AS AccessDetails,
		jobs.[Description] AS MetOnSite,
		OtherMeetingLocation,
		PersonMet,
		CASE 
			WHEN PhysicallyAgressive = 0 THEN 'No'
			ELSE 'Yes'
		END AS PhysicallyAggressive,

		CASE 
			WHEN VerballyAgressive = 0 THEN 'No'
			ELSE 'Yes'
		END AS VerballyAgressive, 

		checks.[Description] AS CompletedChecks,
		verification.[Description] AS LineVerification,
		calchecks.[Description] AS CalibrationCheck,
		tampering.[Description] AS Tampering,
		evidence.[Description] AS TamperingEvidence,
		AdditionalDetails,
		FurtherDiscussion,
		ReportFrom,
		ReportTo,
		ReportDetails,

		CONVERT(VARCHAR, LastDelivery, 103) AS LastDelivery,
		CONVERT(VARCHAR, NextDelivery, 103) AS NextDelivery,
		TotalStock,

		admission.[Description] AS AdmissionMade,
		amb.[Description] AS AdmissionMadeBy,
		AdmissionMadeByPerson,
		ar.[Description] AS AdmissionReason,
		af.[Description] AS AdmissionFor,
		CASE 
			WHEN UTLLOU = 0 THEN 'No'
			ELSE 'Yes'
		END AS UTLLOU,
		SuggestedDamagesValue AS SuggestedCompensation,
		DamagesObtainedValue AS ValueOfCompensationObtained,
		DamagesExplaination,
		outcome.[Description] AS OverallOutcomeOfVisit,
		specificOutcome.[Description] AS SpecificOutcomeOfVisit,
		CAM.UserName AS CAM,
		fa.[Description] AS ActionRecommendedByCAM,
		FurtherAction,

		BDM.UserName AS BDM,
		BDMCommentDate,
		actions.[Description] AS ActionTaken,
		vr.BDMComment,
		BDMDamagesIssuedValue AS CompensationIssued,

		Actioned,
		Injunction,
		BDMUTLLOU,
		BDMDamagesIssued,
		BDMPartialReason
		

	FROM dbo.VisitRecords vr
		JOIN #VisitReasons AS reasons ON reasons.ID = vr.VisitReasonID
		JOIN #Access AS access ON access.ID = vr.AccessDetailsID
		JOIN #Jobs AS jobs ON jobs.ID = vr.MetOnSiteID
		JOIN #Checks AS checks ON checks.ID = vr.CompletedChecksID
		JOIN #Verification AS verification ON verification.ID = vr.VerificationID
		JOIN #CalChecks AS calchecks ON calchecks.ID = vr.CalChecksCompletedID
		JOIN #Tampering AS tampering ON tampering.ID = vr.TamperingID
		JOIN #TamperingEvidence AS evidence ON evidence.ID = vr.TamperingEvidenceID
		JOIN #Admission AS admission ON admission.ID = vr.AdmissionID
		JOIN #AdmissionMadeBy as amb ON amb.ID = vr.AdmissionMadeByID
		JOIN #AdmissionReason as ar ON ar.ID = vr.AdmissionReasonID
		JOIN #AdmissionFor AS af ON af.ID = vr.AdmissionForID
		JOIN #OverallOutcome AS outcome ON outcome.ID = vr.VisitOutcomeID
		JOIN #Outcomes AS specificOutcome ON specificOutcome.ID = vr.SpecificOutcomeID
		JOIN #FurtherAction as fa ON fa.ID = vr.FurtherActionID
		JOIN #BDMActions AS actions ON actions.ID = BDMActionTaken
		LEFT JOIN #BDM AS BDM ON BDM.ID = vr.BDMID
		LEFT JOIN #CAM AS CAM ON CAM.ID = vr.CAMID
		JOIN Sites AS s ON s.EDISID = @EDISID
	WHERE 
		(vr.ID = @VisitID OR @VisitID IS NULL)
		AND vr.EDISID = @EDISID
		--AND (CAMID = @UserID OR @UserID IS NULL)
		AND Deleted = 0

	
	DROP TABLE #VisitReasons
	DROP TABLE #Access
	DROP TABLE #Jobs
	DROP TABLE #Checks
	DROP TABLE #Verification
	DROP TABLE #CalChecks
	DROP TABLE #Tampering
	DROP TABLE #TamperingEvidence
	DROP TABLE #Admission
	DROP TABLE #AdmissionMadeBy
	DROP TABLE #AdmissionReason
	DROP TABLE #AdmissionFor
	DROP TABLE #OverallOutcome
	DROP TABLE #Outcomes
	DROP TABLE #FurtherAction
	DROP TABLE #BDM
	DROP TABLE #CAM
	DROP TABLE #BDMActions
	
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[VisitRecordSingleSiteExport] TO PUBLIC
    AS [dbo];

