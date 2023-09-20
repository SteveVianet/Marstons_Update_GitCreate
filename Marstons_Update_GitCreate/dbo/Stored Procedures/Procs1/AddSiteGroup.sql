---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE AddSiteGroup
(
	@Description	VARCHAR(255),
	@TypeID		INT,
	@NewID		INT OUTPUT
)

AS

INSERT INTO dbo.SiteGroups
([Description], TypeID)
VALUES
(@Description, @TypeID)

SET @NewID = @@IDENTITY

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSiteGroup] TO PUBLIC
    AS [dbo];

