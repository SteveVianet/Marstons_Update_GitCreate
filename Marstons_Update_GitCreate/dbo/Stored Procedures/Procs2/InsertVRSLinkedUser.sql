CREATE PROCEDURE [dbo].[InsertVRSLinkedUser]
(
	@UserType	INTEGER,
	@UserName	VARCHAR(255),
	@Login		VARCHAR(255),
	@EMail		VARCHAR(255),
	@NewID		INTEGER		OUTPUT,
	@PhoneNumber	VARCHAR(255) = '',
	@VRSUserID		INT = NULL
)

AS

--This creates a User that is fit only for VRS linking purposes.
--Key fields are set or diabled to ensure the User is not usable on any of our systems.

INSERT INTO dbo.Users
	(UserName, [Login], [Password], UserType, EMail, PhoneNumber, NeverExpire, SendEMailAlert, 
	 SendSMSAlert, WebActive, VRSUserID, LastWebsiteLoginDate, Deleted)
VALUES
	(@UserName, @Login, '', @UserType, @EMail, @PhoneNumber, 0, 0, 
	 0, 0, @VRSUserID, '1990-01-01', 1)

SET @NewID = @@IDENTITY

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[InsertVRSLinkedUser] TO PUBLIC
    AS [dbo];

