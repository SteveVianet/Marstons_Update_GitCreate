CREATE PROCEDURE [dbo].[GetGlobalProducts]
AS

EXEC [EDISSQL1\SQL1].[Product].dbo.GetProducts


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetGlobalProducts] TO PUBLIC
    AS [dbo];

