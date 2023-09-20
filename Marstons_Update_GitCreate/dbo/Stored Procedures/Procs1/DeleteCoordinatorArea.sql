---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE DeleteCoordinatorArea
(
	@AreaID	INT
)

AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.DeleteCoordinatorArea @AreaID



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteCoordinatorArea] TO PUBLIC
    AS [dbo];

