---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE DeleteCallSiteStock
(
	@CallID		INT,
	@Product	VARCHAR(50),
	@Size		VARCHAR(50)
)

AS

DELETE FROM CallSiteStocks
WHERE	CallID = @CallID
AND Product = @Product
AND [Size]= @Size


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteCallSiteStock] TO PUBLIC
    AS [dbo];

