---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetActions

AS

SELECT	[ID],
	[Description]
FROM dbo.VRSActions


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetActions] TO PUBLIC
    AS [dbo];

