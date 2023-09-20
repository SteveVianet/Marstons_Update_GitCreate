CREATE PROCEDURE dbo.GetReportPackStockReport
(
	@EDISID	INTEGER,
	@From		DATETIME,
	@To		DATETIME,
	@ProductID	INT = NULL
)

AS
BEGIN
SELECT	MasterDates.[Date],
		Products.[Description] AS Product,
		Products.[ID] AS ProductID,
		Products.IsCask,
		Products.IsMetric,
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

END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetReportPackStockReport] TO PUBLIC
    AS [dbo];

