CREATE PROCEDURE [dbo].[UpdateUser]
(
	@UserID		INT,
	@UserName		VARCHAR(255),
	@Login			VARCHAR(255),
	@Password		VARCHAR(255),
	@UserType		INT,
	@EMail			VARCHAR(255),
	@PhoneNumber		VARCHAR(255) = '',
	@NeverExpire		BIT = 0,
	@SendEMailAlert	BIT = 0,
	@SendSMSAlert	BIT = 0,
	@Anonymise		BIT = 0,
	@LanguageOverride		VARCHAR(255) = NULL,
	@VRSUserID		BIGINT = NULL,
	@ReceiveNewCDAlert			BIT = 0,
	@ReceiveiDraughtScorecard	BIT = 0
)

AS

UPDATE dbo.Users
SET	UserName = @UserName,
	Login = @Login,
	[Password] = @Password,
	UserType = @UserType,
	EMail = @EMail,
	PhoneNumber = @PhoneNumber,
	NeverExpire = @NeverExpire,
	VRSUserID = @VRSUserID,
	SendEMailAlert = @SendEMailAlert,
	SendSMSAlert = @SendSMSAlert,
	Anonymise = @Anonymise,
	LanguageOverride = @LanguageOverride,
	ReceiveNewCDAlert = @ReceiveNewCDAlert,
	ReceiveiDraughtScorecard = @ReceiveiDraughtScorecard
	
WHERE [ID] = @UserID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateUser] TO PUBLIC
    AS [dbo];


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateUser] TO [WebAdmin]
    AS [dbo];

