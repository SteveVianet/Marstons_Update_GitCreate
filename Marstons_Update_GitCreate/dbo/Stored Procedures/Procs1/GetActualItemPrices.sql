CREATE PROCEDURE GetActualItemPrices

AS

SELECT	ItemID,
	Price
FROM ItemPrices
GO
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetActualItemPrices] TO PUBLIC
    AS [dbo];

