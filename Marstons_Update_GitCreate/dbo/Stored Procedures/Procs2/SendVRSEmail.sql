CREATE PROCEDURE SendVRSEmail
(
	@EDISID	INT,
	@UserID	INT,
	@NoteID	INT
)

AS

DECLARE @EmailAddress		VARCHAR(255)
DECLARE @UserName			VARCHAR(255)
DECLARE @SiteID			VARCHAR(50)
DECLARE @SiteName			VARCHAR(60)
DECLARE @SiteAddress1		VARCHAR(50)
DECLARE @SiteAddress2		VARCHAR(50)
DECLARE @SiteAddress3		VARCHAR(50)
DECLARE @SiteAddress4		VARCHAR(50)
DECLARE @SiteTown			VARCHAR(50)
DECLARE @MessageSubject		VARCHAR(255)
DECLARE @MessageBody		VARCHAR(8000)
DECLARE @Recipients			VARCHAR(255)
DECLARE @ReturnCode		INT
DECLARE @TheVisit			VARCHAR(1000)
DECLARE @Discussions		VARCHAR(1000)
DECLARE @Evidence			VARCHAR(1000)
DECLARE @TradingPatterns		VARCHAR(1000)
DECLARE @FurtherDiscussions		VARCHAR(1000)
DECLARE @BuyingOutLevel		VARCHAR(1000)
DECLARE @CourseOfAction		VARCHAR(1000)
DECLARE @CCList			VARCHAR(1000)
DECLARE @MailType			VARCHAR(10)
DECLARE @UserAcceptsHTMLMail	BIT
DECLARE @Auditor			VARCHAR(255)
DECLARE @AuditorName		VARCHAR(255)

SET @UserAcceptsHTMLMail = 0

-- Get user details
SELECT	@EmailAddress = ISNULL(EMail, ''),
	@UserName = ISNULL(UserName, '')
FROM Users
WHERE [ID] = @UserID

-- Get site details
SELECT	@SiteID = ISNULL(SiteID, ''),
	@SiteName = ISNULL([Name], ''),
	@SiteAddress1 = ISNULL(Address1, ''),
	@SiteAddress2 = ISNULL(Address2, ''),
	@SiteAddress3 = ISNULL(Address3, ''),
	@SiteAddress4 = ISNULL(Address4, '')
FROM Sites
WHERE EDISID = @EDISID

-- Get visit note details
SELECT	@TheVisit = TheVisit,
	@Discussions = Discussions,
	@Evidence = Evidence,
	@TradingPatterns = TradingPatterns,
	@FurtherDiscussions = FurtherDiscussions,
	@BuyingOutLevel = BuyingOutLevel,
	@CourseOfAction = CourseOfAction
FROM SiteNotes
WHERE [ID] = @NoteID

SET @TheVisit = REPLACE(@TheVisit, CHAR(13) + CHAR(10), '<BR>')
SET @Discussions = REPLACE(@Discussions, CHAR(13) + CHAR(10), '<BR>')
SET @Evidence = REPLACE(@Evidence, CHAR(13) + CHAR(10), '<BR>')
SET @TradingPatterns = REPLACE(@TradingPatterns, CHAR(13) + CHAR(10), '<BR>')
SET @FurtherDiscussions = REPLACE(@FurtherDiscussions, CHAR(13) + CHAR(10), '<BR>')
SET @BuyingOutLevel = REPLACE(@BuyingOutLevel, CHAR(13) + CHAR(10), '<BR>')
SET @CourseOfAction = REPLACE(@CourseOfAction, CHAR(13) + CHAR(10), '<BR>')

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

-- Validation - note details
IF @TheVisit IS NULL
	RETURN -5

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
SET @MessageSubject = 'Brulines Volume Recovery Scheme'

-- Generate the e-mail body

