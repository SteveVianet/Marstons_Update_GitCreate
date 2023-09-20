---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE DeleteCallFault
(
	@ID	INT
)

AS

DELETE FROM CallFaults
WHERE [ID] = @ID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteCallFault] TO PUBLIC
    AS [dbo];

