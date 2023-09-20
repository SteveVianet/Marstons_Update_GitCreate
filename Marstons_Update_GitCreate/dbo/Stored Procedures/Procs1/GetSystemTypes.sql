---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetSystemTypes

AS

SELECT	[ID],
	[Description],
	DispenseByMinute
FROM SystemTypes


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSystemTypes] TO PUBLIC
    AS [dbo];

