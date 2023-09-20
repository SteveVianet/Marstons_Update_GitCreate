
CREATE PROCEDURE [dbo].[GenerateAndSendCDEmailAlert]
AS

SET NOCOUNT ON

DECLARE @UserName VARCHAR(255)
DECLARE @Login VARCHAR(255)
DECLARE @Password VARCHAR(255)
DECLARE @EMail VARCHAR(255)
DECLARE @UserID INT
DECLARE @DatabaseID INT
DECLARE @CompanyName VARCHAR(100)

DECLARE @Subject VARCHAR(1000)
DECLARE @Head VARCHAR(8000)
DECLARE @Body VARCHAR(8000)
DECLARE @AccountController VARCHAR(100)
DECLARE @AccountControllerEmail VARCHAR(100)
DECLARE @CDEmailList VARCHAR(8000)

SELECT @AccountController = CAST(PropertyValue AS VARCHAR(100))
FROM Configuration
WHERE PropertyName = 'AccountManagerName'

SELECT @AccountControllerEmail = CAST(PropertyValue AS VARCHAR(100))
FROM Configuration
WHERE PropertyName = 'AccountManagerEMail'

SELECT @CDEmailList = CAST(PropertyValue AS VARCHAR(8000))
FROM Configuration
WHERE PropertyName = 'CD EMail'

SELECT @DatabaseID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

SELECT @CompanyName = CompanyName
FROM [EDISSQL1\SQL1].ServiceLogger.dbo.EDISDatabases
WHERE ID = @DatabaseID

--Send email to CD email list from Configuration table above
SET @Subject = 'Calculated Deficits Data Available'

SET @Body = '<html><head></head>' 
			+ '<body>'
			+ '<p>New Calculated Deficit (CD) reporting for ' + @CompanyName + ' is now available.</p>'
			+ '</body></html>'

EXEC dbo.SendEmail  '', '', @CDEmailList, @Subject, @Body, '', NULL, NULL

--Send emails to other users who have the CD alerts option turned on
DECLARE curEmails CURSOR FORWARD_ONLY READ_ONLY FOR
SELECT ID
FROM Users
WHERE ReceiveNewCDAlert = 1 
AND WebActive = 1
AND Deleted = 0
AND (LastWebsiteLoginDate >= DATEADD(DAY, -90, GETDATE()) OR NeverExpire = 1)

OPEN curEmails
FETCH NEXT FROM curEmails INTO @UserID
		
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @EMail = ''
	SET @UserName = ''
	SET @Login = ''
	SET @Password = ''
	SET @Subject = ''
	SET @Body = ''

	SELECT @UserName = UserName, @Login = [Login], @Password = [Password], @EMail = EMail
	FROM Users
	WHERE ID = @UserID

	IF @EMail <> ''
	BEGIN
	
		SET @Subject = 'Calculated Deficits Data Available'

		SET @Body = '<html><head></head>' 
					+ '<body>'
					+ '<p>New Calculated Deficit (CD) reporting for ' + @CompanyName + ' is now available.</p>'
					+ '<p>Please use the link below to access your data</p>'
					+ '<p>http://bms.brulines.com</p>'
					+ '<p>Your login details are - Username: ' + @UserName + ' Password: ' + @Password + '</p>'
					+ '<p>If you have any queries with this data please contact your Account Controller, ' + ISNULL(@AccountController, '') + '</p>'
					+ '</body></html>'

		EXEC dbo.SendEmail  '', '', @EMail, @Subject, @Body, '', NULL, @AccountControllerEmail
	
	END
	
	FETCH NEXT FROM curEmails INTO @UserID
	
END

CLOSE curEmails
DEALLOCATE curEmails

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GenerateAndSendCDEmailAlert] TO PUBLIC
    AS [dbo];

