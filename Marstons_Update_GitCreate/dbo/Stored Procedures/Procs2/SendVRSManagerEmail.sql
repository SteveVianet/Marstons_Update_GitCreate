CREATE PROCEDURE SendVRSManagerEmail
(
	@EDISID	INT
)

AS

DECLARE @EmailAddress		VARCHAR(255)
DECLARE @UserName		VARCHAR(255)
DECLARE @SiteID			VARCHAR(50)
DECLARE @SiteName		VARCHAR(60)
DECLARE @SiteAddress1		VARCHAR(50)
DECLARE @SiteAddress2		VARCHAR(50)
DECLARE @SiteAddress3		VARCHAR(50)
DECLARE @SiteAddress4		VARCHAR(50)
DECLARE @SiteTown		VARCHAR(50)
DECLARE @MessageSubject		VARCHAR(255)
DECLARE @MessageBody		VARCHAR(8000)
DECLARE @Recipients		VARCHAR(255)
DECLARE @ReturnCode		INT
DECLARE @Auditor		VARCHAR(255)
DECLARE @AuditorName		VARCHAR(255)

-- Get VRS Manager Name
SELECT @UserName = PropertyValue
FROM Configuration
WHERE PropertyName = 'VRSManagerName'

-- Get VRS Manager E-Mail Address
SELECT @EmailAddress = PropertyValue
FROM Configuration
WHERE PropertyName = 'VRSManagerEMail'

-- Get site details
SELECT	@SiteID = ISNULL(SiteID, ''),
	@SiteName = ISNULL([Name], ''),
	@SiteAddress1 = ISNULL(Address1, ''),
	@SiteAddress2 = ISNULL(Address2, ''),
	@SiteAddress3 = ISNULL(Address3, ''),
	@SiteAddress4 = ISNULL(Address4, '')
FROM Sites
WHERE EDISID = @EDISID

-- Validation - user details
IF @EmailAddress IS NULL
	RETURN -1
IF @EmailAddress = ''
	RETURN -2

-- Validation - site details
IF @SiteID IS NULL
	RETURN -3
IF @SiteID = ''
	RETURN -4

-- Calculate site town
IF @SiteAddress4 <> ''
	SET @SiteTown = @SiteAddress4
ELSE IF @SiteAddress3 <> ''
	SET @SiteTown = @SiteAddress3
ELSE IF @SiteAddress2 <> ''
	SET @SiteTown = @SiteAddress2
ELSE
	SET @SiteTown = @SiteAddress1

-- Generate the e-mail subject
SET @MessageSubject = 'Brulines Volume Recovery Scheme - BDM Actioned'

-- Generate the e-mail body

SET @MessageBody = '<HTML><BODY><FONT FACE="Arial" SIZE="2">BDM has actioned file note<HR>'
SET @MessageBody = @MessageBody + '<FONT SIZE="5" COLOR="Black" BGCOLOR="Gold"><I>Site Details</I></FONT>'
SET @MessageBody = @MessageBody + '<P><B>Site ID:</B> '
SET @MessageBody = @MessageBody + @SiteID
SET @MessageBody = @MessageBody + '<P><B>Site Name:</B> '
SET @MessageBody = @MessageBody + @SiteName
SET @MessageBody = @MessageBody + '<P><B>Site Town:</B> '
SET @MessageBody = @MessageBody + @SiteTown
SET @MessageBody = @MessageBody + '<HR>To see further details of this change, visit the <B><I>Brulines</I></B> website at <A HREF="http://www.brulines.com">http://www.brulines.com</A> and log in with your usual Brulines website username and password.<P><FONT SIZE="1"><I>This is an automatically generated message.</I></FONT></FONT></BODY></HTML>'

-- Generate the destination address
IF @UserName = ''
	SET @Recipients = @EmailAddress
ELSE
	SET @Recipients = @UserName + ' <' + @EmailAddress + '>'

-- Attempt to get the name & e-mail of the auditor from the site record
IF (SELECT COUNT(*) FROM Configuration WHERE PropertyName = 'Restrict Sites By User' AND PropertyValue = 1) > 0
BEGIN
	SELECT @Auditor = REPLACE(LOWER(SiteUser), 'maingroup\', '')
	FROM Sites
	WHERE EDISID = @EDISID

	IF @Auditor <> ''
	BEGIN
		SET @Auditor = @Auditor + '@brulines.co.uk'
	END
END

-- Attempt to get the name & e-mail of the auditor from the configuration table
IF @Auditor = ''
BEGIN
	SELECT @Auditor = PropertyValue FROM Configuration WHERE PropertyName = 'AuditorEMail'
	SELECT @AuditorName = PropertyValue FROM Configuration WHERE PropertyName = 'AuditorName'
	IF @AuditorName IS NULL OR @AuditorName = ''
		SET @Auditor = 'Auditor <' + @Auditor + '>'
	ELSE
		SET @Auditor = @AuditorName + ' <' + @Auditor + '>'
END

-- Add auditor to recipients
IF @Auditor <> ''
	SET @Recipients = @Recipients + ', ' + @Auditor

-- Send e-mail
EXEC [SQL1\SQL1].ServiceLogger.dbo.SendAutoEmail 'brulinesvrs@brulines.co.uk', 'Brulines VRS', @Recipients, @MessageSubject, @MessageBody

/*
IF @@VERSION LIKE 'Microsoft SQL Server 2008%'
BEGIN
	EXEC msdb.dbo.sp_send_dbmail
	@profile_name = 'BrulinesAuto',
	@recipients = @Recipients,
	@subject = @MessageSubject,
	@body = @MessageBody,
	@body_format = 'HTML'
	
END
ELSE
BEGIN
	EXEC @ReturnCode = master..xp_smtp_sendmail
				@FROM	= N'brulinesvrs@brulines.co.uk',
				@FROM_NAME	= N'Brulines VRS',
				@TO		= @Recipients,
				@subject	= @MessageSubject,
				@message	= @MessageBody,
				@type		= 'text/html',
				@server	= '192.168.1.10',
				@port		= 2500
END
*/

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SendVRSManagerEmail] TO PUBLIC
    AS [dbo];

