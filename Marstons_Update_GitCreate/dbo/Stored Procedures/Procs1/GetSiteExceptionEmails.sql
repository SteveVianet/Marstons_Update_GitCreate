
CREATE PROCEDURE [dbo].[GetSiteExceptionEmails]
(
	@ID			INT = NULL,
	@EDISID		INT = NULL,
	@From		DATE = NULL,
	@To			DATE = NULL
)
AS

SET NOCOUNT ON;

SELECT	SiteExceptionEmails.ID,
		SiteExceptionEmails.EmailDate, 
		(Sites.Name + ', ' + Sites.Address1 + ', ' + Sites.Address3) AS SiteDescription, 
		CASE WHEN SiteExceptions.[Type] = 'Weekly Site Report' THEN 'Report' ELSE 'Exception' END AS [Type], 
		SiteExceptions.EDISID AS EDISID, 
		SiteExceptionEmails.EmailContent
FROM SiteExceptionEmails
JOIN SiteExceptions ON SiteExceptions.ExceptionEmailID = SiteExceptionEmails.ID
JOIN
(
	SELECT EDISID, EmailDate AS LastEmailDate
	FROM SiteExceptionEmails
	JOIN SiteExceptions ON SiteExceptions.ExceptionEmailID = SiteExceptionEmails.ID
	--GROUP BY EDISID
) AS LastSiteExceptionEmails ON LastSiteExceptionEmails.EDISID = SiteExceptions.EDISID
AND LastSiteExceptionEmails.LastEmailDate = SiteExceptionEmails.EmailDate
JOIN Sites ON Sites.EDISID = SiteExceptions.EDISID
WHERE (SiteExceptionEmails.ID = @ID OR @ID IS NULL) 
AND (Sites.EDISID = @EDISID OR @EDISID IS NULL)
AND ((CAST(SiteExceptionEmails.EmailDate AS DATE) BETWEEN @From AND @To) OR (@From IS NULL AND @To IS NULL))
GROUP BY SiteExceptionEmails.ID,
		SiteExceptionEmails.EmailDate, 
		(Sites.Name + ', ' + Sites.Address1 + ', ' + Sites.Address3), 
		CASE WHEN SiteExceptions.[Type] = 'Weekly Site Report' THEN 'Report' ELSE 'Exception' END, 
		SiteExceptions.EDISID, 
		SiteExceptionEmails.EmailContent
ORDER BY SiteExceptionEmails.EmailDate DESC

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteExceptionEmails] TO PUBLIC
    AS [dbo];

