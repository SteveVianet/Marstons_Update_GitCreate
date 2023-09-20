---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE AddImage
(
	@ImageContent	IMAGE,
	@ImageID	INT	OUTPUT
)

AS

INSERT INTO dbo.Images
(Content)
VALUES
(@ImageContent)

SET @ImageID = @@IDENTITY


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddImage] TO PUBLIC
    AS [dbo];

