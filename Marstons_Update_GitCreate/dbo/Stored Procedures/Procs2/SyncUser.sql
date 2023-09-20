CREATE PROCEDURE [dbo].[SyncUser]
	-- Add the parameters for the stored procedure here
  (
	
	@UserName		VARCHAR(255),
	@Login			VARCHAR(255),
	@Password		VARCHAR(255),
	@UserType		INT,
	@EMail			VARCHAR(255),
	@PhoneNumber		VARCHAR(255) = '',
	@Deleted		BIT = 0,
	@WebEnabled		BIT = 0,
	@LastWebsiteLoginDate		DATETIME,
	@LastWebsiteLoginIPAddress	VARCHAR(255),
	@NeverExpire		BIT = 0,
	@VRSUserID		BIGINT = NULL,
	@SendEMailAlert	BIT = 0,
	@SendSMSAlert	BIT = 0,
	@Anonymise		BIT = 0,
	@LanguageOverride		VARCHAR(255) = NULL
  )
  
  
AS
BEGIN

	SET NOCOUNT ON;
		
	EXEC [SQL1\SQL1].ServiceLogger.dbo.SyncUser @UserName, @Login, @Password, @UserType, @EMail, 
	@PhoneNumber, @Deleted, @WebEnabled, @LastWebsiteLoginDate, @LastWebsiteLoginIPAddress, @NeverExpire, 
	@VRSUserID, @SendEMailAlert, @SendSMSAlert, @Anonymise, @LanguageOverride 

END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SyncUser] TO PUBLIC
    AS [dbo];

