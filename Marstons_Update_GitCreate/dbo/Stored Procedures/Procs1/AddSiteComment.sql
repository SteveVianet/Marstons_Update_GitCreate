CREATE PROCEDURE [dbo].[AddSiteComment]
(
	@EDISID		INT,
	@Type		INT,
	@Date		DATETIME,
	@HeadingType	INT,
	@Text		VARCHAR(1024),
	@NewID		INT OUTPUT,
	@User		VARCHAR(255) = NULL,
    @Status		VARCHAR(50) = NULL
	
)

AS

DECLARE @GlobalEDISID	INTEGER
DECLARE @CallID INTEGER

SET NOCOUNT ON

IF @Status IS NULL AND @HeadingType = 3004 SET @Status = 'Green';

INSERT INTO dbo.SiteComments
(EDISID, [Type], [Date], HeadingType, [Text], Deleted, AddedBy, EditedBy, RAGStatus)
VALUES
(@EDISID, @Type, @Date, @HeadingType, @Text, 0, ISNULL(@User, SUSER_SNAME()), ISNULL(@User, SUSER_SNAME()), @Status)

SET @NewID = @@IDENTITY

IF @Type = 5
BEGIN
	SELECT @CallID = MAX(ID) FROM Calls WHERE EDISID = @EDISID
	EXEC dbo.RefreshHandheldCall @CallID, 0, 0, 1
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSiteComment] TO PUBLIC
    AS [dbo];

