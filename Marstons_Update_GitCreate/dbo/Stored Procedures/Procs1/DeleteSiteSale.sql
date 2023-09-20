CREATE PROCEDURE [dbo].[DeleteSiteSale]
(
	@EDISID	INT,
	@From	DATETIME,
	@To		DATETIME
)

AS

DELETE Sales
FROM Sales
JOIN MasterDates ON MasterDates.ID = Sales.MasterDateID
WHERE MasterDates.[Date] BETWEEN @From AND @To
AND MasterDates.EDISID = @EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteSiteSale] TO PUBLIC
    AS [dbo];

