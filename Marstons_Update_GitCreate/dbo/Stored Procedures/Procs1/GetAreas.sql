
---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetAreas

AS

SELECT	[ID],
	[Description]
FROM dbo.Areas


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAreas] TO PUBLIC
    AS [dbo];

