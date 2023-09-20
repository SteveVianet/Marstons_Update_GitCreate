CREATE PROCEDURE [dbo].[GetCDAOverview]
(
	@From		DATETIME,
	@To			DATETIME
)
AS

SET NOCOUNT ON

DECLARE @Sites TABLE(SiteUser VARCHAR(100) NOT NULL, SiteCount INT NOT NULL, DMSSiteCount INT NOT NULL, QualitySiteCount INT NOT NULL)
DECLARE @SiteAuditsDMS TABLE(SiteUser VARCHAR(100) NOT NULL, SitesAuditedCount INT NOT NULL)
DECLARE @SiteAuditsQuality TABLE(SiteUser VARCHAR(100) NOT NULL, SitesAuditedCount INT NOT NULL)
DECLARE @Stocks TABLE(SiteUser VARCHAR(100) NOT NULL, StockDate DATETIME, TotalProductsInStockChecks INT NOT NULL)

DECLARE @DefaultCDA VARCHAR(50)

SELECT @DefaultCDA = UPPER(PropertyValue)
FROM Configuration
WHERE PropertyName = 'AuditorName'

DECLARE @ToNextDay DATETIME

SET @ToNextDay = DATEADD(DAY, 1, @To)

INSERT INTO @Sites
(SiteUser, SiteCount, DMSSiteCount, QualitySiteCount)
SELECT CASE WHEN UPPER(Sites.SiteUser) IS NULL OR UPPER(Sites.SiteUser) = '' THEN @DefaultCDA ELSE UPPER(Sites.SiteUser) END, 
              COUNT(*),
              SUM(CASE WHEN Quality = 0 THEN 1 ELSE 0 END),
              SUM(CASE WHEN Quality = 1 THEN 1 ELSE 0 END)
FROM Sites
WHERE Hidden = 0
GROUP BY CASE WHEN UPPER(Sites.SiteUser) IS NULL OR UPPER(Sites.SiteUser) = '' THEN @DefaultCDA ELSE UPPER(Sites.SiteUser) END

--SELECT * FROM @Sites

-- Pick up any people who have audited sites but are not assigned to that site
INSERT INTO @Sites
(SiteUser, SiteCount, DMSSiteCount, QualitySiteCount)
SELECT DISTINCT UPPER(UserName), 0, 0, 0
FROM SiteAudits
WHERE TimeStamp BETWEEN @From AND @ToNextDay
AND AuditType IN (1,10)
AND UPPER(UserName) NOT IN
(SELECT UPPER(SiteUser) FROM @Sites)

-- Pick up DMS audits (old way)
/*
INSERT INTO @SiteAuditsDMS
(SiteUser, SitesAuditedCount)
SELECT UPPER(UserName), COUNT(DISTINCT EDISID)
FROM SiteAudits
WHERE [TimeStamp] BETWEEN @From AND @ToNextDay
AND AuditType = 1
GROUP BY UserName
*/

-- Pick up DMS audits (crappy new way)
INSERT INTO @SiteAuditsDMS
(SiteUser, SitesAuditedCount)
SELECT UserName, COUNT(*)
FROM (
	SELECT UPPER(UserName) AS UserName, EDISID, CAST(TimeStamp AS DATE) AS Date
	FROM SiteAudits
	WHERE TimeStamp BETWEEN @From AND @ToNextDay AND AuditType = 1
	GROUP BY UPPER(UserName), EDISID, CAST(TimeStamp AS DATE)
) AS x
GROUP BY UserName

--SELECT * FROM @SiteAuditsDMS

-- Pick up iD audits (old way)
/*
INSERT INTO @SiteAuditsQuality
(SiteUser, SitesAuditedCount)
SELECT UPPER(UserName), COUNT(DISTINCT EDISID)
FROM SiteAudits
WHERE [TimeStamp] BETWEEN @From AND @ToNextDay
AND AuditType = 10
GROUP BY UserName
*/

-- Pick up iD audits (crappy new way)
INSERT INTO @SiteAuditsQuality
(SiteUser, SitesAuditedCount)
SELECT UserName, COUNT(*)
FROM (
	SELECT UPPER(UserName) AS UserName, EDISID, CAST(TimeStamp AS DATE) AS Date
	FROM SiteAudits
	WHERE TimeStamp BETWEEN @From AND @ToNextDay AND AuditType = 10
	GROUP BY UPPER(UserName), EDISID, CAST(TimeStamp AS DATE)
) AS x
GROUP BY UserName

--SELECT * FROM @SiteAuditsQuality

INSERT INTO @Stocks
(SiteUser, StockDate, TotalProductsInStockChecks)
SELECT CASE WHEN UPPER(Sites.SiteUser) IS NULL OR LEN(Sites.SiteUser) = 0 THEN @DefaultCDA ELSE UPPER(Sites.SiteUser) END, 
	 MasterDates.[Date],
	 COUNT(*)
FROM Sites
JOIN MasterDates ON MasterDates.EDISID = Sites.EDISID
JOIN Stock ON Stock.MasterDateID = MasterDates.ID
WHERE MasterDates.[Date] BETWEEN @From AND @To
GROUP BY CASE WHEN UPPER(Sites.SiteUser) IS NULL OR LEN(Sites.SiteUser) = 0 THEN @DefaultCDA ELSE UPPER(Sites.SiteUser) END,
	      MasterDates.[Date]

SELECT Sites.SiteUser,
               Configuration.PropertyValue AS Customer,
               Sites.SiteCount,
               ISNULL(SiteAuditsDMS.SitesAuditedCount, 0) AS DMSAudited,
	  Sites.DMSSiteCount - ISNULL(SiteAuditsDMS.SitesAuditedCount, 0) AS DMSUnaudited,
               ISNULL(SiteAuditsQuality.SitesAuditedCount, 0) AS IDraughtAudited,
               Sites.QualitySiteCount - ISNULL(SiteAuditsQuality.SitesAuditedCount, 0) AS IDraughtUnaudited,
               ISNULL(SUM(Stocks.TotalProductsInStockChecks), 0) AS Stocks
FROM @Sites AS Sites
LEFT JOIN @SiteAuditsDMS AS SiteAuditsDMS ON SiteAuditsDMS.SiteUser = Sites.SiteUser
LEFT JOIN @SiteAuditsQuality AS SiteAuditsQuality ON SiteAuditsQuality.SiteUser = Sites.SiteUser
LEFT JOIN @Stocks AS Stocks ON Stocks.SiteUser = Sites.SiteUser
JOIN Configuration ON Configuration.PropertyName = 'Company Name'
GROUP BY Sites.SiteUser,
         Configuration.PropertyValue,
         Sites.SiteCount,
         ISNULL(SiteAuditsDMS.SitesAuditedCount, 0),
	 Sites.DMSSiteCount - ISNULL(SiteAuditsDMS.SitesAuditedCount, 0),
         ISNULL(SiteAuditsQuality.SitesAuditedCount, 0),
         Sites.QualitySiteCount - ISNULL(SiteAuditsQuality.SitesAuditedCount, 0)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCDAOverview] TO PUBLIC
    AS [dbo];

