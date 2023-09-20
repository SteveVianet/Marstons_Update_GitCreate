-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[AddWebSiteComment] 
	
	
	-- Add the parameters for the stored procedure here
	@EDISID			INT,
	@CommentType	INT,
	@HeadingType	INT, 
	@Text			VARCHAR(1024),
	@Date			DATETIME,
	@AddedOn		DATETIME,
	@AddedBy		VARCHAR(255)

	
AS
BEGIN

	SET NOCOUNT ON;

	INSERT INTO dbo.SiteComments (EDISID, [Type], HeadingType, [Text], [Date], AddedOn, AddedBy)
	
	VALUES (@EDISID, @CommentType, @HeadingType, @Text, @Date, @AddedOn, @AddedBy)
	
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddWebSiteComment] TO PUBLIC
    AS [dbo];

