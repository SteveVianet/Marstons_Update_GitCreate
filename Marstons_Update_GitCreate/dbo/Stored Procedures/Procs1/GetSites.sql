
CREATE PROCEDURE [dbo].[GetSites]
(
	@ShowHidden			BIT = 0,
	@RestrictSitesByUser		BIT = 0,
	@RestrictSitesByUserID	INT = 0,
	@OnlyQuality			BIT = 0
)

AS

--WAITFOR  DELAY '00:01:05'

SET NOCOUNT ON

DECLARE @LoginCount			INT
DECLARE @UserHasAllSites		BIT
DECLARE @MultipleAuditors BIT


DECLARE @ElectricalWorksSummary 		TABLE(EDISID INT NOT NULL PRIMARY KEY,
										MinorWorks DATETIME,
										Plug DATETIME,
										Contractor  DATETIME)


DECLARE @AuditorDetails	TABLE(AuditorName VARCHAR (50), 
							  AuditorShortName VARCHAR (50),	
							  TeamLeaderID INT, 
							  TeamLeader VARCHAR (50), 
							  UserGrade VARCHAR (20))

DECLARE @DefaultCDA VARCHAR(50)
SELECT @DefaultCDA = PropertyValue
FROM Configuration
WHERE PropertyName = 'AuditorName'

INSERT INTO @AuditorDetails (AuditorName, AuditorShortName, TeamLeaderID, TeamLeader, UserGrade)
SELECT UPPER(Logins.[Login]) AS AuditorName,
	   UPPER(dbo.udfNiceName(Logins.[Login])) AS AuditorShortName,
	   Logins.TeamLeader AS TeamLeaderID,
	   TeamLeaders.[Login] AS TeamLeader,
	   Logins.UserGrade AS UserGrade
FROM [SQL1\SQL1].ServiceLogger.dbo.Logins AS Logins
LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.Logins AS TeamLeaders ON TeamLeaders.ID = Logins.TeamLeader


INSERT INTO @ElectricalWorksSummary (EDISID, MinorWorks, Plug, Contractor)
SELECT  Sites.EDISID,
	ElectricalMinorWorks.VisitedOn AS MinorWorks,
	ElectricalPlug.VisitedOn AS Plug,
	ElectricalContractor.VisitedOn AS Contractor
FROM Sites WITH (NOLOCK)
LEFT JOIN (
	SELECT EDISID, MAX(VisitedOn) AS VisitedOn
	FROM CallWorkItems WITH (NOLOCK)
	JOIN Calls WITH (NOLOCK) ON Calls.ID = CallWorkItems.CallID
	WHERE WorkItemID = 42 AND VisitedOn IS NOT NULL GROUP BY EDISID
) AS ElectricalMinorWorks ON ElectricalMinorWorks.EDISID = Sites.EDISID
LEFT JOIN (
	SELECT EDISID, MAX(VisitedOn) AS VisitedOn
	FROM CallWorkItems WITH (NOLOCK)
	JOIN Calls WITH (NOLOCK) ON Calls.ID = CallWorkItems.CallID
	WHERE WorkItemID = 43 AND VisitedOn IS NOT NULL GROUP BY EDISID
) AS ElectricalPlug ON ElectricalPlug.EDISID = Sites.EDISID
LEFT JOIN (
	SELECT EDISID, MAX(VisitedOn) AS VisitedOn
	FROM CallWorkItems WITH (NOLOCK)
	JOIN Calls WITH (NOLOCK) ON Calls.ID = CallWorkItems.CallID
	WHERE WorkItemID = 44 AND VisitedOn IS NOT NULL GROUP BY EDISID
) AS ElectricalContractor ON ElectricalContractor.EDISID = Sites.EDISID
WHERE (ElectricalMinorWorks.VisitedOn IS NOT NULL OR ElectricalPlug.VisitedOn IS NOT NULL OR  ElectricalContractor.VisitedOn IS NOT NULL)
AND (Sites.Hidden = 0 OR @ShowHidden = 1)

-- Check if user exists in log-ins table.
SELECT @LoginCount = COUNT(*)
FROM dbo.Logins
WHERE UPPER(Login) = UPPER(SUSER_SNAME())

-- Which sites are we allowed to see?
SELECT @UserHasAllSites = AllSitesVisible
FROM dbo.UserTypes
JOIN dbo.Users ON Users.UserType = UserTypes.[ID]
WHERE dbo.Users.[ID] = @RestrictSitesByUserID

