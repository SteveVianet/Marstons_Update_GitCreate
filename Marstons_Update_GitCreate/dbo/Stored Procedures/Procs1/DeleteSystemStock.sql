CREATE PROCEDURE [dbo].[DeleteSystemStock]
(
	@ID		INT
)

AS

SET NOCOUNT ON

DELETE
FROM dbo.SystemStock
WHERE ID = @ID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteSystemStock] TO PUBLIC
    AS [dbo];

