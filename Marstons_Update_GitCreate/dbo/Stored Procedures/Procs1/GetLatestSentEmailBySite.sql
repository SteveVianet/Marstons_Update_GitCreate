
CREATE PROCEDURE [dbo].[GetLatestSentEmailBySite]
(
	@EDISID		INT = NULL
)
AS

SET NOCOUNT ON;

--SELECT TOP 1 see.EmailDate, (s.Name + ', ' + s.Address1 + ', ' + s.Address3) AS SiteDescription, 'Exception' AS [Type], se.EDISID AS EDISID, see.EmailContent
--FROM SiteExceptions se
--INNER JOIN SiteExceptionEmails see ON see.ID = se.ExceptionEmailID
--INNER JOIN Sites s ON s.EDISID = se.EDISID
--WHERE se.ExceptionEmailID IS NOT NULL
--	AND se.EDISID = @EDISID
--	AND see.EmailDate IS NOT NULL
--ORDER BY see.EmailDate DESC

SELECT	SiteExceptionEmails.EmailDate, 
		(Sites.Name + ', ' + Sites.Address1 + ', ' + Sites.Address3) AS SiteDescription, 
		CASE WHEN SiteExceptions.[Type] = 'Weekly Site Report' THEN 'Report' ELSE 'Exception' END AS [Type], 
		SiteExceptions.EDISID AS EDISID, 
		SiteExceptionEmails.EmailContent
FROM SiteExceptionEmails
JOIN SiteExceptions ON SiteExceptions.ExceptionEmailID = SiteExceptionEmails.ID
JOIN
(
	SELECT EDISID, MAX(EmailDate) AS LastEmailDate
	FROM SiteExceptionEmails
	JOIN SiteExceptions ON SiteExceptions.ExceptionEmailID = SiteExceptionEmails.ID
	GROUP BY EDISID
) AS LastSiteExceptionEmails ON LastSiteExceptionEmails.EDISID = SiteExceptions.EDISID
AND LastSiteExceptionEmails.LastEmailDate = SiteExceptionEmails.EmailDate
JOIN Sites ON Sites.EDISID = SiteExceptions.EDISID
WHERE (Sites.EDISID = @EDISID OR @EDISID IS NULL)
GROUP BY SiteExceptionEmails.EmailDate, 
		(Sites.Name + ', ' + Sites.Address1 + ', ' + Sites.Address3), 
		CASE WHEN SiteExceptions.[Type] = 'Weekly Site Report' THEN 'Report' ELSE 'Exception' END, 
		SiteExceptions.EDISID, 
		SiteExceptionEmails.EmailContent
ORDER BY SiteExceptionEmails.EmailDate DESC

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetLatestSentEmailBySite] TO PUBLIC
    AS [dbo];