-- If not, add the user.
IF @LoginCount = 0
	INSERT INTO Logins(Login, SuperUser)
	VALUES(SUSER_SNAME(), 0)

-- Find whether the database has Multipole Auditor mode enabled
SELECT @MultipleAuditors = MultipleAuditors 
FROM [SQL1\SQL1].ServiceLogger.dbo.EDISDatabases
WHERE Name = DB_NAME()
  AND (LimitToClient = HOST_NAME() OR LimitToClient IS NULL)


-- Get the site details.
SELECT	Sites.EDISID,
		OwnerID,
		SiteID,
		[Name] AS SiteName,
		TenantName,
		Address1, Address2, Address3, Address4, PostCode,
		SiteTelNo, EDISTelNo,
		EDISPassword,
		SiteOnline,
		SerialNo,
		Region, AreaID,
		Budget,
		SiteClosed,
		Version,
		LastDownload,
		'' AS Comment,		-- To save time when connecting to database, these 3 fields have been disabled.
		'' AS BDMComment,	-- Their field contents, however, are still in the database itself.
		'' AS InternalComment,
		IsVRSMember,
		VRSOwner,
		ModemTypeID,
		SystemTypeID,
		Hidden,
		CAST(CASE UPPER(SiteUser) 
			WHEN UPPER(SUSER_SNAME()) THEN 1
			ELSE 0
			END AS BIT) AS OwnedSite,			
		CASE WHEN @MultipleAuditors = 1 
		 THEN Sites.SiteUser 
		 ELSE @DefaultCDA			
		END AS SiteOwner,
		SiteGroupID,
		CommunicationProviderID,
		OwnershipStatus,
		AltSiteTelNo,
		UpdateID,
		Quality,
		CASE WHEN InstallationDate IS NULL THEN CAST('2000-01-01' AS DATETIME)
		 ELSE InstallationDate
		END AS InstallationDate,
		ISNULL(GlobalEDISID, 0) AS GlobalEDISID,
		ElectricalWorksSummary.MinorWorks,
		ElectricalWorksSummary.Plug,
		ElectricalWorksSummary.Contractor,
		dbo.udfNiceName(ISNULL(Auditors.TeamLeader, '')) AS TeamLeader,
		ISNULL(Auditors.UserGrade,'') As UserGrade,
		CAST(CASE WHEN SiteContracts.SiteContractID IS NULL THEN 0 ELSE 1 END AS BIT) AS HasSiteContract,
		[Status],
		[ClubMembership],
		EPOSType,
		LastInstallationDate,
		BirthDate,
		LastMaintenanceDate,
		LastPATDate,
		LastElectricalCheckDate,
		ISNULL(LastImportedEndDate, '1899-12-30')  AS LastImportedEndDate,
		ISNULL(LastEPOSImportedDate, '1899-12-30') AS LastEPOSImportedDate
FROM dbo.Sites WITH (NOLOCK)
LEFT JOIN @AuditorDetails AS Auditors ON ( (Auditors.AuditorName = UPPER(Sites.SiteUser) AND @MultipleAuditors = 1)
										OR (Auditors.AuditorShortName = UPPER(@DefaultCDA) AND @MultipleAuditors = 0) )
LEFT JOIN @ElectricalWorksSummary AS ElectricalWorksSummary ON ElectricalWorksSummary.EDISID = Sites.EDISID
LEFT JOIN (SELECT SiteContracts.EDISID, 
				  MAX(SiteContracts.ContractID) AS SiteContractID 
			FROM SiteContracts WITH (NOLOCK)
			GROUP BY EDISID
			) AS SiteContracts ON SiteContracts.EDISID = Sites.EDISID
			
WHERE (Hidden = 0 OR @ShowHidden = 1)
AND (	UPPER(SiteUser) = UPPER(SUSER_SNAME()) 
	OR @RestrictSitesByUser = 0
	OR SiteUser = ''
	OR SiteUser IS NULL)
AND (
	(@RestrictSitesByUserID = 0) OR 
	(@UserHasAllSites = 1) OR 
	(Sites.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @RestrictSitesByUserID))
	)
AND (Quality = 1 OR @OnlyQuality = 0)
ORDER BY [Name]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSites] TO PUBLIC
    AS [dbo];

