CREATE PROCEDURE [neo].[UpdateSiteComment2]
(
	@CommentID	INT,
	@Date		DATETIME,
	@HeadingType	INT,
	@Text		VARCHAR(1024),
	@Status VARCHAR(30)
)

AS

UPDATE SiteComments
SET	[Date] = @Date,
	HeadingType = @HeadingType,
	[Text] = @Text,
	EditedOn = GETDATE(),
	EditedBy = SUSER_SNAME(),
	RAGStatus = @Status
WHERE [ID] = @CommentID
GO
GRANT EXECUTE
    ON OBJECT::[neo].[UpdateSiteComment2] TO PUBLIC
    AS [dbo];

