CREATE PROCEDURE [dbo].[GetSiteTradingShifts]
(
	@EDISID		INT
)

AS

SET NOCOUNT ON;

SELECT *
FROM SiteTradingShifts
WHERE EDISID = @EDISID
ORDER BY DayOfWeek asc
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteTradingShifts] TO PUBLIC
    AS [dbo];

