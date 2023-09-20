CREATE PROCEDURE [dbo].[GetWebUserManagementPagesReport]
(
	@UserID INT,
	@From DATE,
	@To DATE
)
AS

DECLARE @DatabaseID INT

SELECT @DatabaseID = ID 
FROM [EDISSQL1\SQL1].ServiceLogger.dbo.EDISDatabases
WHERE Name = DB_NAME()

EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.[GetWebStatisticsManagementPagesReport] @DatabaseID, @UserID, @From, @To


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserManagementPagesReport] TO PUBLIC
    AS [dbo];

