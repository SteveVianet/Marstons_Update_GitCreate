---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[DeleteSiteDelivery]
(
	@EDISID	INT,
	@From	DATETIME,
	@To		DATETIME
)

AS

DELETE Delivery FROM Delivery
JOIN MasterDates ON MasterDates.ID = Delivery.DeliveryID
WHERE MasterDates.[Date] BETWEEN @From AND @To
AND EDISID = @EDISID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteSiteDelivery] TO PUBLIC
    AS [dbo];

