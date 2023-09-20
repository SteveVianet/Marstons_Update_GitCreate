
CREATE PROCEDURE [dbo].[GetExceptionsEnabledSites]
AS

SELECT	Sites.EDISID,
		Sites.SiteID,
		Sites.Name AS SiteName,
		Sites.Address1,
		Sites.Address2,
		Sites.Address3,
		Sites.Address4,
		Sites.PostCode,
		Sites.OwnerID,
		Owners.Name AS OwnerName
FROM Sites
JOIN Owners ON Owners.ID = Sites.OwnerID
LEFT JOIN (
	SELECT SiteGroupSites.EDISID,
		   SiteGroupSites.IsPrimary
	FROM SiteGroupSites
	JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
	WHERE TypeID = 1
) AS SiteGroupSites ON SiteGroupSites.EDISID = Sites.EDISID
WHERE UseExceptionReporting = 1
AND Hidden = 0
AND Quality = 1
AND (SiteGroupSites.IsPrimary = 1 OR SiteGroupSites.IsPrimary IS NULL)
ORDER BY Owners.Name ASC, Sites.Name ASC

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetExceptionsEnabledSites] TO PUBLIC
    AS [dbo];

