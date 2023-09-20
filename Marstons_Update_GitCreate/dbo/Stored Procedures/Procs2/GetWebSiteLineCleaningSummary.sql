

CREATE PROCEDURE [dbo].[GetWebSiteLineCleaningSummary]
(
	@EDISID			INT,
	@IncludeKegs	BIT,
	@IncludeCasks	BIT,
	@OnlyIssues		BIT = 1
)
AS

SELECT	Pump,
		Product,
		Location,
		Volume,
		LastClean
FROM WebSiteTLCleaning
JOIN SiteRankingCurrent ON SiteRankingCurrent.EDISID = WebSiteTLCleaning.EDISID
WHERE WebSiteTLCleaning.EDISID = @EDISID
AND ( (IsCask = 1 AND @IncludeCasks = 1) OR (IsCask = 0 AND @IncludeKegs = 1) )
AND LastUpdated >= DATEADD(DAY, -1, CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME))
AND (WebSiteTLCleaning.Issue = 1 OR @OnlyIssues = 0)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteLineCleaningSummary] TO PUBLIC
    AS [dbo];

