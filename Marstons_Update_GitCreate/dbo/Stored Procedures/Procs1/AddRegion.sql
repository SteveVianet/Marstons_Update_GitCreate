---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE AddRegion
(
	@Description	VARCHAR(50),
	@NewID		INT		OUTPUT
)

AS

INSERT INTO dbo.Regions
([Description])
VALUES
(@Description)

SET @NewID = @@IDENTITY


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddRegion] TO PUBLIC
    AS [dbo];

