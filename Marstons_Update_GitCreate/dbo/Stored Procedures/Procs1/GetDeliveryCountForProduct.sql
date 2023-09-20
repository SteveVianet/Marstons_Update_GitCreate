CREATE PROCEDURE [dbo].[GetDeliveryCountForProduct]
(
	@ProductID	INTEGER
)

AS

SELECT	Count(Delivery.[ID]) as DeliveryCount

FROM dbo.Delivery 
WHERE 
Delivery.Product = @ProductID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDeliveryCountForProduct] TO PUBLIC
    AS [dbo];

