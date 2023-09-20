CREATE PROCEDURE [dbo].[GetDeliveryDatesRange]
(
      @EDISID           INT
)
AS

SELECT MasterDates.EDISID, MAX([Date]) AS MaxDate, MIN([Date]) AS MinDate
FROM MasterDates 
JOIN Delivery
  ON Delivery.DeliveryID = MasterDates.ID
WHERE MasterDates.EDISID = @EDISID
GROUP BY MasterDates.EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDeliveryDatesRange] TO PUBLIC
    AS [dbo];

