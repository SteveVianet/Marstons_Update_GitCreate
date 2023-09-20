
CREATE PROCEDURE GetProductsSold
(
	@EDISID		INT,
	@From		DATETIME,
	@To		DATETIME
)

AS

SELECT ProductID
FROM dbo.Sales
JOIN dbo.MasterDates ON MasterDates.[ID] = Sales.MasterDateID
WHERE MasterDates.EDISID = @EDISID
AND MasterDates.[Date] BETWEEN @From AND @To
GROUP BY Sales.ProductID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetProductsSold] TO PUBLIC
    AS [dbo];

