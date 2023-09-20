
CREATE PROCEDURE GetOwnerTradingShifts
(
	@OwnerID		INT
)

AS

SET NOCOUNT ON;

SELECT *
FROM OwnerTradingShifts
WHERE OwnerID = @OwnerID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetOwnerTradingShifts] TO PUBLIC
    AS [dbo];

