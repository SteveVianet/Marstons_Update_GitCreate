CREATE PROCEDURE [dbo].[UpdateUserByLoginName]
(
	@UserName					VARCHAR(255),
	@Login						VARCHAR(255),
	@Password					VARCHAR(255),
	@UserType					INT,
	@EMail						VARCHAR(255),
	@PhoneNumber				VARCHAR(255) = '',
	@Deleted					BIT = 0,
	@WebEnabled					BIT = 1 ,
	@LastWebsiteLoginDate		DateTime =  '',
	@LastWebsiteLoginIPAddress	VARCHAR(255) = '',
	@NeverExpire				BIT = 0,
	@VRSUserID					BIGINT = NULL,
	@SendEMailAlert				BIT = 0,
	@SendSMSAlert				BIT = 0,
	@Anonymise					BIT = 0,
	@LanguageOverride			VARCHAR(20) = ''
	
)

AS

DECLARE @RealLanguage VARCHAR(20)

IF @LanguageOverride = ''
BEGIN
	SET @RealLanguage = NULL
END
ELSE
BEGIN
	SET @RealLanguage = @LanguageOverride
END


UPDATE dbo.Users
SET	--UserName = @UserName,     -- No need to update
	--[Login] = @Login,         -- No need to update
	[Password] = @Password,     -- UserName/Login/Password match, = Synced user
	UserType = @UserType,       -- Must be consistent between databases/customers
    --EMail = @EMail,           -- Unsafe
	--PhoneNumber = @PhoneNumber,     -- Unsafe
	--Deleted = @Deleted,       -- Do not allow unintended un-delete
	--WebActive = @WebEnabled,  -- Unsafe? Control website login access.
	LastWebsiteLoginDate = @LastWebsiteLoginDate, -- User Insights
	LastWebsiteLoginIPAddress = @LastWebsiteLoginIPAddress, -- User Insights
	NeverExpire = @NeverExpire, -- Unsure how synced users work with expiry
	--VRSUserID = @VRSUserID,     -- Unsafe? Controls VRS website login.
	--SendEMailAlert = @SendEMailAlert, -- User should set manually?
	--SendSMSAlert = @SendSMSAlert, -- User should set manually?
	--Anonymise = @Anonymise,
	LanguageOverride = @RealLanguage -- Let user website language settings sync

WHERE
    [UserName] = @UserName 
AND [Login] = @Login
AND [Deleted] != 1
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateUserByLoginName] TO PUBLIC
    AS [dbo];

