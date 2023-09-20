CREATE PROCEDURE [dbo].[AddDelivery]
(
	@EDISID 	INTEGER, 
	@Date		DATETIME,
	@ProductID	INTEGER,
	@Quantity	REAL,
	@DeliveryIdent	VARCHAR(50),
	@ID		INT OUTPUT
)

AS

DECLARE @DeliveryID		INTEGER
DECLARE @GlobalEDISID	INTEGER
DECLARE @GlobalProductID	INTEGER

SET NOCOUNT ON

--Check delivery date does not already exist
SELECT @DeliveryID = [ID]
FROM dbo.MasterDates
WHERE EDISID = @EDISID
AND [Date] = @Date

IF @DeliveryID IS NULL
BEGIN
	INSERT INTO dbo.MasterDates
	(EDISID, [Date])
	VALUES
	(@EDISID, @Date)

	SET @DeliveryID = @@IDENTITY
END

/*
SELECT @GlobalEDISID = GlobalEDISID
FROM Sites
WHERE EDISID = @EDISID

IF @GlobalEDISID IS NOT NULL
BEGIN
	SELECT @GlobalProductID = GlobalID
	FROM Products
	WHERE [ID] = @ProductID

	EXEC [SQL2\SQL2].[Global].dbo.AddDelivery @GlobalEDISID, @Date, @GlobalProductID, @Quantity, @DeliveryIdent, @ID OUTPUT
END
*/

INSERT INTO dbo.Delivery
(DeliveryID, Product, Quantity, DeliveryIdent)
VALUES
(@DeliveryID, @ProductID, @Quantity, @DeliveryIdent)

SET @ID = @@IDENTITY



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddDelivery] TO PUBLIC
    AS [dbo];

