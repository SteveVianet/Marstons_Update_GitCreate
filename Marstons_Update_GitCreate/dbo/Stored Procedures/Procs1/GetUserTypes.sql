---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetUserTypes

AS

SELECT [ID], [Description], AllSitesVisible
FROM dbo.UserTypes
ORDER BY [ID]


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetUserTypes] TO PUBLIC
    AS [dbo];

