CREATE PROCEDURE GetEngineerFlowmetersUsed
(
	@CallReference		VARCHAR(50)
)
AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.WD_GetEngineerFlowmetersUsed @CallReference

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetEngineerFlowmetersUsed] TO PUBLIC
    AS [dbo];

