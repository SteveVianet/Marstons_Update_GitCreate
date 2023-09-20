CREATE PROCEDURE DeleteGlobalSite
(
	@EDISID		INTEGER
)

AS

--EXEC [SQL2\SQL2].[Global].dbo.DeleteSite @EDISID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteGlobalSite] TO PUBLIC
    AS [dbo];

