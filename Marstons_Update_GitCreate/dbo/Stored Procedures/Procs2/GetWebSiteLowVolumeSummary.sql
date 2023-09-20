CREATE PROCEDURE [dbo].[GetWebSiteLowVolumeSummary]
(
	@EDISID			INT,
	@IncludeKegs	BIT,
	@IncludeCasks	BIT
)
AS

SELECT	Pump,
		Product,
		Category,
		AvgVolumePerWeek,
		TotalCleaningWastage
FROM WebSiteTLThroughput
JOIN SiteRankingCurrent ON SiteRankingCurrent.EDISID = WebSiteTLThroughput.EDISID
WHERE WebSiteTLThroughput.EDISID = @EDISID
AND ((IsCask = 1 AND @IncludeCasks = 1)
OR (IsCask = 0 AND @IncludeKegs = 1))
AND LastUpdated >= DATEADD(DAY, -1, CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME))

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteLowVolumeSummary] TO PUBLIC
    AS [dbo];

