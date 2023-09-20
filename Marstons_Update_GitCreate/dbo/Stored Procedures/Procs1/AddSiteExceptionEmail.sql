
CREATE PROCEDURE dbo.AddSiteExceptionEmail
(
	@EmailSentTo	VARCHAR(8000),
	@EmailSubject	VARCHAR(MAX),
	@EmailHTML		VARCHAR(MAX),
	@EmailID		INT OUTPUT
)
AS

SET NOCOUNT ON

INSERT INTO SiteExceptionEmails
(EmailSentTo, EmailDate, EmailSubject, Acknowledged, EmailContent)
VALUES
(@EmailSentTo, NULL, @EmailSubject, 0, @EmailHTML)

SET @EmailID = @@IDENTITY

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSiteExceptionEmail] TO PUBLIC
    AS [dbo];

