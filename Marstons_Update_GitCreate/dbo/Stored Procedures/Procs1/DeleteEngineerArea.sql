---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE DeleteEngineerArea
(
	@AreaID	INT
)

AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.DeleteEngineerArea @AreaID



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteEngineerArea] TO PUBLIC
    AS [dbo];

