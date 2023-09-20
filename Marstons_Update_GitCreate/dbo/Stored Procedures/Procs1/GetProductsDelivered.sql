---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetProductsDelivered
(
	@EDISID		INT,
	@From		DATETIME,
	@To		DATETIME
)

AS

SELECT Product AS ProductID
FROM dbo.Delivery
JOIN dbo.MasterDates ON MasterDates.[ID] = Delivery.DeliveryID
WHERE MasterDates.EDISID = @EDISID
AND MasterDates.[Date] BETWEEN @From AND @To
GROUP BY Delivery.Product


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetProductsDelivered] TO PUBLIC
    AS [dbo];

