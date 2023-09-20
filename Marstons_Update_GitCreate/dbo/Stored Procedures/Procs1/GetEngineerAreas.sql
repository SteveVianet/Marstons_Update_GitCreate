---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetEngineerAreas
(
	@EngineerID	INT = NULL
)

AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.GetEngineerAreas @EngineerID



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetEngineerAreas] TO PUBLIC
    AS [dbo];

