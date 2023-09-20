CREATE PROCEDURE [dbo].[InsertSiteComment]
(
	@EDISID		INT,
	@Type		INT,
	@Date		DATETIME,
	@HeadingType	INT,
	@Text		VARCHAR(1024),
	@NewID		INT OUTPUT,
	@AddedOn	DATETIME,
	@AddedBy	VARCHAR(255),
	@EditedOn	DATETIME,
	@EditedBy	VARCHAR(255),
	@Deleted	BIT
)

AS


INSERT INTO dbo.SiteComments
(EDISID, Type, [Date], HeadingType, [Text], Deleted, 
 AddedBy, EditedBy, AddedOn, EditedOn)
VALUES
(@EDISID, @Type, @Date, @HeadingType, @Text, @Deleted, 
 @AddedBy, @EditedBy, @AddedOn, @EditedOn)

SET @NewID = @@IDENTITY

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[InsertSiteComment] TO PUBLIC
    AS [dbo];

