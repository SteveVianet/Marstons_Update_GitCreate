---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetDeliveries
(
	@EDISID	INTEGER,
	@Date		DATETIME
)

AS

SELECT	Delivery.[ID],
		Delivery.Product AS ProductID, 
		Products.[Description] AS Product,
		Delivery.Quantity,
		Delivery.DeliveryIdent 
FROM dbo.Delivery 
JOIN dbo.MasterDates ON MasterDates.[ID] = Delivery.DeliveryID
JOIN dbo.Products ON Products.[ID] = Delivery.Product
WHERE MasterDates.EDISID = @EDISID
AND MasterDates.[Date] = @Date
ORDER BY Products.[Description]


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDeliveries] TO PUBLIC
    AS [dbo];

