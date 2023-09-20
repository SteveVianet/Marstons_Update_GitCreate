
CREATE PROCEDURE dbo.AddProductGroup
(
	@Description	VARCHAR(255),
	@TypeID		INT,
	@NewID		INT OUTPUT
)

AS

INSERT INTO dbo.ProductGroups
([Description], TypeID)
VALUES
(@Description, @TypeID)

SET @NewID = @@IDENTITY

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddProductGroup] TO PUBLIC
    AS [dbo];

