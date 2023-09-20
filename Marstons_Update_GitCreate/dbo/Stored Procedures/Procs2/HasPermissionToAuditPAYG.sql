CREATE PROCEDURE dbo.HasPermissionToAuditPAYG 
(
	@LoginName	VARCHAR(50)
)
AS
EXEC [SQL1\SQL1].ServiceLogger.dbo.HasPermissionToAuditPAYG @LoginName
	

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[HasPermissionToAuditPAYG] TO PUBLIC
    AS [dbo];

