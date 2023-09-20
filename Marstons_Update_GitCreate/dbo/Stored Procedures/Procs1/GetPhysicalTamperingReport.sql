CREATE PROCEDURE [dbo].[GetPhysicalTamperingReport] 
	-- Add the parameters for the stored procedure here
	@FromDate DATETIME,
	@ToDate DATETIME
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	/*-- For Debugging Purposes
	DECLARE @FromDate	DATETIME
	DECLARE @ToDate		DATETIME
	
	SET @FromDate	= '2011-01-01'
	SET @ToDate		= '2011-02-20'
	*/

    -- Insert statements for procedure here
    DECLARE @RelevantCases		TABLE (	CaseID INT NOT NULL, EDISID INT NOT NULL, ConfirmDate DATE NOT NULL)
    
	DECLARE @PhysicalTampering	TABLE (	CustomerName						VARCHAR(255) NOT NULL, 
										EDISID								INT NOT NULL,
										SiteID								VARCHAR(15) NOT NULL,
										SiteName							VARCHAR(60) NOT NULL,
										SiteAddress							VARCHAR(50) NOT NULL,
										Region								VARCHAR(50) NOT NULL,
										SiteAuditor							VARCHAR(255),
										CAM									VARCHAR(255),
										VRS									VARCHAR(255),
										IsHighRisk							BIT NOT NULL,
										SpecialMeasures						BIT NOT NULL,
										PhysicalTamperingConfirmation		DATETIME NOT NULL,
										IdentifiedBy						INT,
										LatestTamperingDate					DATETIME NOT NULL,
										ServiceCallRef						VARCHAR(4096),
										CallFault							VARCHAR(4096),
										WorkDone							VARCHAR(4096),
										WorkDetail							VARCHAR(4096),
										TamperComment						VARCHAR(4096),
										PreviousServiceCalls				INT NOT NULL
										)

	--Relevant Tamper Cases
	INSERT INTO @RelevantCases 
		(CaseID, EDISID, ConfirmDate)
	SELECT TamperCases.CaseID, TamperCases.EDISID, MAX(EventDate) FROM TamperCaseEvents
	JOIN TamperCases ON TamperCases.CaseID = TamperCaseEvents.CaseID
	WHERE SeverityID = 4 --Physical Confirmation
	  AND EventDate BETWEEN @FromDate AND DATEADD(ss,-1,DATEADD(dd,1, @ToDate))
	 GROUP BY TamperCases.CaseID, TamperCases.EDISID

	INSERT INTO @PhysicalTampering
		(CustomerName, EDISID, SiteID, SiteName, SiteAddress, Region, SiteAuditor, CAM, PreviousServiceCalls, VRS, TamperComment, SpecialMeasures, 
		 IsHighRisk, PhysicalTamperingConfirmation, IdentifiedBy, LatestTamperingDate)
	SELECT	EDISDatabases.CompanyName,
			Sites.EDISID, 
			Sites.SiteID, 
			Sites.Name, 
			ISNULL(Sites.Address2, Sites.Address3) AS [Address], 
			Regions.[Description] AS Region, 
			Sites.SiteUser AS Auditor, 
			CAMs.UserName AS CAM,
			ISNULL(ServiceCalls.CallCount, 0) AS CallCount, 
			InternalUsers.UserName AS VRS, 
			LatestTamperInfo.Comment AS TamperComment, 
			CASE UPPER(SpecialMeasures.Value)
				WHEN 'TRUE'	THEN 1
				WHEN 'YES'	THEN 1
				WHEN '1'	THEN 1
				ELSE 0
			END AS HasSpecialMeasures,
			CASE UPPER(ISNULL(HighRiskEvents.Value,'No Events Recorded'))
				WHEN 'NO EVENTS RECORDED'	THEN 0
				ELSE 1
			END AS HighRisk,
			Cases.ConfirmDate,
			ISNULL(LatestTamperInfo.SeverityUserID, 1) AS SeverityUserID, --Default to Auditor for historical items with no assigned info
			LatestTamperInfo.LatestUpdate AS EventDate
	FROM Sites
	JOIN @RelevantCases AS Cases 
		ON Cases.EDISID = Sites.EDISID
	JOIN Regions 
		ON Regions.ID = Sites.Region
	LEFT JOIN (
		SELECT EDISID, UserName
		FROM UserSites
		JOIN Users 
			ON Users.ID = UserSites.UserID
		WHERE Users.UserType = 9 --VRS CAM
		) AS CAMs
		ON CAMs.EDISID = Sites.EDISID
	LEFT JOIN (
		SELECT EDISID, COUNT(ID) AS CallCount
		FROM Calls
		WHERE CallTypeID = 1
		AND RaisedOn <= @ToDate
		GROUP BY EDISID
		) AS ServiceCalls
		ON ServiceCalls.EDISID = Sites.EDISID
	LEFT JOIN (
		SELECT TamperCaseEvents.CaseID, UserID AS VRSUserID, [Text] AS Comment, CAST(LatestCaseInfo.LatestUpdate AS DATE) AS LatestUpdate, TamperCaseEvents.SeverityUserID
		FROM TamperCaseEvents
		JOIN (
			SELECT Cases.CaseID, MAX(EventDate) AS LatestUpdate
			FROM TamperCaseEvents
			JOIN @RelevantCases AS Cases
				ON Cases.CaseID = TamperCaseEvents.CaseID
			WHERE SeverityID = 4
			GROUP BY Cases.CaseID
			) AS LatestCaseInfo
			ON LatestCaseInfo.CaseID = TamperCaseEvents.CaseID
			AND LatestCaseInfo.LatestUpdate = TamperCaseEvents.EventDate
		) AS LatestTamperInfo
		ON LatestTamperInfo.CaseID = Cases.CaseID
	JOIN InternalUsers
		ON InternalUsers.ID = LatestTamperInfo.VRSUserID
	LEFT JOIN (
		SELECT EDISID, Value
		FROM SiteProperties
		JOIN Properties 
			ON Properties.ID = SiteProperties.PropertyID
			AND UPPER(Properties.Name) = 'SPECIALMEASURES'
		) AS SpecialMeasures
		ON SpecialMeasures.EDISID = Sites.EDISID
	LEFT JOIN (
		SELECT EDISID, Value
		FROM SiteProperties
		JOIN Properties 
			ON Properties.ID = SiteProperties.PropertyID
			AND Properties.Name = 'LastHighRiskEvent' --This value is hard-coded in SiteLib
		) AS HighRiskEvents
		ON HighRiskEvents.EDISID = Sites.EDISID
	JOIN (
		SELECT CompanyName, Name FROM [EDISSQL1\SQL1].ServiceLogger.dbo.EDISDatabases
		) AS EDISDatabases
		ON EDISDatabases.Name = DB_NAME()
	GROUP BY	EDISDatabases.CompanyName, Sites.EDISID, Sites.SiteID, Sites.Name, ISNULL(Sites.Address2, Sites.Address3), 
				Regions.[Description], Sites.SiteUser, CAMs.UserName, ISNULL(ServiceCalls.CallCount, 0),
				InternalUsers.UserName, LatestTamperInfo.Comment,
				CASE UPPER(SpecialMeasures.Value) WHEN 'TRUE' THEN 1 WHEN 'YES' THEN 1 WHEN '1' THEN 1 ELSE 0 END,
				CASE UPPER(ISNULL(HighRiskEvents.Value,'No Events Recorded')) WHEN 'NO EVENTS RECORDED' THEN 0 ELSE 1 END,
				Cases.ConfirmDate, LatestTamperInfo.SeverityUserID, LatestTamperInfo.LatestUpdate
	
	--Add work detail information. This must be done seperately as TEXT fields cannot be used in a GROUP
	UPDATE @PhysicalTampering
	SET ServiceCallRef = dbo.GetCallReference(Calls.ID),
		WorkDetail = CallWorkDetailComments.WorkDetailComment,
		WorkDone = dbo.[GetWorkItemDescriptionFunction](Calls.ID)
	FROM @PhysicalTampering AS TamperResults
	JOIN Calls 
		ON Calls.EDISID = TamperResults.EDISID
	JOIN CallWorkDetailComments 
		ON CallWorkDetailComments.CallID = Calls.ID
	WHERE CAST(CallWorkDetailComments.SubmittedOn AS DATE) = CAST(TamperResults.PhysicalTamperingConfirmation AS DATE)
	
	--Return the results
	SELECT	CustomerName, EDISID, SiteID, SiteName, SiteAddress, Region, ISNULL(SiteAuditor,'') AS SiteAuditor, ISNULL(CAM,'') AS CAM,
			ISNULL(VRS,'') AS VRS, IsHighRisk, SpecialMeasures, PhysicalTamperingConfirmation, IdentifiedBy, 
			ISNULL(ServiceCallRef,'N/A') AS ServiceCallRef, ISNULL(CallFault,'N/A') AS CallFault, ISNULL(WorkDone,'N/A') AS WorkDone, 
			ISNULL(WorkDetail,'N/A') AS WorkDetail, TamperComment, PreviousServiceCalls, LatestTamperingDate
	FROM @PhysicalTampering
	ORDER BY PhysicalTamperingConfirmation DESC

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetPhysicalTamperingReport] TO PUBLIC
    AS [dbo];

