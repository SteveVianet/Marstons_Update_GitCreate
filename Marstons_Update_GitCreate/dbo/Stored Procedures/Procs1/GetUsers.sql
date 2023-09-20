CREATE PROCEDURE [dbo].[GetUsers]
(
	@UserID	INT = 0
) 
AS

SELECT	Users.[ID],
		UserName,
		Login,
		[Password],
		UserType,
		UserTypes.Description as UserTypeDescription,
		EMail,
		PhoneNumber,
		WebActive,
		LastWebsiteLoginDate,
		LastWebsiteLoginIPAddress,
		NeverExpire,
		VRSUserID,
		Deleted,
		SendEMailAlert,
		SendSMSAlert,
		Anonymise,
		LanguageOverride,
		ReceiveNewCDAlert,
		ReceiveiDraughtScorecard
FROM dbo.Users
join UserTypes on Users.UserType = UserTypes.ID
WHERE (Users.[ID] = @UserID OR @UserID = 0)
ORDER BY UserName

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetUsers] TO PUBLIC
    AS [dbo];