IF @UserAcceptsHTMLMail = 1
BEGIN
	SET @MessageBody = '<HTML><BODY ALINK="Gold" VLINK="Gold" BGCOLOR="Black" TEXT="White"><FONT FACE="Arial" SIZE="2"><FONT COLOR="Gold">An action is required at the <B><I>Brulines Volume Recovery Scheme</I></B> website.</FONT><HR><P><CENTER><TABLE BGCOLOR="Goldenrod" WIDTH="80%" BORDERCOLOR="Gold" CELLSPACING="0" BORDERCOLORDARK="Gray" CELLPADDING="0" BGCOLOR="Black" BORDERCOLORLIGHT="Goldenrod" BORDER="2"><TR><TH COLSPAN="2">Site Details</TH><TR><TH ALIGN="Left">Site ID</TH><TD>'
	SET @MessageBody = @MessageBody + @SiteID
	SET @MessageBody = @MessageBody + '</TD></TR><TR><TH ALIGN="Left">Site Name</TH><TD>'
	SET @MessageBody = @MessageBody + @SiteName
	SET @MessageBody = @MessageBody + '</TD></TR><TR><TH ALIGN="Left">Site Town</TH><TD>'
	SET @MessageBody = @MessageBody + @SiteTown
	SET @MessageBody = @MessageBody + '</TD></TR></TABLE><P><TABLE BGCOLOR="Goldenrod" WIDTH="80%" BORDERCOLOR="Gold" CELLSPACING="0" BORDERCOLORDARK="Gray" CELLPADDING="0" BGCOLOR="Black" BORDERCOLORLIGHT="Goldenrod" BORDER="2"><TR><TH COLSPAN="2">Visit Details</TH><TR><TH ALIGN="Left">The Visit</TH><TD>'
	SET @MessageBody = @MessageBody + @TheVisit
	IF LEN(@TheVisit) >= 1000 SET @MessageBody = @MessageBody + ' &lt;truncated&gt;'
	SET @MessageBody = @MessageBody + '</TD></TR><TR><TH ALIGN="Left">Discussions</TH><TD>'
	SET @MessageBody = @MessageBody + @Discussions
	IF LEN(@Discussions) >= 1000 SET @MessageBody = @MessageBody + ' &lt;truncated&gt;'
	SET @MessageBody = @MessageBody + '</TD></TR><TR><TH ALIGN="Left">Evidence</TH><TD>'
	SET @MessageBody = @MessageBody + @Evidence
	IF LEN(@Evidence) >= 1000 SET @MessageBody = @MessageBody + ' &lt;truncated&gt;'
	SET @MessageBody = @MessageBody + '</TD></TR><TR><TH ALIGN="Left">Trading Patterns</TH><TD>'
	SET @MessageBody = @MessageBody + @TradingPatterns
	IF LEN(@TradingPatterns) >= 1000 SET @MessageBody = @MessageBody + ' &lt;truncated&gt;'
	SET @MessageBody = @MessageBody + '</TD></TR><TR><TH ALIGN="Left">Further Discussions</TH><TD>'
	SET @MessageBody = @MessageBody + @FurtherDiscussions
	IF LEN(@FurtherDiscussions) >= 1000 SET @MessageBody = @MessageBody + ' &lt;truncated&gt;'
	SET @MessageBody = @MessageBody + '</TD></TR><TR><TH ALIGN="Left">Buying Out Level</TH><TD>'
	SET @MessageBody = @MessageBody + @BuyingOutLevel
	IF LEN(@BuyingOutLevel) >= 1000 SET @MessageBody = @MessageBody + ' &lt;truncated&gt;'
	SET @MessageBody = @MessageBody + '</TD></TR><TR><TH ALIGN="Left">Course of Action</TH><TD>'
	SET @MessageBody = @MessageBody + @CourseOfAction
	IF LEN(@CourseOfAction) >= 1000 SET @MessageBody = @MessageBody + ' &lt;truncated&gt;'
	SET @MessageBody = @MessageBody + '</TD></TR></TABLE></CENTER><P><HR><FONT COLOR="Gold"><P>To see further details of this change, visit the <B><I>Brulines</I></B> website at <A HREF="http://www.brulines.com">http://www.brulines.com</A> and log in with your usual Brulines website username and password.<P>This is an automatically generated message.</FONT></FONT></BODY></HTML>'
