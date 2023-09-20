---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetPropertyTypes

AS

SELECT [ID], [Name]
FROM dbo.Properties


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetPropertyTypes] TO PUBLIC
    AS [dbo];

