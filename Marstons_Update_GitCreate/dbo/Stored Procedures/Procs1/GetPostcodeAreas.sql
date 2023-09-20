---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetPostcodeAreas

AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.GetPostcodeAreas



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetPostcodeAreas] TO PUBLIC
    AS [dbo];

