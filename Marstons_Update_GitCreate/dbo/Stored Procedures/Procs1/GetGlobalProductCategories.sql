CREATE PROCEDURE dbo.GetGlobalProductCategories
AS

EXEC [EDISSQL1\SQL1].[Product].dbo.GetCategories


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetGlobalProductCategories] TO PUBLIC
    AS [dbo];

