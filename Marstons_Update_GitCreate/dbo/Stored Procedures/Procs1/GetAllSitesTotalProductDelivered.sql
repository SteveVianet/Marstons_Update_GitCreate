---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetAllSitesTotalProductDelivered
(
	@ProductID	INT,
	@From		DATETIME,
	@To		DATETIME
)

AS

SELECT SUM(Quantity) AS TotalDelivered
FROM dbo.Delivery
JOIN dbo.MasterDates ON MasterDates.[ID] = Delivery.DeliveryID
WHERE Delivery.Product = @ProductID
AND MasterDates.[Date] BETWEEN @From AND @To


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAllSitesTotalProductDelivered] TO PUBLIC
    AS [dbo];

