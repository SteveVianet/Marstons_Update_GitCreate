CREATE PROCEDURE dbo.GetCDANotAuditedSites
(
	@From		DATETIME,
	@To		DATETIME
)
AS

SET NOCOUNT ON

DECLARE @SiteRMUsers TABLE(EDISID INT, UserName VARCHAR(100))
DECLARE @SiteBDMUsers TABLE(EDISID INT, UserName VARCHAR(100))
DECLARE @SitesNotAudited TABLE(EDISID INT)

DECLARE @DefaultCDA VARCHAR(50)

SELECT @DefaultCDA = PropertyValue
FROM Configuration
WHERE PropertyName = 'AuditorName'

INSERT INTO @SiteRMUsers
(EDISID, UserName)
SELECT EDISID,
	 RMUsers.UserName
FROM UserSites
JOIN Users AS RMUsers ON RMUsers.[ID] = UserSites.UserID AND RMUsers.UserType = 1

INSERT INTO @SiteBDMUsers
(EDISID, UserName)
SELECT EDISID,
	 BDMUsers.UserName
FROM UserSites
JOIN Users AS BDMUsers ON BDMUsers.[ID] = UserSites.UserID AND BDMUsers.UserType = 2

INSERT INTO @SitesNotAudited
(EDISID)
SELECT Sites.EDISID
FROM Sites
LEFT JOIN SiteAudits ON SiteAudits.EDISID = Sites.EDISID AND ([TimeStamp] BETWEEN @From AND @To)
WHERE Hidden = 0
AND [TimeStamp] IS NULL

SELECT Configuration.PropertyValue AS Customer,
	 Sites.SiteID,
	 Sites.[Name] AS SiteName,
	 CASE WHEN Sites.SiteUser IS NULL OR LEN(Sites.SiteUser) = 0 THEN @DefaultCDA ELSE Sites.SiteUser END AS CDA,
	 ISNULL(SiteRMUsers.UserName, '') AS RM,
	 ISNULL(SiteBDMUsers.UserName, '') AS BDM,
	 Areas.[Description] AS Area
FROM Sites
LEFT JOIN UserSites ON UserSites.EDISID = Sites.EDISID
JOIN Areas ON Areas.[ID] = Sites.AreaID
LEFT JOIN @SiteRMUsers AS SiteRMUsers ON SiteRMUsers.EDISID = Sites.EDISID
LEFT JOIN @SiteBDMUsers AS SiteBDMUsers ON SiteBDMUsers.EDISID = Sites.EDISID
JOIN Configuration ON Configuration.PropertyName = 'Company Name'
JOIN @SitesNotAudited AS SitesNotAudited ON SitesNotAudited.EDISID = Sites.EDISID
WHERE Hidden = 0
GROUP BY Configuration.PropertyValue,
	 Sites.SiteID,
	 Sites.[Name],
 	 CASE WHEN Sites.SiteUser IS NULL OR LEN(Sites.SiteUser) = 0 THEN @DefaultCDA ELSE Sites.SiteUser END,
	 SiteRMUsers.UserName,
	 SiteBDMUsers.UserName,
	 Areas.[Description]
ORDER BY CASE WHEN Sites.SiteUser IS NULL OR LEN(Sites.SiteUser) = 0 THEN @DefaultCDA ELSE Sites.SiteUser END





GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCDANotAuditedSites] TO PUBLIC
    AS [dbo];

