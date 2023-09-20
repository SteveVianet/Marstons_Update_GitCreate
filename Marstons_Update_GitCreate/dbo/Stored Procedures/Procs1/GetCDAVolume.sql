CREATE PROCEDURE [dbo].[GetCDAVolume]

AS

SET NOCOUNT ON

DECLARE @DefaultCDA VARCHAR(50)
SELECT @DefaultCDA = PropertyValue
FROM Configuration
WHERE PropertyName = 'AuditorName'

DECLARE @CompanyName VARCHAR(50)
SELECT @CompanyName = PropertyValue
FROM Configuration
WHERE PropertyName = 'Company Name'

-- Find whether the database has Multipole Auditor mode enabled
DECLARE @MultipleAuditors BIT
SELECT @MultipleAuditors = MultipleAuditors 
FROM [SQL1\SQL1].ServiceLogger.dbo.EDISDatabases
WHERE Name = DB_NAME()
AND IsDevelopment = 0

DECLARE @RODUsers TABLE([EDISID] INT NOT NULL, [UserName] VARCHAR (50))
DECLARE @BDMUsers TABLE([EDISID] INT NOT NULL, [UserName] VARCHAR (50), [Area] VARCHAR (50))

DECLARE @AuditorDetails	TABLE(AuditorName VARCHAR (50), 
							  AuditorShortName VARCHAR (50),	
							  TeamLeaderID INT, 
							  TeamLeader VARCHAR (50), 
							  UserGrade VARCHAR (20))

--GET AUDITOR DETAILS
INSERT INTO @AuditorDetails (AuditorName, AuditorShortName, TeamLeaderID, TeamLeader, UserGrade)
SELECT LOWER(Logins.[Login]) AS AuditorName,
	   dbo.udfNiceName(Logins.[Login]) AS AuditorShortName,
	   Logins.TeamLeader AS TeamLeaderID,
	   TeamLeaders.[Login] AS TeamLeader,
	   Logins.UserGrade AS UserGrade
FROM [SQL1\SQL1].ServiceLogger.dbo.Logins AS Logins
LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.Logins AS TeamLeaders ON TeamLeaders.ID = Logins.TeamLeader



--GET ROD USERS
INSERT INTO @RODUsers
SELECT Sites.EDISID, Users.UserName
FROM Sites
JOIN UserSites ON UserSites.EDISID = Sites.EDISID 
JOIN Users ON Users.ID = UserSites.UserID
AND Users.UserType = 1
AND Users.Deleted = 0

--GET BDM USERS
INSERT INTO @BDMUsers
SELECT Sites.EDISID, Users.UserName, Areas.[Description]
FROM Sites
JOIN UserSites ON UserSites.EDISID = Sites.EDISID 
JOIN Users ON Users.ID = UserSites.UserID
JOIN Areas ON Areas.ID = Sites.AreaID
AND Users.UserType = 2
AND Users.Deleted = 0

SELECT @CompanyName AS Customer,
	CASE WHEN Quality = 0 THEN 'DMS' ELSE 'I-Draught' END AS SystemType,
	Auditors.AuditorShortName AS AuditorShortName,	
	dbo.udfNiceName(Auditors.TeamLeader) AS TeamLeader,
	Auditors.UserGrade AS UserGrade,
	RODUsers.UserName AS ROD,
	BDMUsers.UserName AS BDM,
	BDMUsers.Area AS BDMArea,
	COUNT(*) AS TotalSites,
	ISNULL (Configuration.PropertyValue, '') AS AccountManagerName		
FROM dbo.Sites

LEFT JOIN @AuditorDetails AS Auditors ON (Auditors.AuditorName = LOWER(Sites.SiteUser) AND @MultipleAuditors = 1) OR (Auditors.AuditorShortName = @DefaultCDA AND @MultipleAuditors = 0)
LEFT JOIN @RODUsers AS RODUsers ON RODUsers.EDISID = Sites.EDISID
LEFT JOIN @BDMUsers AS BDMUsers ON BDMUsers.EDISID = Sites.EDISID
LEFT JOIN Configuration ON Configuration.PropertyName = 'AccountManagerName'
JOIN Owners ON Owners.ID = Sites.OwnerID
WHERE Sites.Hidden = 0

GROUP BY RODUsers.UserName, BDMUsers.UserName, CASE WHEN Quality = 0 THEN 'DMS' ELSE 'I-Draught' END,     Auditors.AuditorShortName, Auditors.TeamLeader, Auditors.UserGrade, BDMUsers.Area, ISNULL(Configuration.PropertyValue, '')

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCDAVolume] TO PUBLIC
    AS [dbo];

