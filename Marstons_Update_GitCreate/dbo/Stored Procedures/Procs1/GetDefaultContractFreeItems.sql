---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetDefaultContractFreeItems

AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.GetDefaultContractFreeItems



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDefaultContractFreeItems] TO PUBLIC
    AS [dbo];

