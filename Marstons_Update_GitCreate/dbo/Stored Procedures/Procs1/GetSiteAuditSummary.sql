CREATE PROCEDURE [dbo].[GetSiteAuditSummary]
(
	@From		DATETIME,
	@To		DATETIME
)

AS

SELECT 	UPPER(UserName) AS UserName, 
	CAST(CONVERT(VARCHAR(10), [TimeStamp], 121) AS SMALLDATETIME) AS [Date],
	COUNT(*) AS AuditCount,
	Configuration.PropertyValue AS CompanyName
FROM SiteAudits
JOIN Configuration ON Configuration.PropertyName = 'Company Name'
WHERE [TimeStamp] BETWEEN @From AND @To
AND AuditType IN (1,10)
GROUP BY Configuration.PropertyValue, UPPER(UserName), CAST(CONVERT(VARCHAR(10), [TimeStamp], 121) AS SMALLDATETIME)
ORDER BY Configuration.PropertyValue, UPPER(UserName), CAST(CONVERT(VARCHAR(10), [TimeStamp], 121) AS SMALLDATETIME)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteAuditSummary] TO PUBLIC
    AS [dbo];


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteAuditSummary] TO [TeamLeader]
    AS [dbo];

