CREATE PROCEDURE [dbo].[AddWebSiteStock]
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

DECLARE @MasterDateID		INTEGER
DECLARE @GlobalEDISID		INTEGER

DECLARE @ExistingProductID	INTEGER

SET XACT_ABORT ON

BEGIN TRAN

SELECT @MasterDateID = [ID]
FROM dbo.MasterDates
WHERE EDISID = @EDISID
AND [Date] = @Date

IF @MasterDateID IS NULL
BEGIN
	INSERT INTO dbo.MasterDates
	(EDISID, [Date])
	VALUES
	(@EDISID, @Date)

	SET @MasterDateID = @@IDENTITY
END

SELECT @ExistingProductID = ProductID
FROM dbo.Stock
WHERE MasterDateID = @MasterDateID
AND ProductID = @ProductID

IF @ExistingProductID IS NULL
BEGIN
	INSERT INTO dbo.Stock
	(MasterDateID, ProductID, Quantity, Hour, BeforeDelivery)
	VALUES
	(@MasterDateID, @ProductID, @Quantity, @Hour, @BeforeDelivery)

END
ELSE
BEGIN
	UPDATE dbo.Stock
	SET Quantity = @Quantity, Hour = @Hour, BeforeDelivery = @BeforeDelivery
	WHERE MasterDateID = @MasterDateID
	AND ProductID = @ExistingProductID
	
END

COMMIT

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddWebSiteStock] TO PUBLIC
    AS [dbo];

