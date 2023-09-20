CREATE PROCEDURE dbo.GetChangeOfTenancies
(
	@From		DATETIME,
	@To			DATETIME
)
AS

SELECT	SiteComments.ID,
		SiteComments.EDISID,
		Sites.SiteID,
		SiteComments.[Date],
		SiteComments.[Text]
FROM SiteComments
JOIN Sites ON Sites.EDISID = SiteComments.EDISID
WHERE HeadingType IN (16, 3004)
AND [Date] BETWEEN @From AND @To
AND Deleted = 0
ORDER BY [Date] DESC

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetChangeOfTenancies] TO PUBLIC
    AS [dbo];

