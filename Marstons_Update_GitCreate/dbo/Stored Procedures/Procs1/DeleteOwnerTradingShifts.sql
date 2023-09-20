
CREATE PROCEDURE DeleteOwnerTradingShifts
(
	@OwnerID			INT
)

AS

SET NOCOUNT ON;

DELETE FROM OwnerTradingShifts
WHERE OwnerID = @OwnerID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteOwnerTradingShifts] TO PUBLIC
    AS [dbo];

