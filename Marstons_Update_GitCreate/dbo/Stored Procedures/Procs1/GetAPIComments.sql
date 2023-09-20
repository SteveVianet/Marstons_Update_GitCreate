
CREATE PROCEDURE [dbo].[GetAPIComments]
(
	@SiteID		VARCHAR(15),
	@From		DATE,
	@To			DATE
)
AS

SELECT	Sites.SiteID,
		SiteComments.[Date] AS CommentDate,
		SiteCommentHeadingTypes.[Description] AS CommentType,
		SiteComments.[Text] AS CommentText
FROM SiteComments
	JOIN SiteCommentHeadingTypes ON SiteCommentHeadingTypes.ID = SiteComments.HeadingType
	JOIN Sites ON Sites.EDISID = SiteComments.EDISID
WHERE Sites.SiteID = @SiteID
	AND SiteComments.[Type] = 1
	AND [Date] BETWEEN @From AND @To
	

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAPIComments] TO PUBLIC
    AS [dbo];

