CREATE PROCEDURE [dbo].[GetWebSitePouringYieldSummary]
(
	@EDISID			INT,
	@IncludeKegs	BIT,
	@IncludeCasks	BIT
)
AS

SELECT	Product,
		CAST([Percent] AS VARCHAR) + '%' AS [Percent],
		IsInErrorThreshold
FROM WebSiteTLPouringYield
JOIN SiteRankingCurrent ON SiteRankingCurrent.EDISID = WebSiteTLPouringYield.EDISID
WHERE WebSiteTLPouringYield.EDISID = @EDISID
AND ((IsCask = 1 AND @IncludeCasks = 1)
OR (IsCask = 0 AND @IncludeKegs = 1))
AND LastUpdated >= DATEADD(DAY, -1, CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME))

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSitePouringYieldSummary] TO PUBLIC
    AS [dbo];

