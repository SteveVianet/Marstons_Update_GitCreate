CREATE PROCEDURE dbo.GetDisposedSitesForTransfer
AS

SELECT DisposedStatus.EDISID
FROM Sites
JOIN (
	SELECT EDISID, Value
	FROM SiteProperties
	JOIN Properties ON Properties.[ID] = SiteProperties.PropertyID
	WHERE Properties.[Name] = 'Disposed Status'
	AND SiteProperties.[Value] = 'Yes'
) AS DisposedStatus ON DisposedStatus.EDISID = Sites.EDISID
FULL JOIN (
	SELECT EDISID, Value
	FROM SiteProperties
	JOIN Properties ON Properties.[ID] = SiteProperties.PropertyID
	WHERE Properties.[Name] = 'Disposed Site Completed'
) AS DisposedCompleted ON DisposedCompleted.EDISID = Sites.EDISID
WHERE DisposedCompleted.[Value] IS NULL

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDisposedSitesForTransfer] TO PUBLIC
    AS [dbo];

