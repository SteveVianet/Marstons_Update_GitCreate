---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetPermittedUsers

AS

SELECT [name] AS UserName
FROM [sysusers]
WHERE isntuser = 1
AND issqluser = 0
AND uid <> 1
ORDER BY UPPER([name])
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetPermittedUsers] TO PUBLIC
    AS [dbo];

