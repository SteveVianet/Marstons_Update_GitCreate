CREATE PROCEDURE UpdateSale
(
	@ID 		INTEGER, 
	@Quantity	REAL
)

AS

SET NOCOUNT ON

DECLARE @GlobalEDISID	INTEGER
DECLARE @GlobalProductID	INTEGER
DECLARE @EDISID		INTEGER
DECLARE @Date		DATETIME
DECLARE @ProductID		INTEGER
DECLARE @SaleIdent		VARCHAR(255)
DECLARE @SaleTime		DATETIME

SELECT @EDISID = MasterDates.EDISID,
	 @Date = MasterDates.[Date],
	 @ProductID = ProductID,
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

	EXEC [SQL2\SQL2].[Global].dbo.UpdateGlobalSale @GlobalEDISID, @Date, @GlobalProductID, @Quantity, @SaleIdent, @SaleTime

END
*/

UPDATE Sales 
SET Quantity = @Quantity
WHERE [ID] = @ID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSale] TO PUBLIC
    AS [dbo];