END
ELSE
BEGIN
	SET @MessageBody = '<HTML><BODY><FONT FACE="Arial" SIZE="2">An action is required at the <B><I>Brulines Volume Recovery Scheme</I></B> website.<HR>'
	SET @MessageBody = @MessageBody + '<FONT SIZE="5" COLOR="Black" BGCOLOR="Gold"><I>Site Details</I></FONT>'
	SET @MessageBody = @MessageBody + '<P><B>Site ID:</B> '
	SET @MessageBody = @MessageBody + @SiteID
	SET @MessageBody = @MessageBody + '<P><B>Site Name:</B> '
	SET @MessageBody = @MessageBody + @SiteName
	SET @MessageBody = @MessageBody + '<P><B>Site Town:</B> '
	SET @MessageBody = @MessageBody + @SiteTown
	SET @MessageBody = @MessageBody + '<HR><FONT SIZE="5" COLOR="Black" BGCOLOR="Gold"><I>Visit Details</I></FONT>'
	SET @MessageBody = @MessageBody + '<P><B>The Visit:</B> '
	SET @MessageBody = @MessageBody + @TheVisit
	IF LEN(@TheVisit) >= 1000 SET @MessageBody = @MessageBody + ' &lt;truncated&gt;'
	SET @MessageBody = @MessageBody + '<P><B>Discussions:</B> '
	SET @MessageBody = @MessageBody + @Discussions
	IF LEN(@Discussions) >= 1000 SET @MessageBody = @MessageBody + ' &lt;truncated&gt;'
	SET @MessageBody = @MessageBody + '<P><B>Evidence:</B> '
	SET @MessageBody = @MessageBody + @Evidence
	IF LEN(@Evidence) >= 1000 SET @MessageBody = @MessageBody + ' &lt;truncated&gt;'
	SET @MessageBody = @MessageBody + '<P><B>Trading Patterns:</B> '
	SET @MessageBody = @MessageBody + @TradingPatterns
	IF LEN(@TradingPatterns) >= 1000 SET @MessageBody = @MessageBody + ' &lt;truncated&gt;'
	SET @MessageBody = @MessageBody + '<P><B>Further Discussions:</B> '
	SET @MessageBody = @MessageBody + @FurtherDiscussions
	IF LEN(@FurtherDiscussions) >= 1000 SET @MessageBody = @MessageBody + ' &lt;truncated&gt;'
	SET @MessageBody = @MessageBody + '<P><B>Buying Out Level:</B> '
	SET @MessageBody = @MessageBody + @BuyingOutLevel
	IF LEN(@BuyingOutLevel) >= 1000 SET @MessageBody = @MessageBody + ' &lt;truncated&gt;'
	SET @MessageBody = @MessageBody + '<P><B>Course Of Action:</B> '
	SET @MessageBody = @MessageBody + @CourseOfAction
	IF LEN(@CourseOfAction) >= 1000 SET @MessageBody = @MessageBody + ' &lt;truncated&gt;'
	SET @MessageBody = @MessageBody + '<HR>To see further details of this change, visit the <B><I>Brulines</I></B> website at <A HREF="http://www.brulines.com">http://www.brulines.com</A> and log in with your usual Brulines website username and password.<P><FONT SIZE="1"><I>This is an automatically generated message.</I></FONT></FONT></BODY></HTML>'
END

-- Generate the destination address for the passed in user
IF @UserName = ''
	SET @Recipients = @EmailAddress
ELSE
	SET @Recipients = @UserName + ' <' + @EmailAddress + '>'

SET @Auditor = ''

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
IF @Auditor = 'NOBODY'
BEGIN
	SET @Auditor = ''
END
ELSE
BEGIN
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

END

	
-- Generate the CC list
SET @CCList = ''

DECLARE @CCAddress	VARCHAR(255)

DECLARE CCListCursor	CURSOR LOCAL STATIC FOR
	SELECT [Name] + ' <' + Address + '>'
	FROM CCAddresses

OPEN CCListCursor


FETCH NEXT FROM CCListCursor INTO @CCAddress

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @CCList = @CCList + @CCAddress + ', '

	FETCH NEXT FROM CCListCursor INTO @CCAddress

END

CLOSE CCListCursor
DEALLOCATE CCListCursor

IF LEN(@CCList) > 0
	SET @CCList = LEFT(@CCList, LEN(@CCList) - 1)

-- Send e-mail
EXEC [SQL1\SQL1].ServiceLogger.dbo.SendAutoEmail 'brulinesvrs@brulines.co.uk', 'Brulines VRS', @Recipients, @MessageSubject, @MessageBody, @CCList


/*
IF @@VERSION LIKE 'Microsoft SQL Server 2008%'
BEGIN
	EXEC msdb.dbo.sp_send_dbmail
	@profile_name = 'BrulinesAuto',
	@recipients = @Recipients,
	@copy_recipients = @CCList,
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
				@CC		= @CCList,
				@subject	= @MessageSubject,
				@message	= @MessageBody,
				@type		= 'text/html',
				@server	= '192.168.1.10',
				@port		= 2500
END
*/

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SendVRSEmail] TO PUBLIC
    AS [dbo];

