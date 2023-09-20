---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetStockistCategories

AS

SELECT	[ID],
	[Description]
FROM StockistCategories
ORDER BY [Description]


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetStockistCategories] TO PUBLIC
    AS [dbo];

