---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetModemTypes

AS

SELECT	[ID],
	[Description]
FROM dbo.ModemTypes


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetModemTypes] TO PUBLIC
    AS [dbo];

