CREATE PROCEDURE [dbo].[UpdateSiteCommentsWithStatus]
(
	@CommentID	INT,
	@Date		DATETIME,
	@Heading	VARCHAR(1024),
	@Text		VARCHAR(1024),
	@Status		VARCHAR(50)
)

AS
BEGIN
DECLARE @HeadingType	INT

SELECT @HeadingType = ID FROM SiteCommentHeadingTypes WHERE [Description] LIKE SUBSTRING(@Heading, 1, 8) + '%';
IF @HeadingType IS NULL SET @HeadingType = 21;

UPDATE SiteComments
SET	[Date] = @Date,
	HeadingType = @HeadingType,
	[Text] = @Text,
	RAGStatus = @Status,
	EditedOn = GETDATE(),
	EditedBy = SUSER_SNAME()
WHERE [ID] = @CommentID
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteCommentsWithStatus] TO PUBLIC
    AS [dbo];

