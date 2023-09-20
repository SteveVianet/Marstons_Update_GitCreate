---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetDefaultItemPrices

AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.GetDefaultItemPrices



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDefaultItemPrices] TO PUBLIC
    AS [dbo];

