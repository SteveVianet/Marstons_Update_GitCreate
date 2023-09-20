CREATE PROCEDURE [dbo].[GetSalesCountForProduct]
(
	@ProductID	INTEGER
)

AS

SELECT	Count(Sales.ID) as SalesCount

FROM dbo.Sales
WHERE 
Sales.ProductID = @ProductID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSalesCountForProduct] TO PUBLIC
    AS [dbo];

