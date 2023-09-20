CREATE PROCEDURE [dbo].[GetLatestSiteRanking]
(
	@EDISID	INT,
	@ValidTo DATETIME
)

AS

SET @ValidTo = CAST(CONVERT(VARCHAR(10), @ValidTo, 20) AS SMALLDATETIME)

SELECT TOP 1
ValidFrom,
ValidTo,
RankingTypeID

FROM dbo.SiteRankings
WHERE EDISID = @EDISID	
	AND ValidTo <= @ValidTo
order by ValidFrom desc
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetLatestSiteRanking] TO PUBLIC
    AS [dbo];

