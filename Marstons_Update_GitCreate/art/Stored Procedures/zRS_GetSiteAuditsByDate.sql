CREATE PROCEDURE [art].[zRS_GetSiteAuditsByDate]
(
	@From		DATETIME,
	@To			DATETIME
)
AS

/* Get current site count, not including BMS, Closed, Hidden or Second Systems */
DECLARE @SiteCount TABLE 
(
OwnerName VARCHAR(50),
SiteCount INT
)

INSERT INTO @SiteCount

SELECT o.Name,
	COUNT(s.SiteID) CurrentSiteCount

FROM Sites s 
	INNER JOIN		[Owners] o ON o.ID = s.OwnerID
	LEFT JOIN		[SiteGroupSites] sgs ON sgs.EDISID = s.EDISID
	LEFT JOIN		[SiteGroups] sg ON sg.ID = sgs.SiteGroupID
	LEFT JOIN		[SiteGroupTypes] sgt ON sgt.ID = sg.TypeID

WHERE s.Hidden = 0 AND s.SiteClosed = 0 AND  s.Quality = 1 AND
/* Ensure only primary systems are counted from sites assigned "Multiple Cellar" */
	((sgt.Description = 'Multiple Cellar' OR sgt.Description IS NULL) AND (sgs.IsPrimary = 1 OR sgs.IsPrimary IS NULL))

GROUP BY
o.Name

/* Get Total Audits By Owner Name and Date (Distinct daily audits) */
SELECT
  DB_NAME() DatabaseName,
  o.Name CompanyName,
  sc.SiteCount,
  CAST(sa.TimeStamp AS DATE) AS Date,
  COUNT(DISTINCT(SiteID)) AS AuditCount 

  FROM			[Sites] AS s 
  INNER JOIN	[Owners] AS o ON o.ID = s.OwnerID
  INNER JOIN	[SiteAudits] AS sa ON sa.EDISID = s.EDISID
  JOIN @SiteCount sc ON sc.OwnerName = o.Name
  WHERE
  sa.AuditType = 10  AND 
  CAST(sa.TimeStamp AS DATE) BETWEEN @From AND @To
  GROUP BY
  o.Name,
  sc.SiteCount,
  CAST(sa.TimeStamp AS DATE)
GO
GRANT EXECUTE
    ON OBJECT::[art].[zRS_GetSiteAuditsByDate] TO PUBLIC
    AS [dbo];

