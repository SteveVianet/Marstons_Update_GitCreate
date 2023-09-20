---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetCallSiteStocks
(
	@CallID	INT
)

AS

SELECT	Product,
	[Size],
	FullQuantity, 
	EmptyQuantity
FROM CallSiteStocks
WHERE CallID = @CallID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallSiteStocks] TO PUBLIC
    AS [dbo];

