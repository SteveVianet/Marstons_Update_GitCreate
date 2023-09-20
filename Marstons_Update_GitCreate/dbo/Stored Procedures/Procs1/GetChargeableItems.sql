---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetChargeableItems

AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.GetChargeableItems



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetChargeableItems] TO PUBLIC
    AS [dbo];

