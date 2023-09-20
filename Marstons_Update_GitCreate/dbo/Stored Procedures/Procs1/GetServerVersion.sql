---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetServerVersion

AS

SELECT	SERVERPROPERTY('ProductVersion') AS ProductVersion,
	SERVERPROPERTY('ProductLevel') AS ProductLevel,
	SERVERPROPERTY('Edition') AS ProductEdition


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetServerVersion] TO PUBLIC
    AS [dbo];

