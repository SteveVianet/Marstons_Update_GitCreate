
CREATE PROCEDURE art.GetSiteAuditsByDateTime
(
	@From		DATETIME,
	@To			DATETIME
)
AS

SELECT	Owners.Name AS CustomerName,
		Sites.SiteID,
		Sites.Name AS SiteName,
		SiteAudits.UserName AS EmployeeName,
		SiteAudits.[TimeStamp] AS [DateTime],
		SiteAudits.AuditType
FROM SiteAudits
JOIN Sites ON Sites.EDISID = SiteAudits.EDISID
JOIN Owners ON Owners.ID = Sites.OwnerID
WHERE [TimeStamp] BETWEEN @From AND @To
ORDER BY SiteAudits.[TimeStamp] ASC

GO
GRANT EXECUTE
    ON OBJECT::[art].[GetSiteAuditsByDateTime] TO PUBLIC
    AS [dbo];

