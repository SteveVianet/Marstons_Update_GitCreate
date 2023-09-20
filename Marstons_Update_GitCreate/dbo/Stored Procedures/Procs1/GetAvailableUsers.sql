---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetAvailableUsers

AS


SELECT [name] AS UserName
FROM master.dbo.syslogins AS syslogins
WHERE isntname = 1
AND isntgroup = 0
AND NOT EXISTS (SELECT [name]
		FROM [sysusers]
		WHERE isntuser = 1
		AND issqluser = 0
		AND uid <> 1
		AND [name] = syslogins.[name])
ORDER BY UPPER([name])


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAvailableUsers] TO PUBLIC
    AS [dbo];

