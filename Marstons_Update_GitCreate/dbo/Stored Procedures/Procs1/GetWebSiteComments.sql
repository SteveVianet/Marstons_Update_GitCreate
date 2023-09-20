CREATE PROCEDURE [dbo].[GetWebSiteComments]
(
	@EDISID	INT,
	@From	DATETIME,
	@Type	INT = 1
)

AS

SELECT TOP 6 [Date], SiteCommentHeadingTypes.[Description] AS [Heading], [Text] AS Comment
FROM SiteComments 
JOIN SiteCommentHeadingTypes 
  ON SiteCommentHeadingTypes.ID = SiteComments.HeadingType
WHERE [Type] = @Type
  AND EDISID = @EDISID
  AND [Date] BETWEEN @From AND GETDATE()
ORDER BY [Date] DESC
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteComments] TO PUBLIC
    AS [dbo];

