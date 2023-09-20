CREATE PROCEDURE [dbo].[HasPermissionToShowAllSites] 
(
	@LoginName	VARCHAR(50)
)
AS
BEGIN
	EXEC [SQL1\SQL1].ServiceLogger.dbo.HasPermissionToShowAllSites @LoginName
	
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[HasPermissionToShowAllSites] TO PUBLIC
    AS [dbo];

