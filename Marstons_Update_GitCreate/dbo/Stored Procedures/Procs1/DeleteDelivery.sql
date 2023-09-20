CREATE PROCEDURE DeleteDelivery
(
	@ID	INT
)

AS

SET NOCOUNT ON

DECLARE @EDISID		INTEGER
DECLARE @Date		DATETIME
DECLARE @Product		INTEGER
DECLARE @Quantity		FLOAT
DECLARE @DeliveryIdent	VARCHAR(50)
DECLARE @GlobalEDISID	INTEGER
DECLARE @GlobalProductID	INTEGER

SELECT @EDISID = @EDISID,
	 @Date = MasterDates.[Date],
	 @Product = Product,
	 @Quantity = Quantity,
	 @DeliveryIdent = DeliveryIdent 
FROM Delivery
JOIN MasterDates ON MasterDates.[ID] = Delivery.DeliveryID
WHERE Delivery.[ID] = @ID

/*
SELECT @GlobalEDISID = Sites.GlobalEDISID
FROM Sites
WHERE EDISID = @EDISID

IF @GlobalEDISID IS NOT NULL
BEGIN
	SELECT @GlobalProductID = GlobalID
	FROM Products
	WHERE [ID] = @Product

	EXEC [SQL2\SQL2].[Global].dbo.DeleteGlobalDelivery @GlobalEDISID, @Date, @GlobalProductID, @Quantity, @DeliveryIdent
END
*/

DELETE FROM dbo.Delivery
WHERE [ID] = @ID



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteDelivery] TO PUBLIC
    AS [dbo];

