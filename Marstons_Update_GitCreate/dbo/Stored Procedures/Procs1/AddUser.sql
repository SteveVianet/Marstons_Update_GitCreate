CREATE PROCEDURE [dbo].[AddUser]
(
	@UserType	INTEGER,
	@UserName	VARCHAR(255),
	@Login		VARCHAR(255),
	@Password	VARCHAR(255),
	@EMail		VARCHAR(255),
	@NewID		INTEGER		OUTPUT,
	@PhoneNumber	VARCHAR(255) = '',
	@NeverExpire	BIT = 0,
	@SendEMailAlert	BIT = 0,
	@SendSMSAlert	BIT = 0,
	@Anonymise		BIT = 0,
	@ReceiveNewCDAlert			BIT = 0,
	@ReceiveiDraughtScorecard	BIT = 0
)

AS

INSERT INTO dbo.Users
(UserName, Login, [Password], UserType, EMail, PhoneNumber, NeverExpire, SendEMailAlert, SendSMSAlert, ReceiveNewCDAlert, ReceiveiDraughtScorecard)
VALUES
(@UserName, @Login, @Password, @UserType, @EMail, @PhoneNumber, @NeverExpire, @SendEMailAlert, @SendSMSAlert, @ReceiveNewCDAlert, @ReceiveiDraughtScorecard)

SET @NewID = @@IDENTITY

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddUser] TO PUBLIC
    AS [dbo];


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddUser] TO [WebAdmin]
    AS [dbo];

