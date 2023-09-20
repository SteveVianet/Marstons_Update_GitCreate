CREATE PROCEDURE dbo.GetAuditsByDate 
(
	@From	DATETIME,
	@To	DATETIME
)
AS

SELECT UserName,
	 [TimeStamp]
FROM SiteAudits
WHERE [TimeStamp] BETWEEN @From AND @To

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAuditsByDate] TO PUBLIC
    AS [dbo];

