CREATE PROCEDURE DeleteSale
(
	@ID	INT
)

AS

SET NOCOUNT ON

DECLARE @GlobalEDISID	INTEGER
DECLARE @GlobalProductID	INTEGER
DECLARE @EDISID		INTEGER
DECLARE @Date		DATETIME
DECLARE @ProductID		INTEGER
DECLARE @Quantity		FLOAT
DECLARE @SaleIdent		VARCHAR(255)
DECLARE @SaleTime		DATETIME

SELECT @EDISID = MasterDates.EDISID,
	 @Date = MasterDates.[Date],
	 @ProductID = ProductID,
	 @Quantity = Quantity,
	 @SaleIdent = SaleIdent,
	 @SaleTime = SaleTime
FROM Sales
JOIN MasterDates ON MasterDates.[ID] = Sales.MasterDateID
WHERE Sales.[ID] = @ID

/*
SELECT @GlobalEDISID = Sites.GlobalEDISID
FROM Sites
WHERE EDISID = @EDISID

IF @GlobalEDISID IS NOT NULL
BEGIN
	SELECT @GlobalProductID = GlobalID
	FROM Products
	WHERE [ID] = @ProductID

	EXEC [SQL2\SQL2].[Global].dbo.DeleteGlobalSale @GlobalEDISID, @Date, @GlobalProductID, @Quantity, @SaleIdent, @SaleTime

END
*/

DELETE FROM dbo.Sales
WHERE [ID] = @ID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteSale] TO PUBLIC
    AS [dbo];

