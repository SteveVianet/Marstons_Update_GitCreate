
CREATE PROCEDURE dbo.DeleteProductGroup
(
	@ID		INT
)

AS

--Delete members
DELETE FROM dbo.ProductGroupProducts
WHERE ProductGroupID = @ID

--Delete group
DELETE FROM dbo.ProductGroups
WHERE [ID] = @ID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteProductGroup] TO PUBLIC
    AS [dbo];

