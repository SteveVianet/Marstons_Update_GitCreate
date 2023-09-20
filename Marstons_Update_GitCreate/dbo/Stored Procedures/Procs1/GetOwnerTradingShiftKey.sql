
CREATE PROCEDURE GetOwnerTradingShiftKey
(
	@OwnerID		INT
)

AS

SET NOCOUNT ON;

SELECT DISTINCT Name, TableColour, TableNumber
FROM OwnerTradingShifts
WHERE OwnerID = @OwnerID
ORDER BY TableNumber


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetOwnerTradingShiftKey] TO PUBLIC
    AS [dbo];

