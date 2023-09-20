---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE DeleteContractor
(
	@ContractorID	INT
)

AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.DeleteContractor @ContractorID



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteContractor] TO PUBLIC
    AS [dbo];

