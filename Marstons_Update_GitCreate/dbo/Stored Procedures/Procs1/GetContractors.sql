CREATE PROCEDURE [dbo].[GetContractors]
(
	@IncInactive	BIT = 0
)
AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.GetContractors @IncInactive



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetContractors] TO PUBLIC
    AS [dbo];

