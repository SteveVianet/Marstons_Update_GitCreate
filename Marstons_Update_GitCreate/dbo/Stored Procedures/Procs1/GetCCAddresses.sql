---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetCCAddresses

AS

SELECT	[Name],
	[Address]
FROM dbo.CCAddresses


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCCAddresses] TO PUBLIC
    AS [dbo];

