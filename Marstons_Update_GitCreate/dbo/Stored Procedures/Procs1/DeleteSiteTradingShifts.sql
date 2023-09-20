
CREATE PROCEDURE DeleteSiteTradingShifts
(
	@EDISID			INT
)

AS

SET NOCOUNT ON;

DELETE FROM SiteTradingShifts
WHERE EDISID = @EDISID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteSiteTradingShifts] TO PUBLIC
    AS [dbo];

