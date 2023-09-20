CREATE PROCEDURE [dbo].[GetSales]
(
	@EDISID		INTEGER,
	@Date		DATETIME = NULL,
	@MinDate	DATETIME = NULL
)

AS

SELECT	Sales.[ID],
		Sales.ProductID AS ProductID, 
		Products.[Description] AS Product,
		Sales.Quantity,
		Sales.SaleIdent,
		Sales.SaleTime,
		Sales.SaleDate,
		[External],
		Sales.ProductAlias,
		MasterDates.EDISID
FROM dbo.Sales
JOIN dbo.MasterDates ON MasterDates.[ID] = Sales.MasterDateID
JOIN dbo.Products ON Products.[ID] = Sales.ProductID
WHERE MasterDates.EDISID = @EDISID
AND ( (MasterDates.[Date] = @Date) OR (@Date IS NULL) )
AND (MasterDates.[Date] >= @MinDate OR @MinDate IS NULL)
ORDER BY Products.[Description]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSales] TO PUBLIC
    AS [dbo];

