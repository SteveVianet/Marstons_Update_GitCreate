---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetRegions

AS

SELECT 	[ID],
	[Description]
FROM dbo.Regions


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetRegions] TO PUBLIC
    AS [dbo];

