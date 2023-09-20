---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetOutcomes

AS

SELECT	[ID],
	[Description]
FROM dbo.VRSOutcomes


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetOutcomes] TO PUBLIC
    AS [dbo];

