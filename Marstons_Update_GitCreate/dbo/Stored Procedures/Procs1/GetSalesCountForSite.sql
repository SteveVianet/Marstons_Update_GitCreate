CREATE PROCEDURE [dbo].[GetSalesCountForSite]
(
	@EDISID	INTEGER
)

AS

SELECT	Count(Sales.ID) as SalesCount

FROM dbo.Sales
WHERE 
Sales.EDISID = @EDISID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSalesCountForSite] TO PUBLIC
    AS [dbo];

