CREATE PROCEDURE [dbo].[AddSiteCommentWithStatus]
	@EDISID		 INT,
	@CommentDate DATETIME,
	@Heading	 VARCHAR(1024),
	@CommentType INT,
	@Comment     VARCHAR(1024),
	@Status      VARCHAR(50)
	
AS
BEGIN
	SET NOCOUNT ON;
DECLARE @NewID int = 0
DECLARE @HeadingID int
SELECT @HeadingID = ID FROM SiteCommentHeadingTypes WHERE [Description] LIKE SUBSTRING(@Heading, 1, 8) + '%';
IF @HeadingID IS NULL SET @HeadingID = 21;
EXEC dbo.AddSiteComment @EDISID, @CommentType, @CommentDate, @HeadingID, @Comment, @NewID, NULL, @Status
   
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSiteCommentWithStatus] TO PUBLIC
    AS [dbo];

