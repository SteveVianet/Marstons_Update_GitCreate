CREATE PROCEDURE [dbo].[UpdateProductGroup]
(
	@GroupID INTEGER,
	@Description VARCHAR(50)
)

AS

UPDATE	dbo.ProductGroups
set Description = @Description
Where ID = @GroupID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateProductGroup] TO PUBLIC
    AS [dbo];

