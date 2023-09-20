CREATE PROCEDURE dbo.GetStock
(
	@EDISID	INTEGER,
	@Date		DATETIME,
	@ProductID	INT = NULL
)

AS

SELECT	Stock.Quantity,
		Stock.Hour,
		Stock.BeforeDelivery,
		Products.[Description] AS Product,
		Products.[ID] AS ProductID
FROM dbo.Stock
JOIN dbo.MasterDates ON MasterDates.[ID] = Stock.MasterDateID
JOIN dbo.Products ON Products.[ID] = Stock.ProductID
WHERE MasterDates.[Date] = @Date
AND MasterDates.EDISID = @EDISID
AND (Stock.ProductID = @ProductID OR @ProductID IS NULL)
ORDER BY MasterDates.[Date]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetStock] TO PUBLIC
    AS [dbo];

