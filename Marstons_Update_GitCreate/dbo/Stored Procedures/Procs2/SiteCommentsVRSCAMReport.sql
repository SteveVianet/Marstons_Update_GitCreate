CREATE PROCEDURE [dbo].[SiteCommentsVRSCAMReport]
	@ScheduleID INT = NULL,
	@EDISID INT = NULL

AS
BEGIN
	
	SET NOCOUNT ON;

	--Get BDM for each site
	DECLARE @BDM TABLE	( 
		ID INT,
		UserName VARCHAR(30),
		EDISID INT
		)

	INSERT INTO @BDM
	SELECT	u.ID,
		u.UserName,
		s.EDISID
	FROM Users As u
		INNER JOIN UserSites as us ON us.UserID = u.ID
		INNER JOIN Sites AS s ON s.EDISID = us.EDISID
	WHERE u.UserType = 2

	--Get Last Auditor Comment

	DECLARE @AuditorComments TABLE(
		EDISID INT,
		AuditorComment VARCHAR(8000)
		)

	INSERT INTO @AuditorComments
	SELECT ss.EDISID,
		(CONVERT(VARCHAR(20),[AddedOn],106)+ ' ' + REPLACE(SUBSTRING(sc.AddedBy,CHARINDEX('\',sc.AddedBy)+1,LEN(sc.AddedBy)), '.', ' ')+': ' + scht.[Description] +': '+ [Text]) AS AuditiorComment
	FROM dbo.SiteComments as sc
		INNER JOIN SiteCommentHeadingTypes AS scht ON scht.ID = sc.HeadingType
		INNER JOIN Sites AS s ON sc.EDISID = s.EDISID
		INNER JOIN (SELECT DISTINCT EDISID
					FROM ScheduleSites AS ss
					WHERE (ss.ScheduleID = @ScheduleID or @ScheduleID IS NULL) AND (ss.EDISID = @EDISID or @EDISID IS NULL)
					 )AS ss ON s.EDISID = ss.EDISID
	WHERE 
		 ([Type] = 1)
		AND [AddedOn] = (SELECT MAX([AddedOn]) FROM SiteComments AS sc2 WHERE sc2.EDISID = sc.EDISID AND [Type]=1)
	

	--Get Last Tamper Comments

	DECLARE @TamperComments TABLE(
		EDISID INT,
		TamperComment VARCHAR(8000)
		)

	INSERT INTO @TamperComments
	SELECT 
		ss.EDISID,
		LastTamperComments.[Description] AS LastTamperComments
	FROM
		TamperCases AS tc
			INNER JOIN TamperCaseEvents AS tce ON tce.CaseID = tc.CaseID
			INNER JOIN (SELECT B.CaseID,
							SUBSTRING(
								(SELECT CONVERT(VARCHAR(8000),A.EventDate,106)+ ' ' + ISNULL(REPLACE(SUBSTRING(A.AcceptedBy,CHARINDEX('\',A.AcceptedBy)+1,LEN(A.AcceptedBy)), '.', ' '),'')+': ' +A.[Text] + CHAR(10) + CHAR(10) as [text()]
								 FROM TamperCaseEvents AS A
								 WHERE A.CaseID = B.CaseID
								 ORDER BY A.EventDate desc
								 For XML PATH('')), 2, 1000) AS [Description] 
						FROM TamperCaseEvents AS B) AS LastTamperComments ON LastTamperComments.CaseID = tce.CaseID
			INNER JOIN (SELECT EDISID, MAX(CaseID) AS MaxCaseID FROM TamperCases AS tc2 Group By EDISID) AS MaxCase ON tc.CaseID = MaxCase.MaxCaseID
			INNER JOIN Sites AS s ON tc.EDISID = s.EDISID
			INNER JOIN (SELECT DISTINCT EDISID
					FROM ScheduleSites AS ss
					WHERE (ss.ScheduleID = @ScheduleID or @ScheduleID IS NULL) AND (ss.EDISID = @EDISID or @EDISID IS NULL)
					 )AS ss ON s.EDISID = ss.EDISID
	GROUP BY ss.EDISID, tce.CaseID, LastTamperComments.[Description]

	--Get Work Detail Comments

	CREATE TABLE #WorkDetailComments (
		EDISID INT,
		WorkDetail VARCHAR(8000),
		LastSCDate VARCHAR(50),
		SCRaisedFor VARCHAR(1000)
		)
	INSERT INTO #WorkDetailComments
	SELECT 
		ss.EDISID,
		WorkDetail.[Description] AS WorkDetail,
		CONVERT(VARCHAR(50),csh.ChangedOn,103) AS LastSCDate,
	    CASE	
			WHEN cf.AdditionalInfo = '' OR cf.AdditionalInfo IS NULL THEN 'None'
			ELSE cf.AdditionalInfo
		END AS SCRaisedFor
	FROM
		Calls AS c
			LEFT JOIN CallWorkDetailComments AS cwdc ON c.ID= cwdc.CallID
			LEFT JOIN (SELECT B.CallID,
							SUBSTRING(
								(SELECT ISNULL(CONVERT(VARCHAR(8000),A.SubmittedOn,106),'')+ ' ' + ISNULL(REPLACE(SUBSTRING(A.WorkDetailCommentBy,CHARINDEX('\',A.WorkDetailCommentBy)+1,LEN(A.WorkDetailCommentBy)), '.', ' '),'')+': ' +CONVERT(VARCHAR(1000),A.WorkDetailComment) + CHAR(10) + CHAR(10) as [text()]
								 FROM Calls AS c2 
									LEFT JOIN CallWorkDetailComments AS A ON c2.ID = A.CallID
									LEFT JOIN CallStatusHistory AS csh ON c2.ID = csh.CallID 
								 WHERE A.CallID = B.CallID
									AND  ChangedOn = (SELECT MAX(ChangedOn) FROM Calls AS c3 LEFT JOIN CallStatusHistory AS csh2 ON csh2.CallID = c3.ID WHERE c2.EDISID = c3.EDISID AND StatusID != 4 AND StatusID !=5 )
								 ORDER BY csh.ChangedOn
								 For XML PATH('')), 1, 1000) AS [Description] 
						FROM CallWorkDetailComments AS B) AS WorkDetail ON cwdc.CallID = WorkDetail.CallID
			LEFT JOIN (SELECT EDISID, MAX(ID) AS MaxCallID FROM Calls AS c2 Group By EDISID) AS MaxCase ON c.ID = MaxCase.MaxCallID
			LEFT JOIN CallStatusHistory AS csh ON  c.ID = csh.CallID
			LEFT JOIN CallFaults AS cf ON  c.ID = cf.CallID 
			INNER JOIN Sites AS s ON c.EDISID = s.EDISID
			INNER JOIN (SELECT DISTINCT EDISID
					FROM ScheduleSites AS ss
					WHERE (ss.ScheduleID = @ScheduleID or @ScheduleID IS NULL) AND (ss.EDISID = @EDISID or @EDISID IS NULL)
					 )AS ss ON s.EDISID = ss.EDISID
	WHERE
		 ChangedOn = (SELECT MAX(ChangedOn) FROM Calls AS c2 LEFT JOIN CallStatusHistory AS csh2 ON csh2.CallID = c2.ID WHERE c2.EDISID = c.EDISID AND StatusID != 4 AND StatusID !=5 )
	GROUP BY ss.EDISID, cwdc.CallID,csh.ChangedOn, cf.AdditionalInfo, WorkDetail.[Description]

	--Get VRS Comments
	--Obtain the relevant infomrtaion from service logger

	DECLARE @MetOnSite TABLE(
		ID INT,
		[Description] VARCHAR(500)
		)

	INSERT INTO @MetOnSite 
	EXEC [SQL1\SQL1].[ServiceLogger].[dbo].[GetVRSMetOnSite]

	DECLARE @ReasonForVisit TABLE(
		ID INT,
		[Description] VARCHAR(500)
		)

	INSERT INTO @ReasonForVisit
	EXEC [SQL1\SQL1].[ServiceLogger].[dbo].[GetVRSReasonForVisit]

	DECLARE @ChecksDone TABLE(
		ID INT,
		[Description] VARCHAR(500)
		)

	INSERT INTO @ChecksDone
	EXEC [SQL1\SQL1].[ServiceLogger].[dbo].[GetVRSCompletedChecks]

	DECLARE @Verification TABLE(
		ID INT,
		[Description] VARCHAR(500)
		)

	INSERT INTO @Verification 
	EXEC [SQL1\SQL1].[ServiceLogger].[dbo].[GetVRSVerification]

	DECLARE @VisitOutcome TABLE(
		ID INT,
		[Description] VARCHAR(500)
		)

	INSERT INTO @VisitOutcome
	EXEC [SQL1\SQL1].[ServiceLogger].[dbo].[GetVRSVisitOutcome]

	--Get VRS Comments put all the information together

	DECLARE @VRSComments TABLE(
		EDISID INT,
		LastVRSDate VARCHAR(50),
		LastVRSComments VARCHAR(8000)
		)

	INSERT INTO @VRSComments
	SELECT 
		s.EDISID,
		CONVERT(VARCHAR(50),vr.VisitDate,103),
		('Met ' + mos.[Description] + ': ' + vr.PersonMet + CHAR(10) + 'Reason For Visit: '+ rfv.[Description] +  CHAR(10) + 'Checks Done: ' + cd.[Description]
			+  CHAR(10) + 'Verification: ' + v.[Description] +  CHAR(10) + 'Outcome: ' + vo.[Description] +  CASE WHEN vr.DamagesObtained = 1 THEN CHAR(10) +'Damages Obtained: Â£' + CONVERT(VARCHAR(50),vr.DamagesObtainedValue) ELSE '' END
			+  CHAR(10) + 'UTL/LOU signed: ' + CASE WHEN vr.UTLLOU = 1 THEN 'No' ELSE 'Yes' END
			+  CHAR(10) + 'Period From: ' + CONVERT(VARCHAR(50),vr.ReportFrom, 103) + ' - ' + CONVERT(VARCHAR(50),vr.ReportTo,103)) AS LastVRSComments
	FROM VisitRecords AS vr
		INNER JOIN @MetOnSite AS mos ON mos.ID = vr.MetOnSiteID
		INNER JOIN @ReasonForVisit AS rfv ON rfv.ID = vr.VisitReasonID
		INNER JOIN @ChecksDone AS cd ON cd.ID = vr.CompletedChecksID
		INNER JOIN @Verification AS v ON v.ID = vr.VerificationID
		INNER JOIN @VisitOutcome AS vo ON vo.ID = vr.VisitOutcomeID
		INNER JOIN Sites AS s ON vr.EDISID = s.EDISID
		INNER JOIN (SELECT DISTINCT EDISID
					FROM ScheduleSites AS ss
					WHERE (ss.ScheduleID = @ScheduleID or @ScheduleID IS NULL) AND (ss.EDISID = @EDISID or @EDISID IS NULL)
					 )AS ss ON s.EDISID = ss.EDISID
	WHERE vr.VisitDate = (SELECT MAX(VisitDate) FROM VisitRecords AS vr2 WHERE vr2.EDISID = vr.EDISID)

	-- Taking into account for Multi Cellar

	DECLARE @Sites TABLE (
		EDISID INT,
		SiteID VARCHAR(50),
		Name VARCHAR(50),
		Address1 VARCHAR(50),
		Address2 VARCHAR(50),
		Address3 VARCHAR(50),
		PostCode VARCHAR(50),
		SiteOnline SMALLDATETIME,
		Hidden BIT
		)

	INSERT INTO @Sites

	SELECT DISTINCT ss.EDISID, s.SiteID, s.Name, s.Address1, s.Address2,s.Address3,s.PostCode,s.SiteOnline,s.Hidden
	FROM ScheduleSites AS ss
		LEFT JOIN (
			SELECT SiteGroupID,EDISID
			FROM SiteGroupSites AS s	
				LEFT JOIN SiteGroups AS sg ON s.SiteGroupID = sg.ID
			WHERE sg.TypeID = 1
		) AS sgs ON sgs.EDISID = ss.EDISID

		LEFT JOIN SiteGroupSites AS sgs2 ON sgs2.SiteGroupID = sgs.SiteGroupID AND sgs2.IsPrimary = 1
		INNER JOIN Sites AS s ON s.EDISID = COALESCE(sgs2.EDISID, ss.EDISID)
	WHERE (ss.ScheduleID = @ScheduleID or @ScheduleID IS NULL) AND (s.EDISID = @EDISID or @EDISID IS NULL)

    -- Main Select Statement 

	SELECT 
		BDM.UserName,
		s.SiteID,
		s.Name,
		ISNULL(VRS.LastVRSDate,'') AS LastVRSDate,
		ISNULL(VRS.LastVRSComments,'')AS LastVRSComments,
		wdc.LastSCDate,
		wdc.SCRaisedFor,
		ISNULL(wdc.WorkDetail,'None') AS WorkDetail,
		ISNULL(tc.TamperComment,'None') AS LastTamperComment,
		ac.AuditorComment
	FROM @Sites AS s
		INNER JOIN @BDM AS BDM ON BDM.EDISID = s.EDISID
		LEFT JOIN #WorkDetailComments AS wdc ON  s.EDISID =wdc.EDISID
		LEFT JOIN @TamperComments AS tc ON s.EDISID = tc.EDISID
		LEFT JOIN @AuditorComments AS ac ON s.EDISID = ac.EDISID
		LEFT JOIN @VRSComments AS VRS ON s.EDISID = VRS.EDISID
	ORDER BY s.Name

	DROP TABLE #WorkDetailComments
	
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SiteCommentsVRSCAMReport] TO PUBLIC
    AS [dbo];

