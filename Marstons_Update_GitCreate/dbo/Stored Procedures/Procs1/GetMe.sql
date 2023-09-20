---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetMe

AS

SELECT SUSER_SNAME() AS Me


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetMe] TO PUBLIC
    AS [dbo];

