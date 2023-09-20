CREATE PROCEDURE [dbo].[GenerateScorecardEmails]
AS

SET NOCOUNT ON

DECLARE @ScorecardID INT

DECLARE curDatabases CURSOR FORWARD_ONLY READ_ONLY FOR
SELECT ID
FROM SiteScorecardEmails
WHERE Processed = 0

OPEN curDatabases
FETCH NEXT FROM curDatabases INTO @ScorecardID

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC dbo.GenerateAndSendSiteScorecardEmail @ScorecardID
	
	FETCH NEXT FROM curDatabases INTO @ScorecardID
END

CLOSE curDatabases
DEALLOCATE curDatabases

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GenerateScorecardEmails] TO PUBLIC
    AS [dbo];

