---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE AddCallSiteStock
(
	@CallID		INT,
	@Product	VARCHAR(50),
	@Size		VARCHAR(50),
        @FullQuantity	INT,
        @EmptyQuantity	INT
)

AS

INSERT INTO CallSiteStocks
(CallID, Product, [Size], FullQuantity, EmptyQuantity)
VALUES
(@CallID, @Product, @Size, @FullQuantity, @EmptyQuantity)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddCallSiteStock] TO PUBLIC
    AS [dbo];

