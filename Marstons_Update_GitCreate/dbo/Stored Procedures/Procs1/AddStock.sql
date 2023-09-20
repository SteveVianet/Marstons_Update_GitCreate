CREATE PROCEDURE [dbo].[AddStock]
(
	@EDISID 		INTEGER, 
	@Date			DATETIME,
	@ProductID		INTEGER,
	@Quantity		REAL,
	@Hour			INT = 0,
	@BeforeDelivery	BIT = 0
)

AS

SET NOCOUNT ON

SET XACT_ABORT ON


DECLARE @MasterDateID INTEGER

SELECT @MasterDateID = [ID]
FROM dbo.MasterDates
WHERE EDISID = @EDISID
AND [Date] = CAST(@Date AS DATE)

IF @MasterDateID IS NULL 
BEGIN
	INSERT INTO dbo.MasterDates (EDISID, Date)
	VALUES(@EDISID, CAST(@Date AS date))

	SELECT @MasterDateID = SCOPE_IDENTITY()
END

INSERT INTO dbo.Stock
(MasterDateID, ProductID, Quantity, Hour, BeforeDelivery)
VALUES
(@MasterDateID, @ProductID, @Quantity, @Hour, @BeforeDelivery)
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddStock] TO PUBLIC
    AS [dbo];

