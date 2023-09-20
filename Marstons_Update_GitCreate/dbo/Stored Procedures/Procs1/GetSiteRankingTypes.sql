
CREATE PROCEDURE dbo.GetSiteRankingTypes

AS

SELECT	[ID],
	Priority,
	Colour,
	[Name],
	ISNULL(SafeDisplayRanking, [ID]) AS SafeDisplayRanking,
	AllowUserSelection,
	ExcelColour
FROM dbo.SiteRankingTypes
ORDER BY Priority

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteRankingTypes] TO PUBLIC
    AS [dbo];

