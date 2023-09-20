﻿CREATE PROCEDURE [dbo].[GetWebSiteTillYieldSummary]
(
	@EDISID			INT,
	@IncludeKegs	BIT,
	@IncludeCasks	BIT
)
AS

SELECT	Product,
		[Percent],
		Sold,
		CashValue,
		RetailDispensed
FROM WebSiteTLTillYield
JOIN SiteRankingCurrent ON SiteRankingCurrent.EDISID = WebSiteTLTillYield.EDISID
WHERE WebSiteTLTillYield.EDISID = @EDISID
AND ((IsCask = 1 AND @IncludeCasks = 1)
OR (IsCask = 0 AND @IncludeKegs = 1))
AND LastUpdated >= DATEADD(DAY, -1, CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME))

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteTillYieldSummary] TO PUBLIC
    AS [dbo];

