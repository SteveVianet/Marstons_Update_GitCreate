CREATE PROCEDURE [art].[zRS_GetSiteAuditsByDateTimeUS]
(
	@From		DATETIME,
	@Weeks		INT
)
AS

  SELECT TOP 100 
  o.Name,
  s.SiteID,
  s.Name,
  REPLACE(REPLACE(sa.UserName,'.', ' '),'MAINGROUP\', '') AS AuditorName,
  CAST(sa.TimeStamp AS DATE) AS Date,
  COUNT(sa.TimeStamp) AS DailyAuditCount
  
  FROM Sites AS s 
  INNER JOIN SiteProperties AS sp ON sp.EDISID = s.EDISID 
  INNER JOIN Properties AS p ON p.ID = sp.PropertyID
  INNER JOIN Owners AS o ON o.ID = s.OwnerID
  INNER JOIN SiteAudits AS sa ON sa.EDISID = s.EDISID

  WHERE 
  sp.Value = 'en-US'
  AND
  sa.AuditType = 10
  AND 
  CAST(sa.TimeStamp AS DATE) BETWEEN @From AND DATEADD(wk,@Weeks,@From)
  GROUP BY 
  o.Name,
  s.SiteID,
  s.Name,
  sa.UserName,
  CAST(sa.TimeStamp AS DATE)
GO
GRANT EXECUTE
    ON OBJECT::[art].[zRS_GetSiteAuditsByDateTimeUS] TO PUBLIC
    AS [dbo];

