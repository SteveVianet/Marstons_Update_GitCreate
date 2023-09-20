CREATE PROCEDURE [dbo].[GetAllSiteAudits]
(
	@From		DATETIME,
	@To		DATETIME
)

AS

SELECT 	EDISID,
	UserName,
	[TimeStamp],
	Comment,
	AuditType
FROM SiteAudits
WHERE [TimeStamp] BETWEEN @From AND @To
ORDER BY [TimeStamp], EDISID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAllSiteAudits] TO PUBLIC
    AS [dbo];


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAllSiteAudits] TO [TeamLeader]
    AS [dbo];

