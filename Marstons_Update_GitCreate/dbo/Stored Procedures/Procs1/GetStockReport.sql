CREATE PROCEDURE dbo.GetStockReport
(
	@EDISID	INTEGER,
	@From		DATETIME,
	@To		DATETIME,
	@ProductID	INT = NULL
)

AS

SELECT	MasterDates.[Date],
		Products.[Description] AS Product,
		Products.[ID] AS ProductID,
		Stock.Quantity,
		Stock.Hour,
		Stock.BeforeDelivery
FROM dbo.Stock
JOIN dbo.MasterDates ON MasterDates.[ID] = Stock.MasterDateID
JOIN dbo.Products ON Products.[ID] = Stock.ProductID
WHERE MasterDates.[Date] BETWEEN @From AND @To
AND MasterDates.EDISID = @EDISID
AND (Stock.ProductID = @ProductID OR @ProductID IS NULL)
ORDER BY MasterDates.[Date]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetStockReport] TO PUBLIC
    AS [dbo];

