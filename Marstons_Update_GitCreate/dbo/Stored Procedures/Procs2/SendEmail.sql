
CREATE PROCEDURE [dbo].[SendEmail]
(
	@EmailFrom		VARCHAR(255),
	@EmailFromName	VARCHAR(255),
	@EmailTo		VARCHAR(1000),
	@EmailSubject	VARCHAR(1000),
	@EmailBody		VARCHAR(8000),
	@EmailCCList	VARCHAR(1000) = NULL,
	@ProfileName	VARCHAR(100) = NULL,
	@ReplyTo		VARCHAR(1000) = NULL,
	@EmailBCCList	VARCHAR(1000) = NULL

)
AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.SendAutoEmail @EmailFrom, @EmailFromName, @EmailTo, @EmailSubject, @EmailBody, @EmailCCList, @ProfileName, @ReplyTo, @EmailBCCList

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SendEmail] TO PUBLIC
    AS [dbo];

