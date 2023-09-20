CREATE PROCEDURE [dbo].[GetSiteAudits]
(
	@EDISID		INT
)

AS

SELECT	UserName,
	[TimeStamp],
	Comment,
	AuditType
FROM dbo.SiteAudits
WHERE EDISID = @EDISID
ORDER BY [TimeStamp]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteAudits] TO PUBLIC
    AS [dbo];

