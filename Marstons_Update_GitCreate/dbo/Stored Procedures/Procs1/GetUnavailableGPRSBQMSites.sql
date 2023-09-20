CREATE PROCEDURE dbo.GetUnavailableGPRSBQMSites
AS

SET NOCOUNT ON

DECLARE @AlertSites TABLE (EDISID INT NOT NULL)
DECLARE @GPRSSites TABLE (EDISID INT NOT NULL, LastGPRS VARCHAR(100) NULL)

INSERT INTO @AlertSites
SELECT EDISID
FROM Sites
WHERE Quality = 1
AND Hidden = 0
AND SiteClosed = 0
AND LastDownload > DATEADD(month, -3, GETDATE())

--SELECT DISTINCT Sites.EDISID
--FROM Sites
--JOIN SiteProperties ON SiteProperties.EDISID = Sites.EDISID
--JOIN Properties ON Properties.[ID] = SiteProperties.PropertyID
--WHERE Properties.[Name] = 'EmailAlert' OR Properties.[Name] = 'SMSAlert'

INSERT INTO @GPRSSites
SELECT Sites.EDISID, SiteProperties.Value
FROM Sites
JOIN SiteProperties ON SiteProperties.EDISID = Sites.EDISID
JOIN Properties ON Properties.[ID] = SiteProperties.PropertyID
JOIN @AlertSites AS AlertSites ON AlertSites.EDISID = Sites.EDISID
WHERE Properties.[Name] LIKE '%Last GPRS connection%'

SELECT EDISID, LastGPRS
FROM @GPRSSites AS GPRSSites
WHERE CAST(GPRSSites.LastGPRS AS DATETIME) < DATEADD(day, -1, GETDATE())


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetUnavailableGPRSBQMSites] TO PUBLIC
    AS [dbo];

