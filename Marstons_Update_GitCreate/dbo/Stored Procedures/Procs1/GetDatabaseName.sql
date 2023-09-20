CREATE PROCEDURE [dbo].[GetDatabaseName]
(
	@DatabaseID		INT
)
AS

SELECT CompanyName As Name
FROM [SQL1\SQL1].ServiceLogger.dbo.EDISDatabases
WHERE ID = @DatabaseID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDatabaseName] TO PUBLIC
    AS [dbo];

