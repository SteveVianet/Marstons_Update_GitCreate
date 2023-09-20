CREATE PROCEDURE GetSalesImportErrors

AS

SELECT Message,
	SiteID,
	[Date],
	SaleIdent,
	ProductAlias,
	Quantity,
	SaleTime
FROM dbo.SalesImportErrors
WHERE UPPER(UserName) = UPPER(SYSTEM_USER)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSalesImportErrors] TO PUBLIC
    AS [dbo];

