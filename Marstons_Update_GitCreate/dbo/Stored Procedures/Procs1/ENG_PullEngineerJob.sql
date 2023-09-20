---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE ENG_PullEngineerJob
(
	@CallReference VARCHAR(20),
	@Force BIT
)

AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.ENG_PullEngineerJob	@CallReference,
								@Force



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ENG_PullEngineerJob] TO PUBLIC
    AS [dbo];

