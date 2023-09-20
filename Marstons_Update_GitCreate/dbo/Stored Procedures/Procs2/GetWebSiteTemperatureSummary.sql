CREATE PROCEDURE [dbo].[GetWebSiteTemperatureSummary]
(
	@EDISID			INT,
	@IncludeKegs	BIT,
	@IncludeCasks	BIT
)
AS

SELECT	Pump,
		Product,
		Specification,
		Tolerance,
		Location,
		AcceptableQuantity,
		PoorQuantity
FROM WebSiteTLTemperature
JOIN SiteRankingCurrent ON SiteRankingCurrent.EDISID = WebSiteTLTemperature.EDISID
WHERE WebSiteTLTemperature.EDISID = @EDISID
AND ((IsCask = 1 AND @IncludeCasks = 1)
OR (IsCask = 0 AND @IncludeKegs = 1))
AND LastUpdated >= DATEADD(DAY, -1, CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME))

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteTemperatureSummary] TO PUBLIC
    AS [dbo];

