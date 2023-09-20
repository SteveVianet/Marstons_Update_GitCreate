---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetContractorEngineers
(
	@ContractorID	INT
)

AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.GetContractorEngineers @ContractorID



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetContractorEngineers] TO PUBLIC
    AS [dbo];

