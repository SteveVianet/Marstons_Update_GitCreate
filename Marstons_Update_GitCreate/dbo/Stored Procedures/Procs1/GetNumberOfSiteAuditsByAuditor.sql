CREATE PROCEDURE dbo.GetNumberOfSiteAuditsByAuditor
(
	@From		DATETIME,
	@To		DATETIME
)

AS

SELECT 	UPPER(UserName) AS UserName,
	COUNT(*) AS NumberOfAudits
FROM SiteAudits
WHERE [TimeStamp] BETWEEN @From AND @To
GROUP BY UPPER(UserName)
ORDER BY COUNT(*) DESC

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetNumberOfSiteAuditsByAuditor] TO PUBLIC
    AS [dbo];

