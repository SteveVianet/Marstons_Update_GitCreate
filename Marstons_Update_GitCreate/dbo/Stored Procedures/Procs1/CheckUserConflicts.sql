
CREATE PROCEDURE [dbo].[CheckUserConflicts]
(
	@UserID	INT
)
AS

SELECT SLDatabases.CompanyName FROM [SQL1\SQL1].ServiceLogger.dbo.WebSiteUsers AS SLUsers
JOIN [SQL1\SQL1].ServiceLogger.dbo.EDISDatabases AS SLDatabases ON SLDatabases.ID = SLUsers.DatabaseID
WHERE SLDatabases.Name <> DB_NAME()
AND [Login] IN (SELECT [Login] FROM Users WHERE ID = @UserID)
AND [Password] IN (SELECT [Password] FROM Users WHERE ID = @UserID)
