CREATE PROCEDURE [dbo].[UpdateStock]
(
	@EDISID 		INTEGER, 
	@Date			DATETIME,
	@ProductID		INTEGER,
	@Quantity		REAL,
	@Hour			INT = 0,
	@BeforeDelivery	BIT = 0,
	@MasterDateID INT = NULL
)

AS

DECLARE @GlobalEDISID	INTEGER
DECLARE @GlobalProductID	INTEGER

IF @MasterDateID IS NULL 
BEGIN
SELECT @MasterDateID = [ID]
FROM dbo.MasterDates
WHERE EDISID = @EDISID
AND [Date] = @Date
END

UPDATE dbo.Stock
SET Quantity = @Quantity, Hour = @Hour, BeforeDelivery = @BeforeDelivery
WHERE MasterDateID = @MasterDateID
AND ProductID = @ProductID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateStock] TO PUBLIC
    AS [dbo];

