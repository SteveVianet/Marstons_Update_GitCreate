CREATE PROCEDURE [dbo].[GetLastSiteAudit]
(
	@EDISID	INT,
	@LastAudit	DATETIME OUTPUT,
	@AuditType INT = 1
)

AS

SET @LastAudit = 
	(SELECT MAX(TimeStamp) 
	FROM SiteAudits 
	WHERE EDISID = @EDISID AND AuditType = @AuditType)
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetLastSiteAudit] TO PUBLIC
    AS [dbo];

