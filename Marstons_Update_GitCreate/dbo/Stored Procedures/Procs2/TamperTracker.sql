CREATE PROCEDURE TamperTracker 
	@ScheduleID INT,
	@CAMParam INT = Null,
	@BDMParam INT = Null,
	@AssignedToParam VARCHAR(50) = '!All',
	@SuspectedTamperLevelParam INT = Null,
	@TamperMethodParam VARCHAR(50) = '!All',
	@ShowHidden BIT = 0
	
AS
BEGIN
	
	SET NOCOUNT ON;

	--Get Latest Tamper Data

	DECLARE @TamperData TABLE (
		EDISID INT,
		CaseID INT,
		[Date] DATETIME,
		TypeListID INT,
		[Text] VARCHAR(8000),
		AssignedTo VARCHAR(50),
		SeverityDescriptionID INT,
		TrackerStatus VARCHAR(100),
		MethodOfTampering VARCHAR(200)
		)

	INSERT INTO @TamperData
	SELECT
		ss.EDISID,
		tce.CaseID AS [CaseID],
		tce.EventDate AS [Date],
		tce.TypeListID AS [TypeListID],
		(CONVERT(VARCHAR(8000),tce.EventDate,106)+': ' + tce.[Text]) AS VRSLastComment,
		REPLACE(SUBSTRING(tce.AcceptedBy,CHARINDEX('\',tce.AcceptedBy)+1,LEN(tce.AcceptedBy)), '.', ' ') As AssignedTo,
		tcesd.ID AS SeverityDescriptionID,
		tcesd.[Description] AS TrackerStatus,
		
		MethodOfTampering.[Description] AS MethodOfTampering
	FROM
		TamperCases AS tc
			INNER JOIN TamperCaseEvents AS tce ON tce.CaseID = tc.CaseID
			INNER JOIN TamperCaseEventsSeverityDescriptions AS tcesd ON tcesd.ID = tce.SeverityID
			INNER JOIN (SELECT B.RefID,
							SUBSTRING(
								(SELECT C.[Description] + CHAR(10) + CHAR(10) as [text()]
								 FROM TamperCaseEventTypeList AS A
									INNER JOIN TamperCaseEventTypeDescriptions AS C ON C.ID = A.TypeID
								 WHERE A.RefID = B.RefID
								 For XML PATH('')), 0, 1000) AS [Description]
						FROM TamperCaseEventTypeList AS B) AS MethodOfTampering ON MethodOfTampering.RefID = tce.TypeListID
			LEFT JOIN ScheduleSites AS ss On ss.EDISID = tc.EDISID
	WHERE
		ss.ScheduleID = @ScheduleID AND EventDate = (SELECT MAX(EventDate) FROM TamperCaseEvents AS tce2 WHERE tce2.CaseID = tce.CaseID) AND tce.SeverityID != 0
	GROUP BY tce.EventDate, ss.EDISID, tce.CaseID, tce.TypeListID, tce.[Text], tce.AcceptedBy,tcesd.[Description],MethodOfTampering.[Description],tcesd.ID
	ORDER BY 
		ss.EDISID,EventDate DESC	

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

	--Get CAM for each site
	DECLARE @CAM TABLE	( 
		ID INT,
		UserName VARCHAR(30),
		EDISID INT
			)

	INSERT INTO @CAM
	SELECT u.ID,
		u.UserName,
		s.EDISID
	FROM Users As u
		INNER JOIN UserSites as us ON us.UserID = u.ID
		INNER JOIN Sites AS s ON s.EDISID = us.EDISID
	WHERE u.UserType = '9' and us.EDISID = s.EDISID and u.EMail NOT LIKE '%vianet%'

	--Get date site was put on Tamper Tracker and weeks of suspected tampering

	DECLARE @TamperDurationTemp TABLE (
		EDISID INT,
		[Date] DATETIME
		)

	INSERT INTO @TamperDurationTemp
	SELECT
		ss.EDISID,
		tce.EventDate AS [Date]
		
	FROM
		TamperCases AS tc
			INNER JOIN TamperCaseEvents AS tce ON tce.CaseID = tc.CaseID
			LEFT JOIN ScheduleSites AS ss On ss.EDISID = tc.EDISID
	WHERE
		ss.ScheduleID = @ScheduleID AND EventDate = (SELECT MIN(EventDate) FROM TamperCaseEvents AS tce2 WHERE tce2.CaseID = tce.CaseID)
	GROUP BY ss.EDISID, tce.EventDate
	ORDER BY 
		ss.EDISID,EventDate DESC	

	DECLARE @TamperDuration TABLE(
		EDISID INT,
		[Date] DATETIME,
		WeeksOfTampering INT
		)

	INSERT INTO @TamperDuration
	SELECT 
		temp.EDISID,
		temp.[Date],
		REPLACE(DATEDIFF(week,GETDATE(),temp.[Date]), '-', '') AS WeeksOfSuspectedTampering
	FROM @TamperDurationTemp AS temp
	WHERE temp.[Date] = (SELECT MAX(temp2.[Date]) FROM @TamperDurationTemp AS temp2 WHERE temp.EDISID = temp2.EDISID)

	--Get All VRS Comments for the latest case 

	DECLARE @VRSAllComments TABLE (
		EDISID INT,
		CaseID INT,
		[Text] VARCHAR(8000)
		)

	INSERT INTO @VRSAllComments
	SELECT 
		ss.EDISID,
		tce.CaseID AS [CaseID],
		VRSAllComments.[Description] AS VRSAllComments
	FROM
		TamperCases AS tc
			INNER JOIN TamperCaseEvents AS tce ON tce.CaseID = tc.CaseID
			INNER JOIN (SELECT B.CaseID,
							SUBSTRING(
								(SELECT CONVERT(VARCHAR(8000),A.EventDate,106)+': ' +A.[Text] + CHAR(10) + CHAR(10) as [text()]
								 FROM TamperCaseEvents AS A
								 WHERE A.CaseID = B.CaseID
								 ORDER BY A.EventDate desc
								 For XML PATH('')), 2, 1000) AS [Description] 
						FROM TamperCaseEvents AS B) AS VRSAllComments ON VRSAllComments.CaseID = tce.CaseID
			INNER JOIN (SELECT EDISID, MAX(CaseID) AS MaxCaseID FROM TamperCases AS tc2 Group By EDISID) AS MaxCase ON tc.CaseID = MaxCase.MaxCaseID
			LEFT JOIN ScheduleSites AS ss On ss.EDISID = tc.EDISID
	WHERE
		ss.ScheduleID = @ScheduleID
	GROUP BY ss.EDISID, tce.CaseID, VRSAllComments.[Description]

	--Get Previous CAM comments

	DECLARE @PreviousCAMComments TABLE (
		EDISID INT,
		CaseID INT,
		[Text] VARCHAR(8000)
		)

	INSERT INTO @PreviousCAMComments
	SELECT 
		ss.EDISID,
		tce.CaseID AS [CaseID],
		PrevCamComments.[Description] AS PreviousCAMComments
	FROM
		TamperCases AS tc
			INNER JOIN TamperCaseEvents AS tce ON tce.CaseID = tc.CaseID
			INNER JOIN (SELECT B.CaseID,
							SUBSTRING(
								(SELECT CONVERT(VARCHAR(8000),A.EventDate,106)+': ' +A.[Text] + ', ' as [text()]
								 FROM TamperCaseEvents AS A
								 WHERE A.CaseID = B.CaseID
								 ORDER BY A.EventDate desc
								 For XML PATH('')), 2, 1000) AS [Description] 
						FROM TamperCaseEvents AS B) AS PrevCamComments ON PrevCamComments.CaseID = tce.CaseID
			INNER JOIN (SELECT EDISID, MAX(CaseID) AS MaxCaseID FROM TamperCases AS tc2 Group By EDISID) AS MaxCase ON tc.CaseID = MaxCase.MaxCaseID
			INNER JOIN Users AS u ON u.ID = tce.UserID
			LEFT JOIN ScheduleSites AS ss On ss.EDISID = tc.EDISID
	WHERE
		ss.ScheduleID = @ScheduleID AND u.UserType = '9'
	GROUP BY ss.EDISID, tce.CaseID, PrevCamComments.[Description]

	--Determine whether the site is in special measures

	DECLARE @SpecialMeasures TABLE (
		EDISID INT, 
		PropertyID INT
		)


	INSERT INTO @SpecialMeasures
	SELECT 
		sp.EDISID,
		sp.PropertyID
	FROM SiteProperties AS sp
	WHERE PropertyID = 14

    -- Main Select Statement

	SELECT DISTINCT
		s.SiteID,
		s.Name,
		CASE 
			WHEN s.Address3 = '' AND s.Address2 = '' THEN s.Address1
			WHEN s.Address3 = '' THEN s.Address2
			ELSE s.Address3
		END AS Town,

		BDM.UserName AS BDM,
		CAM.UserName AS CAM,
		td.[Date],
		td.[Text] AS VRSLastComment,
		td.TrackerStatus,
		td.AssignedTo,
		Tduration.[Date] AS DateSiteWasPutOnTamperTracker,
		Tduration.WeeksOfTampering AS WeeksOfSuspectedTampering,
		td.MethodOfTampering, 
		comments.[Text] AS VRSComments,
		ISNULL(pcc.[Text],'') AS PreviousCAMComments,

		CASE
			WHEN s.[Status] = '1' THEN 'Installed - Active'
			WHEN s.[Status] = '2' THEN 'Installed - Closed'
			WHEN s.[Status] = '3' THEN 'Installed - Legals'
			WHEN s.[Status] = '4' THEN 'Installed - Not Reported On'
			WHEN s.[Status] = '5' THEN 'Installed - Written Off'
			WHEN s.[Status] = '6' THEN 'Not Installed - System To Be Refit'
			WHEN s.[Status] = '7' THEN 'Not Installed - Missing/Not Uplifted By Brulines'
			WHEN s.[Status] = '8' THEN 'Not Installed - Non Brulines'
			WHEN s.[Status] = '9' THEN 'Not Installed - Uplifted'
			WHEN s.[Status] = '10' THEN 'Installed - FOT'
			WHEN s.[Status] = '11' THEN 'Installed - Telecoms Active'
			ELSE 'Unknown'
		END AS SiteStatus,

		CASE 
			WHEN sm.EDISID IS NOT NULL THEN 'Yes'
			ELSE 'No'
		END AS SpecialMeasures
	
	FROM Sites AS s 
		INNER JOIN ScheduleSites AS ss On s.EDISID = ss.EDISID
		LEFT JOIN UserSites AS us ON s.EDISID = us.EDISID
		LEFT JOIN @BDM as BDM ON us.EDISID = BDM.EDISID
		LEFT JOIN @CAM AS CAM ON us.EDISID = CAM.EDISID
		INNER JOIN @TamperData AS td ON s.EDISID = td.EDISID
		INNER JOIN @TamperDuration AS Tduration ON Tduration.EDISID = s.EDISID
		INNER JOIN @VRSAllComments AS comments ON comments.EDISID = s.EDISID
		LEFT JOIN @PreviousCAMComments AS pcc ON s.EDISID = pcc.EDISID
		LEFT JOIN @SpecialMeasures AS sm ON s.EDISID = sm.EDISID
	WHERE ss.ScheduleID = @ScheduleID AND (CAM.ID = @CAMParam OR @CAMParam is null)
		AND (BDM.ID = @BDMParam OR @BDMParam is null) 
		AND (td.AssignedTo = @AssignedToParam OR @AssignedToParam ='!All')
		AND (td.SeverityDescriptionID = @SuspectedTamperLevelParam OR @SuspectedTamperLevelParam is null)
		AND (td.MethodOfTampering LIKE '%'+ @TamperMethodParam +'%' OR @TamperMethodParam ='!All')
		AND (s.Hidden = 0 or @ShowHidden = 1)

	ORDER BY s.SiteID

	
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[TamperTracker] TO PUBLIC
    AS [dbo];

