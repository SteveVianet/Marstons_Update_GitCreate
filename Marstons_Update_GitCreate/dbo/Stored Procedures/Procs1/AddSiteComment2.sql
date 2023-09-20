CREATE PROCEDURE [dbo].[AddSiteComment2]
(
	@SiteID		VARCHAR(50),
	@Type		INT,
	@Date		DATETIME,
	@HeadingType	INT,
	@Text		VARCHAR(1024)
)

AS

DECLARE @EDISID 		INTEGER
DECLARE @GlobalEDISID	INTEGER
DECLARE @NewID		INTEGER

SET NOCOUNT ON

SET @EDISID = 0

SELECT @EDISID = EDISID
FROM Sites
WHERE SiteID = @SiteID

IF @EDISID > 0
BEGIN
	INSERT INTO dbo.SiteComments
	(EDISID, Type, [Date], HeadingType, [Text], Deleted)
	VALUES
	(@EDISID, @Type, @Date, @HeadingType, @Text, 0)
	
	SET @NewID = @@IDENTITY
	
	SELECT @GlobalEDISID = GlobalEDISID
	FROM Sites
	WHERE EDISID = @EDISID
	
	IF @GlobalEDISID IS NOT NULL
	BEGIN
		EXEC [SQL2\SQL2].[Global].dbo.AddSiteComment @GlobalEDISID, @Type, @Date, @HeadingType, @Text, @NewID
	END
END