CREATE PROCEDURE [dbo].[GetUserByUserName]
(
	@UserName VARCHAR(255)
) 
AS

SELECT	[ID],
		UserName,
		Login,
		[Password],
		UserType,
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
WHERE UserName = @UserName
ORDER BY [ID]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetUserByUserName] TO PUBLIC
    AS [dbo];

