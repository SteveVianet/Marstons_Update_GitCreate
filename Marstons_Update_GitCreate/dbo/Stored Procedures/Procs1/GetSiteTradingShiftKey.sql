
CREATE PROCEDURE GetSiteTradingShiftKey
(
	@EDISID		INT
)

AS

SET NOCOUNT ON;

SELECT DISTINCT Name, TableColour, TableNumber
FROM SiteTradingShifts
WHERE EDISID = @EDISID
ORDER BY TableNumber


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteTradingShiftKey] TO PUBLIC
    AS [dbo];

