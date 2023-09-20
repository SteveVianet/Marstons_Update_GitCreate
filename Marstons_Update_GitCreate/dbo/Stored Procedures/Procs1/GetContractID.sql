---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetContractID
(
	@EDISID INT
)

AS

DECLARE @ContractID	INT

SELECT @ContractID = ContractID
FROM SiteContracts
WHERE EDISID = @EDISID

IF @ContractID IS NULL
	RETURN 0
ELSE
	RETURN @ContractID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetContractID] TO PUBLIC
    AS [dbo];

