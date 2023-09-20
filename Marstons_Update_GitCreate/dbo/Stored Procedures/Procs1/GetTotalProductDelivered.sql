---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetTotalProductDelivered
(
	@EDISID		INT,
	@ProductID	INT,
	@From		DATETIME,
	@To		DATETIME
)

AS

SELECT SUM(Quantity) AS TotalDelivered
FROM dbo.Delivery
JOIN dbo.MasterDates ON MasterDates.[ID] = Delivery.DeliveryID
JOIN dbo.Sites ON MasterDates.EDISID = Sites.EDISID
WHERE Sites.EDISID = @EDISID
AND Delivery.Product = @ProductID
AND MasterDates.[Date] BETWEEN @From AND @To
AND MasterDates.[Date] >= Sites.SiteOnline


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTotalProductDelivered] TO PUBLIC
    AS [dbo];

