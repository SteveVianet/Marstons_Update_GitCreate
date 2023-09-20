---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetProductPrices
(
	@EDISID	INTEGER
)

AS

SELECT	Products.[Description] AS Product,
		Products.[ID] AS ProductID,
		ProductPrices.Price
FROM dbo.ProductPrices
JOIN dbo.Products
ON Products.[ID] = ProductPrices.ProductID
WHERE EDISID = @EDISID
AND ValidTo IS NULL


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetProductPrices] TO PUBLIC
    AS [dbo];

