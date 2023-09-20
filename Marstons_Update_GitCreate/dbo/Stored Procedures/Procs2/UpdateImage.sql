---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE UpdateImage
(
	@ImageID	INT,
	@ImageContent	IMAGE
)

AS

UPDATE dbo.Images
SET Content = @ImageContent
WHERE [ID] = @ImageID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateImage] TO PUBLIC
    AS [dbo];

