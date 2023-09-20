CREATE PROCEDURE [dbo].[GetAutomaticEmailRecipients]

AS
BEGIN

	SET NOCOUNT ON;
	
	SELECT ID, UserName, Login, Password, UserType, EMail
	FROM Users
	WHERE (LTRIM(EMail) <> '' AND EMail <> '(None)')
	AND UserType IN (2) AND WebActive = 1 AND Deleted = 0 AND Anonymise = 0

END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAutomaticEmailRecipients] TO PUBLIC
    AS [dbo];

