CREATE PROCEDURE [dbo].[GetSiteComments]
(
	@EDISID	INT,
	@Type		INT = NULL,
	@FromDate	DATETIME = NULL,
	@ToDate	DATETIME = NULL,
	@HeadingType	INT = NULL
)

AS

SELECT	sc.[ID],
	[Date],
	[Type],
	[HeadingType],
	scht.Description AS Header,
	[Text],
	[AddedOn],
	[AddedBy],
	0 AS [Deleted],
	[EditedOn],
	[EditedBy], 
	RAGStatus
FROM dbo.SiteComments AS sc
	JOIN SiteCommentHeadingTypes AS scht ON scht.ID = sc.HeadingType
WHERE EDISID = @EDISID
AND ((@Type IS NULL) OR (Type = @Type))
AND ( (@FromDate IS NULL AND @ToDate IS NULL) OR ([Date] BETWEEN @FromDate AND @ToDate))
AND ( @HeadingType IS NULL OR HeadingType = @HeadingType)
ORDER BY [Date] DESC, ID DESC, HeadingType
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteComments] TO PUBLIC
    AS [dbo];

