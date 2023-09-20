CREATE PROCEDURE [dbo].[GetSitesAudited]
(
	@FromDate		DATETIME,
	@ToDate		DATETIME,
	@IncludeNucleus	BIT = 0
)

AS

SELECT DISTINCT SiteAudits.EDISID
FROM SiteAudits
JOIN Sites ON Sites.EDISID = SiteAudits.EDISID
WHERE ([TimeStamp] BETWEEN @FromDate AND @ToDate)
	AND (@IncludeNucleus = 1 OR SiteAudits.EDISID NOT IN (
		SELECT DISTINCT EDISID FROM SiteProperties
		JOIN Properties ON Properties.ID = SiteProperties.PropertyID
		WHERE Properties.Name = 'PreventCallRaise' AND (SiteProperties.Value = '1' OR UPPER(SiteProperties.Value) = 'YES' OR UPPER(SiteProperties.Value) = 'TRUE'))
	)
	AND Sites.Hidden = 0
	AND AuditType = 1

ORDER BY SiteAudits.EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSitesAudited] TO PUBLIC
    AS [dbo];

