CREATE PROCEDURE [dbo].[GetAuditProgress]
(
	@From			DATETIME,
	@To			DATETIME
)
AS

SET NOCOUNT ON

DECLARE @MultipleAuditors AS BIT
DECLARE @EntireCustomerAuditor AS VARCHAR(255)
DECLARE @ToNextDay DATETIME

SET @ToNextDay = DATEADD(DAY, 1, @To)

SELECT @MultipleAuditors = MultipleAuditors
FROM [SQL1\SQL1].ServiceLogger.dbo.EDISDatabases 
WHERE Name = DB_NAME()

IF @MultipleAuditors = 0
BEGIN
	SELECT @EntireCustomerAuditor = 'MAINGROUP\' + REPLACE(REPLACE(UPPER(PropertyValue), '@BRULINES.COM', ''), '@BRULINES.CO.UK', '')
	FROM Configuration
	WHERE PropertyName = 'AuditorEMail'
END
ELSE
BEGIN
	SET @EntireCustomerAuditor = NULL
END

SELECT  Configuration.PropertyValue AS CompanyName,
	ISNULL(@EntireCustomerAuditor, UPPER(SiteUser)) AS Auditor,
	COUNT(*) AS NumberOfSites,
	SUM(CASE WHEN LastAudits.Audited IS NULL THEN 0 ELSE 1 END) AS SitesAudited,
	SUM(CASE WHEN LastAudits.Audited IS NULL THEN 1 ELSE 0 END) AS SitesUnaudited
FROM Sites
LEFT JOIN (
	SELECT SiteAudits.EDISID, MAX(TimeStamp) AS Audited
	FROM SiteAudits
	JOIN Sites ON Sites.EDISID = SiteAudits.EDISID
	WHERE SiteAudits.TimeStamp BETWEEN @From AND @ToNextDay
	GROUP BY SiteAudits.EDISID
) AS LastAudits ON LastAudits.EDISID = Sites.EDISID
JOIN Configuration ON Configuration.PropertyName = 'Company Name'
WHERE Hidden = 0
GROUP BY Configuration.PropertyValue, ISNULL(@EntireCustomerAuditor, UPPER(SiteUser))

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAuditProgress] TO PUBLIC
    AS [dbo];

