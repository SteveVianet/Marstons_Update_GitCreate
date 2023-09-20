
---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE AddArea
(
	@Description	VARCHAR(50),
	@NewID		INT		OUTPUT
)

AS

INSERT INTO dbo.Areas
([Description])
VALUES
(@Description)

SET @NewID = @@IDENTITY


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddArea] TO PUBLIC
    AS [dbo];

