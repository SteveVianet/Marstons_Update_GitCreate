CREATE PROCEDURE [dbo].[GetSimpleSiteWithUsers]

AS
BEGIN
select Owners.Name as [Owner], s.EDISID, s.SiteID, s.Name as SiteName, 
s.SiteUser as SiteOwner, s.Hidden, u.ID, u.UserName, u.UserType as UserTypeID, ut.[Description] as [UserType], sa.LastAudit
from Sites as s
LEFT JOIN (
	SELECT EDISID, MAX(TimeStamp) AS LastAudit
	FROM SiteAudits
	GROUP BY EDISID
	) AS sa ON  sa.EDISID = s.EDISID
join Owners on s.OwnerID = Owners.ID
join UserSites as us on s.EDISID = us.EDISID
join Users as u on us.UserID = u.ID
join UserTypes as ut on u.UserType = ut.ID
order by us.EDISID
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSimpleSiteWithUsers] TO PUBLIC
    AS [dbo];

