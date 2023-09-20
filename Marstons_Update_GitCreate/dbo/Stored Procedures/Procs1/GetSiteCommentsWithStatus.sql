CREATE PROCEDURE [dbo].[GetSiteCommentsWithStatus] 
	@EDISID int
AS
BEGIN
	SET NOCOUNT ON;

    SELECT	comm.[Date] AS CommentDate,
			comm.[Description] AS Heading,
			comm.[Text] AS Comment,
			rag.Name AS [Status]
FROM (SELECT [Date], [Text], [Description], EDISID FROM SiteComments
	JOIN SiteCommentHeadingTypes ON SiteCommentHeadingTypes.ID = SiteComments.HeadingType) comm
	JOIN (SELECT srt.Name, sr.EDISID, sr.ValidFrom, sr.ValidTo FROM SiteRankingTypes srt INNER JOIN SiteRankings sr ON srt.ID = sr.RankingTypeID) rag
	ON rag.EDISID = comm.EDISID
WHERE comm.EDISID = @EDISID AND comm.[Date] BETWEEN rag.ValidFrom AND rag.ValidTo
ORDER BY [Date] DESC
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteCommentsWithStatus] TO PUBLIC
    AS [dbo];

