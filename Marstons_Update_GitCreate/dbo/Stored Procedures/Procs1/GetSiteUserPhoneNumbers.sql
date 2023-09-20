CREATE PROCEDURE [dbo].[GetSiteUserPhoneNumbers]
(
	@EDISID		INT
)

AS

select EDISID, ut.ID as UserTypeID, ut.Description as UserType, u.UserName, u.PhoneNumber
from UserSites as us
join Users  as u on us.UserID = u.ID
join UserTypes as ut on u.UserType = ut.ID
Where EDISID = @EDISID and (u.UserType = 1 or u.UserType = 2 or u.UserType=9)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteUserPhoneNumbers] TO PUBLIC
    AS [dbo];

