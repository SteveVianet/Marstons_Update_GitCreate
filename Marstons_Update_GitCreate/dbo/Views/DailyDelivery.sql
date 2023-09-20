---------------------------------------------------------------------------
--
--  DailyDelivery view
--
---------------------------------------------------------------------------
CREATE VIEW dbo.DailyDelivery
AS
SELECT		DeliveryID AS DailyID, 
		Product, 
		SUM(Quantity) AS Quantity
FROM		dbo.Delivery
GROUP BY	DeliveryID,
		Product

