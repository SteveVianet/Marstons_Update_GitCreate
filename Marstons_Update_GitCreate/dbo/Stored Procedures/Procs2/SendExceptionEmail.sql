
CREATE PROCEDURE [dbo].[SendExceptionEmail]
	@ExceptionEmailID	INT,
	@EmailReplyTo		VARCHAR(50) = NULL
AS

DECLARE @EmailContent	VARCHAR(MAX)
DECLARE @EmailSubject	VARCHAR(MAX)
DECLARE @EmailSentTo	VARCHAR(8000)

SELECT @EmailContent = EmailContent, @EmailSubject = EmailSubject, @EmailSentTo = EmailSentTo
FROM SiteExceptionEmails
WHERE ID = @ExceptionEmailID

EXEC [SQL1\SQL1].ServiceLogger.dbo.SendAutoEmail '', '', @EmailSentTo, @EmailSubject, @EmailContent, NULL, 'IDraughtExceptions', @EmailReplyTo

UPDATE SiteExceptionEmails 
SET EmailDate = GETDATE()
WHERE ID = @ExceptionEmailID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SendExceptionEmail] TO PUBLIC
    AS [dbo];

