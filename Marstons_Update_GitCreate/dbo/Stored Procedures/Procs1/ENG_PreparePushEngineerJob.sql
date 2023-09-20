---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE ENG_PreparePushEngineerJob
(
	@CallReference VARCHAR(20)
)

AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.ENG_PreparePushEngineerJob @CallReference



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ENG_PreparePushEngineerJob] TO PUBLIC
    AS [dbo];

