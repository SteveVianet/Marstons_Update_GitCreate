CREATE PROCEDURE [dbo].[GetSitesSummary]
(
	@ShowHidden			BIT = 0,
	@RestrictSitesByUser		BIT = 0,
	@RestrictSitesByUserID	INT = 0,
	@OnlyQuality			BIT = 0
)

AS

--DECLARE	@ShowHidden			    BIT = 0
--DECLARE	@RestrictSitesByUser	BIT = 0
--DECLARE	@RestrictSitesByUserID	INT = 0
--DECLARE	@OnlyQuality			BIT = 0

DECLARE @LoginCount		INT
DECLARE @UserHasAllSites		BIT
DECLARE @SiteUsers 			TABLE(EDISID INT NOT NULL, RM INT NOT NULL, BDM INT NOT NULL)
DECLARE @SiteLastAudits		TABLE(EDISID INT NOT NULL, Audited DATETIME NOT NULL)
DECLARE @SiteOutstandingCalls		TABLE(EDISID INT NOT NULL)
SET NOCOUNT ON

-- Check if user exists in log-ins table.
SELECT @LoginCount = COUNT(*)
FROM dbo.Logins
WHERE UPPER([Login]) = UPPER(SUSER_SNAME())

-- Which sites are we allowed to see?
SELECT @UserHasAllSites = AllSitesVisible
FROM dbo.UserTypes
JOIN dbo.Users ON Users.UserType = UserTypes.[ID]
WHERE dbo.Users.[ID] = @RestrictSitesByUserID

-- If not, add the user.
IF @LoginCount = 0
	INSERT INTO Logins([Login], SuperUser)
	VALUES(SUSER_SNAME(), 0)

-- Work out BDM and RM for each site (0 means no user)
INSERT INTO @SiteUsers
(EDISID, RM, BDM)
SELECT  EDISID,
	MAX(CASE WHEN UserType = 1 THEN UserID ELSE 0 END) AS RM,
	MAX(CASE WHEN UserType = 2 THEN UserID ELSE 0 END) AS BDM
FROM UserSites
JOIN Users ON Users.ID = UserSites.UserID
WHERE UserType IN (1,2)
GROUP BY EDISID

-- Work out last audit for each site
INSERT INTO @SiteLastAudits
(EDISID, Audited)
SELECT EDISID, MAX(SiteAudits.[TimeStamp])
FROM SiteAudits
WHERE AuditType = 10
GROUP BY EDISID

INSERT INTO @SiteOutstandingCalls
(EDISID)
SELECT DISTINCT EDISID
FROM Calls
WHERE ClosedOn IS NULL
AND AbortReasonID = 0

DECLARE @DefaultCDA		VARCHAR(50)

SELECT @DefaultCDA = PropertyValue
FROM [Configuration]
WHERE PropertyName = 'AuditorName'

-- Get the site details.
SELECT [Configuration].PropertyValue AS CompanyName,
	Sites.OwnerID,
	Sites.EDISID,
	ISNULL(SiteUsers.RM, 0) AS RM,
	ISNULL(SiteUsers.BDM,0) AS BDM,
	Sites.LastDownload,
	ISNULL(SiteLastAudits.Audited, '1899-12-31') AS LastAudit,
	CASE WHEN SiteOutstandingCalls.EDISID IS NULL THEN 0 ELSE 1 END AS OutstandingCall,
	RMUsers.UserName AS RMName,
	BDMUsers.UserName AS BDMName,
	Owners.[Name] AS OwnerName,
	Sites.SiteID,
	Sites.[Name],
    CASE WHEN LEN(SiteUser) > 0 THEN SiteUser 
         ELSE @DefaultCDA
    END AS [Auditor],
    [LastClean].[Value] AS [LastCleaned],
    CASE WHEN [SpecialMeasures].[EDISID] IS NULL THEN 0 ELSE 1 END AS [InSpecialMeasures]
FROM Sites  WITH (NOLOCK)
LEFT OUTER JOIN @SiteLastAudits AS SiteLastAudits ON SiteLastAudits.EDISID = Sites.EDISID
LEFT OUTER JOIN @SiteUsers AS SiteUsers ON (SiteUsers.EDISID = Sites.EDISID OR SiteUsers.EDISID = SiteLastAudits.EDISID)
LEFT OUTER JOIN @SiteOutstandingCalls AS SiteOutstandingCalls ON SiteOutstandingCalls.EDISID = Sites.EDISID
LEFT OUTER JOIN Users AS RMUsers ON RMUsers.ID = SiteUsers.RM
LEFT OUTER JOIN Users AS BDMUsers ON BDMUsers.ID = SiteUsers.BDM
LEFT OUTER JOIN (
    SELECT 
        [SiteProperties].[EDISID],
        [SiteProperties].[Value]
    FROM [dbo].[Properties]
    JOIN [dbo].[SiteProperties] ON [Properties].[ID] = [SiteProperties].[PropertyID]
    WHERE
        [SiteProperties].[Value] <> ''
    AND [Properties].[Name] = 'Last Cleaned'
    ) AS [LastClean] ON [Sites].[EDISID] = [LastClean].[EDISID]
JOIN Owners ON Owners.ID = Sites.OwnerID
JOIN [Configuration] ON [Configuration].PropertyName = 'Company Name'
LEFT OUTER JOIN (
    SELECT 
        [SiteProperties].[EDISID],
        [SiteProperties].[Value]
    FROM [dbo].[Properties]
    JOIN [dbo].[SiteProperties] ON [Properties].[ID] = [SiteProperties].[PropertyID]
    WHERE [Properties].[Name] = 'SpecialMeasures'
    ) AS [SpecialMeasures] ON [Sites].[EDISID] = [SpecialMeasures].[EDISID]
WHERE ([Hidden] = 0 OR @ShowHidden = 1)
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
AND Sites.EDISID NOT IN (
	SELECT EDISID
	FROM SiteGroupSites
	JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
	WHERE TypeID = 1 AND IsPrimary <> 1
)
ORDER BY Sites.Name

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSitesSummary] TO PUBLIC
    AS [dbo];

