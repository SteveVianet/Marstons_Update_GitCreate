---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetImage
(
	@ImageID	INT
)

AS

SELECT Content
FROM dbo.Images
WHERE [ID] = @ImageID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetImage] TO PUBLIC
    AS [dbo];

